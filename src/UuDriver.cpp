/*=============================================================================
	UuDriver.cpp: Advanced Demo Driver

	Revision history:
		* Created by UsAaR33		
		* Anth: Cleaned up, made some cross-platform modifications
		* Anth: Added Level.TimeSecond syncing (gets screwed when demo pauses)
		* Anth: Added illegal actor cleanup (fixes UTDC crash)

	TODO:
		* Anth: Add Pure Hidden flag fix here.
=============================================================================*/

/*-----------------------------------------------------------------------------
	Includes/Definitions
-----------------------------------------------------------------------------*/
#include "udemoprivate.h"

/*-----------------------------------------------------------------------------
	Globals
-----------------------------------------------------------------------------*/
ULinkerLoad* Linker = NULL;

/*-----------------------------------------------------------------------------
	Constructor
-----------------------------------------------------------------------------*/
UuDemoDriver::UuDemoDriver()
{	
	/*UuDemoPackageMap* DemoPackageMap = new UuDemoPackageMap;
	delete MasterMap;
	MasterMap = DemoPackageMap;*/
}

/*-----------------------------------------------------------------------------
	StaticConstructor
-----------------------------------------------------------------------------*/
void UuDemoDriver::StaticConstructor()
{	
	guard(UuDemoDriver::StaticConstructor);
	new(GetClass(),TEXT("DemoSpectatorClass"), RF_Public)UStrProperty(CPP_PROPERTY(DemoSpectatorClass), TEXT("Client"), CPF_Config);
	unguard;
}

/*-----------------------------------------------------------------------------
	TimeSync - (Anth) Synchronizes time between demo and game after every packet
	read from the demo! Also works while seeking/slomo and when the game is paused
-----------------------------------------------------------------------------*/
void UuDemoDriver::TimeSync(FTime NewTime, FTime OldTime)
{
	guard(UuDemoDriver::TimeSync);

	if (ServerConnection && 
		Notify && 
		GetLevel() && 
		GetLevel()->GetLevelInfo() && 
		Interface && 
		Interface->DemoSpec && 
		Interface->DemoSpec->GameReplicationInfo)
	{
		if (GetLevel()->GetLevelInfo()->Pauser == TEXT("") && 
			GetLevel()->GetLevelInfo()->TimeSeconds + Interface->ltsoffset - Interface->DemoSpec->GameReplicationInfo->SecondCount > RealDilation)
		{
			Interface->DemoSpec->GameReplicationInfo->ElapsedTime++;
			if (Interface->DemoSpec->GameReplicationInfo->RemainingMinute != 0)
			{
				Interface->DemoSpec->GameReplicationInfo->RemainingTime = Interface->DemoSpec->GameReplicationInfo->RemainingMinute;
				Interface->DemoSpec->GameReplicationInfo->RemainingMinute = 0;
			}
			if (Interface->DemoSpec->GameReplicationInfo->RemainingTime > 0 && !Interface->DemoSpec->GameReplicationInfo->bStopCountDown)
				Interface->DemoSpec->GameReplicationInfo->RemainingTime--;
			Interface->DemoSpec->GameReplicationInfo->SecondCount += RealDilation;

		}
	}

	unguard;
}
/*-----------------------------------------------------------------------------
	TickDispatch - Tick the netdriver and the demospec etc! Read packets from
	the ServerConnection and process them
-----------------------------------------------------------------------------*/
void UuDemoDriver::TickDispatch( FLOAT Delta )
{
	guard(UuDemoDriver:TickDispatch);	
	
	// rollback seconds spent to seeking demo
	if (Interface && Interface->bFixLevelTime)
	{
		Interface->bFixLevelTime = FALSE;
		if (Interface->DemoSpec)
			Interface->DemoSpec->XLevel->TimeSeconds += -Delta*Interface->DemoSpec->Level->TimeDilation;
		Delta = 0;
	}

	// Calc deltatime
	FLOAT DeltaTime = Delta;
	if(ServerConnection)
	{
		if (!NoFrameCap)
			DeltaTime*=Speed; //alter speed! 
		if (Paused)
		{
			if (Interface)
			{
				FLOAT DeltaSeconds = Delta*Interface->DemoSpec->Level->TimeDilation;
				Interface->DemoSpec->Tick(DeltaSeconds, LEVELTICK_All);
			}
			return;		
		}
	}

	// update netdriver
	UNetDriver::TickDispatch( DeltaTime );
	FrameNum++;
	if (!ServerConnection)
		return;

	//hack
	if (bNoTick)
	{ 
		FrameNum--;
		return;
	}	

	UBOOL CheckTime = (ServerConnection->State == USOCK_Pending); //true if should set starttime
	BYTE Data[520]; //512+8
	FTime OldTime;
	int oldFrame;
	if(ServerConnection->State==USOCK_Pending || ServerConnection->State==USOCK_Open )
	{	
		// Read data from the demo file
		DWORD PacketBytes;
		INT PlayedThisTick = 0;		
		for( ; ; )
		{			
			// At end of file?
			if( FileAr->AtEnd() || FileAr->IsError() )
			{
			AtEnd:
				ServerConnection->State = USOCK_Closed;
				DemoEnded = 1;
				if (FileAr->IsError())
					debugf(TEXT("udemo: This demo is corrupt!"));
				//detatch demo link!
				if (FileAr)
				{ 
					delete FileAr;
					FileAr = NULL;
				}
				if( Loop || MessagePlay)
					GetLevel()->Exec( *FString::Printf(TEXT("DEMOPLAY \"%ls\""), *LoopURL.String()), *GLog );
				return;
			}
			// Update frames and time
			oldFrame = ServerFrameNum;
			OldTime = ServerPacketTime;
			*FileAr << ServerFrameNum;
			*FileAr << ServerPacketTime;
			if(!MessagePlay && ((!TimeBased && ServerFrameNum > FrameNum) || (TimeBased && ServerPacketTime > Time)))
			{
				if(CheckTime && ServerConnection->State == USOCK_Pending)
					StartTime = ServerPacketTime; //set start to packet after welcome?
				FileAr->Seek(FileAr->Tell() - sizeof(ServerFrameNum) - sizeof(ServerPacketTime));
				ServerPacketTime = OldTime;
				ServerFrameNum = oldFrame;
				if (NoFrameCap && !TimeBased) //sync time 
					Time = OldTime;			
				else if (TimeBased) //sync frames (only for transitions)
					FrameNum=oldFrame;
				break;
			}
			if(!MessagePlay && !NoFrameCap && !TimeBased && ServerPacketTime > Time)
			{
				// Busy-wait until it's time to play the frame.
				// WARNING: use appSleep() if appSeconds() isn't using CPU timestamp!
				// appSleep(ServerPacketTime - Time);
				appSleep(ServerPacketTime - Time);
			}
			//sync level time with demo!
			else if (NoFrameCap && GetLevel() && GetLevel()->GetLevelInfo() ) 
				GetLevel()->GetLevelInfo()->TimeDilation = RealDilation+(ServerPacketTime - Time);

			//alter timedilation with nofcap here!!!!
			*FileAr << PacketBytes;

			//stops crashes on truncated demos:
			if ((FileAr->Tell() + PacketBytes) > (unsigned int) FileAr->TotalSize()) 
				goto AtEnd;

			// Read data from file.
			FileAr->Serialize( Data, PacketBytes );
			if( FileAr->IsError() )
			{
				debugf( NAME_DevNet, TEXT("Failed to read demo file packet") );
				goto AtEnd;
			}

			// Update stats.
			if( PacketBytes )
				PlayedThisTick++;

			// Process incoming packet.
			float oldDilation = 0.0;
			if (GetLevel() && GetLevel()->GetLevelInfo())
				oldDilation = GetLevel()->GetLevelInfo()->TimeDilation;
			UPlayer* OldPlayer = NULL;
			if (SoundPlayer)
			{
				OldPlayer = SoundPlayer->Player;
				SoundPlayer->Player = GetLevel()->Engine->Client->Viewports(0);
				if (OldPlayer == SoundPlayer->Player) // pass actual viewport to tick loop can destroy input
					OldPlayer = NULL;
			}

			// (Anth) Being called in normal playback mode...
			CheckActors();
			
			UuReceivedRawPacket( Data, PacketBytes );

			TimeSync(ServerPacketTime,Time);

			if (SoundPlayer)
				SoundPlayer->Player = OldPlayer;
			if (GetLevel() && GetLevel()->GetLevelInfo() && Abs(GetLevel()->GetLevelInfo()->TimeDilation-oldDilation) >0.01)
			{
				RealDilation=GetLevel()->GetLevelInfo()->TimeDilation;
				if (!NoFrameCap)
					GetLevel()->GetLevelInfo()->TimeDilation*=Speed;				
			}		
			
			if (MessagePlay && Interface)
				Interface->eventNetPacketReceived(); //notify new packet!	

			// Only play one packet per tick on demo playback, until we're 
			// fully connected.  This is like the handshake for net play.
			if(ServerConnection->State == USOCK_Pending)
				break;
		}
	}

	// call event PreTick
	if (Interface)
	{
		FLOAT DeltaSeconds = Delta*Interface->DemoSpec->Level->TimeDilation;
		Interface->DemoSpec->eventPlayerTick(-DeltaSeconds);
	}

	unguard;
 }

/*-----------------------------------------------------------------------------
	CheckActors - (Anth) Uber lame hack to disable illegal actors
-----------------------------------------------------------------------------*/
void UuDemoDriver::CheckActors()
{
	// disabled for 469 (which can fix actor issues on the engine side)
}

/*-----------------------------------------------------------------------------
	ReceivedRawPacket
-----------------------------------------------------------------------------*/
void UuDemoDriver::UuReceivedRawPacket(void* InData, INT Count)
{
	BYTE* Data = (BYTE*)InData;
	
	ServerConnection->InByteAcc += Count + ServerConnection->PacketOverhead;
	ServerConnection->InPktAcc++;
	if (Count > 0)
	{
		BYTE LastByte = Data[Count - 1];
		if (LastByte)
		{
			INT BitSize = Count * 8 - 1;
			while (!(LastByte & 0x80))
			{
				LastByte *= 2;
				BitSize--;
			}
			FBitReader Reader(Data, BitSize);
			UuReceivedPacket(Reader);
		}
	}
}

/*-----------------------------------------------------------------------------
	ReceivedPacket
-----------------------------------------------------------------------------*/
void UuDemoDriver::UuReceivedPacket(FBitReader& Reader)
{
	if (Reader.IsError())	
		return;

	if (!ServerConnection->Channels[0] || !ServerConnection->Channels[0]->Closing)
		ServerConnection->LastReceiveTime = Time;

	const INT PacketId = MakeRelative(Reader.ReadInt(MAX_PACKETID), ServerConnection->InPacketId, MAX_PACKETID);
	if (PacketId > ServerConnection->InPacketId)
	{
		ServerConnection->InLossAcc += PacketId - ServerConnection->InPacketId - 1;
		ServerConnection->InPacketId = PacketId;
	}
	else ServerConnection->InOrdAcc++;

	ServerConnection->SendAck(PacketId);

	while (!Reader.AtEnd() && ServerConnection->State != USOCK_Closed)
	{
		UBOOL IsAck = Reader.ReadBit();
		if (Reader.IsError())
			return;

		if (IsAck)
		{
			INT AckPacketId = MakeRelative(Reader.ReadInt(MAX_PACKETID), ServerConnection->OutAckPacketId, MAX_PACKETID);
			if (Reader.IsError())
				return;

			if (AckPacketId > ServerConnection->OutAckPacketId)
			{
				for (INT NakPacketId = ServerConnection->OutAckPacketId + 1; NakPacketId < AckPacketId; NakPacketId++, ServerConnection->OutLossAcc++)
					ServerConnection->ReceivedNak(NakPacketId);
				ServerConnection->OutAckPacketId = AckPacketId;
			}

			for (INT i = ServerConnection->OpenChannels.Num() - 1; i >= 0; i--)
			{
				UChannel* Channel = ServerConnection->OpenChannels(i);
				for (FOutBunch* Out = Channel->OutRec; Out; Out = Out->Next)
				{
					if (Out->PacketId == AckPacketId)
					{
						Out->ReceivedAck = 1;
						if (Out->bOpen)
							Channel->OpenAcked = 1;
					}
				}
				if (Channel->OpenPacketId == AckPacketId) 
					Channel->OpenAcked = 1;
				Channel->ReceivedAcks();
			}
		}
		else
		{
			FInBunch Bunch(ServerConnection);
			BYTE bControl = Reader.ReadBit();
			Bunch.PacketId = PacketId;
			Bunch.bOpen = bControl ? Reader.ReadBit() : 0;
			Bunch.bClose = bControl ? Reader.ReadBit() : 0;
			Bunch.bReliable = Reader.ReadBit();
			Bunch.ChIndex = Reader.ReadInt(UNetConnection::MAX_CHANNELS);
			Bunch.ChSequence = Bunch.bReliable ? MakeRelative(Reader.ReadInt(MAX_CHSEQUENCE), ServerConnection->InReliable[Bunch.ChIndex], MAX_CHSEQUENCE) : 0;
			Bunch.ChType = (Bunch.bReliable || Bunch.bOpen) ? Reader.ReadInt(CHTYPE_MAX) : CHTYPE_None;
			INT BunchDataBits = Reader.ReadInt(ServerConnection->MaxPacket * 8);
			if (Reader.IsError())
				return;
			Bunch.SetData(Reader, BunchDataBits);
			if (Reader.IsError())
				return;

			if (!ServerConnection->Channels[Bunch.ChIndex] && !ServerConnection->Channels[0] && (Bunch.ChIndex != 0 || Bunch.ChType != CHTYPE_Control))
				return;

			UChannel* Channel = ServerConnection->Channels[Bunch.ChIndex];

			// stijn: demo manager hax. Do not create actor channels for bNetTemporary actors if we're just seeking
			if (Seeking && !Bunch.bReliable /*&& !Channel*/)
				continue;

			if (Bunch.bReliable && Bunch.ChSequence <= ServerConnection->InReliable[Bunch.ChIndex])
				continue;

			if (!Bunch.bReliable && (!Bunch.bOpen || !Bunch.bClose) && (!Channel || Channel->OpenPacketId == INDEX_NONE))
				continue;

			if (!Channel)
			{
				if (!UChannel::IsKnownChannelType(Bunch.ChType))
					return;

				Channel = ServerConnection->CreateChannel((EChannelType)Bunch.ChType, 0, Bunch.ChIndex);

				if (!Notify->NotifyAcceptingChannel(Channel))
				{
					FOutBunch CloseBunch(Channel, 1);
					check(!CloseBunch.IsError());
					check(CloseBunch.bClose);
					CloseBunch.bReliable = 1;
					Channel->SendBunch(&CloseBunch, 0);
					ServerConnection->FlushNet();
					delete Channel;
					if (Bunch.ChIndex == 0)
						ServerConnection->State = USOCK_Closed;
					continue;
				}

				// anth: TODO: check for illegal actor channels here maybe?
			}

			if (Bunch.bOpen)
			{
				Channel->OpenAcked = 1;
				Channel->OpenPacketId = PacketId;
			}

			Channel->ReceivedRawBunch(Bunch);
			ServerConnection->InBunAcc++;
		}
	}
}

/*-----------------------------------------------------------------------------
	GetLevel - Not used?
-----------------------------------------------------------------------------*/
ULevel* UuDemoDriver::GetLevel() 
{
	guard(UuDemoDriver::GetLevel);
	check(Notify);
	return Notify->NotifyGetLevel();
	unguard;
}

/*-----------------------------------------------------------------------------
	ReadTo - Reads to just before this time
-----------------------------------------------------------------------------*/
FTime UuDemoDriver::ReadTo(FTime GoalTime, UBOOL bPacketRead)
{
	guard(UuDemoDriver::ReadTo);
	int seekTo;
	DWORD PacketBytes; 
	FTime OldTime;
	int oldFrame;
	BYTE Data[520]; //512+8
	check(ServerConnection);
	Seeking = TRUE;
	while (!FileAr->AtEnd() && !FileAr->IsError() )
	{  
		oldFrame = ServerFrameNum;
		OldTime = ServerPacketTime;
		*FileAr << ServerFrameNum;
		if (FileAr->AtEnd() || FileAr->IsError())
		{
			debugf(TEXT("udemo: seekto failed - requested %lf - now at %lf - atend %d - iserror %d"), GoalTime.GetDouble(), ServerPacketTime.GetDouble(), FileAr->AtEnd(), FileAr->IsError());
			Seeking = FALSE;
			return ServerPacketTime;
		}
		*FileAr << ServerPacketTime;
		if (FileAr->AtEnd() || FileAr->IsError())
		{
			debugf(TEXT("udemo: seekto failed - requested %lf - now at %lf - atend %d - iserror %d"), GoalTime.GetDouble(), ServerPacketTime.GetDouble(), FileAr->AtEnd(), FileAr->IsError());
			Seeking = FALSE;
			return ServerPacketTime;
		}
		if(ServerPacketTime > GoalTime)
		{
			FTime OutTime = ServerPacketTime;
			FileAr->Seek(FileAr->Tell() - sizeof(ServerFrameNum) - sizeof(ServerPacketTime));
			if (bPacketRead){ //otherwise, readto is exact time!
				ServerPacketTime = OldTime;
				ServerFrameNum = oldFrame;
			}
			Time = ServerPacketTime;			//synch everything on jumps!
			FrameNum=ServerFrameNum;
//			debugf(TEXT("udemo: seekto succeeded - requested %lf - now at %lf - atend %d - iserror %d"), GoalTime.GetDouble(), ServerPacketTime.GetDouble(), FileAr->AtEnd(), FileAr->IsError());
			Seeking = FALSE;
			return OutTime;
		}
		*FileAr << PacketBytes;
		if (FileAr->AtEnd() || FileAr->IsError())
		{
			debugf(TEXT("udemo: seekto failed - requested %lf - now at %lf - atend %d - iserror %d"), GoalTime.GetDouble(), ServerPacketTime.GetDouble(), FileAr->AtEnd(), FileAr->IsError());
			Seeking = FALSE;
			return ServerPacketTime;
		}
		seekTo=FileAr->Tell() + PacketBytes;
		if (seekTo>FileAr->TotalSize()) //stops crashes on truncated demos
		{
			debugf(TEXT("udemo: seekto failed - possible truncated demo - requested %lf - now at %lf - atend %d - iserror %d"), GoalTime.GetDouble(), ServerPacketTime.GetDouble(), FileAr->AtEnd(), FileAr->IsError());
			Seeking = FALSE;
			return ServerPacketTime;
		}
		if (!bPacketRead)
			FileAr->Seek(seekTo); //move ahead by packetbytes
		else
		{
			TimeSync(ServerPacketTime,OldTime);
			FileAr->Serialize( Data, PacketBytes );
			ServerConnection->ReceivedRawPacket( Data, PacketBytes );
		}
	}

	debugf(TEXT("udemo: seekto failed - requested %lf - now at %lf - atend %d - iserror %d"), GoalTime.GetDouble(), ServerPacketTime.GetDouble(), FileAr->AtEnd(), FileAr->IsError());
	Seeking = FALSE;
	return ServerPacketTime;
	unguard;
}

/*-----------------------------------------------------------------------------
	getTime
-----------------------------------------------------------------------------*/
void UuDemoDriver::getTime()
{
	guard(UuDemoDriver::getTime);
	int seekTo;
	int oldPos = FileAr->Tell();
	DWORD PacketBytes; 
	while (!FileAr->AtEnd() && !FileAr->IsError() ){  //loop until done
		*FileAr << TotalFrames;
		if (FileAr->AtEnd() || FileAr->IsError())
			break;
		*FileAr << TotalTime;
		//	GLog->Logf(TEXT("time is %f"),ftime.GetFloat());
		if (FileAr->AtEnd() || FileAr->IsError())
			break;
		*FileAr << PacketBytes;
		if (FileAr->AtEnd() || FileAr->IsError())
			break;
		seekTo=FileAr->Tell() + PacketBytes;
		if (seekTo>FileAr->TotalSize()) //stops crashes on truncated demos
			break;
		FileAr->Seek(seekTo); //move ahead by packetbytes
	}
	FileAr->Seek(oldPos);

	unguard;
}

/*-----------------------------------------------------------------------------
	InitConnect - Connect with extra options
-----------------------------------------------------------------------------*/
UBOOL UuDemoDriver::InitConnect( FNetworkNotify* InNotify, FURL& ConnectURL, FString& Error )
{
	guard(UuDemoDriver::InitConnect);	
	if (ConnectURL==TEXT("")) //supa-hack!!!!!!!
		return 0;
	if( !UNetDriver::InitConnect( InNotify, ConnectURL, Error ) )
		return 0;
	if( !InitBase( 1, InNotify, ConnectURL, Error ) )
		return 0;

	Speed=1;
	RealDilation=1;
	
	// Playback, local machine is a client, and the demo stream acts "as if" it's the server.
	ServerConnection					= new UuDemoConnection( this, ConnectURL );			
	ServerConnection->CurrentNetSpeed	= 0x7fffffff;
	ServerConnection->State				= USOCK_Pending;

	// Start stream
	FileAr								= GFileManager->CreateFileReader( *DemoFilename );
	if( !FileAr )
	{
		Error = FString::Printf( TEXT("Couldn't open demo file %s for reading"), *DemoFilename );//!!localize!!
		return 0;
	}

	getTime(); //figure out the time
	if (FileAr->IsError())
	{
		// maybe it's just truncated. Try to recover
		delete FileAr;
		FileAr = GFileManager->CreateFileReader(*DemoFilename);
		if (!FileAr)
		{
			Error = FString::Printf(TEXT("Couldn't open demo file %s for reading"), *DemoFilename);//!!localize!!
			return 0;
		}
	}
	
	LoopURL				= ConnectURL;
	Want3rdP			= ConnectURL.HasOption(TEXT("3rdperson")); 
	TimeBased			= ConnectURL.HasOption(TEXT("timebased"));
	NoFrameCap          = ConnectURL.HasOption(TEXT("noframecap"));
	if (NoFrameCap) //can't have both!!!!!
		TimeBased = false; 
	Loop				= ConnectURL.HasOption(TEXT("loop"));
	MessagePlay			= ConnectURL.HasOption(TEXT("messageread"));
	if (MessagePlay)
		LoopURL.Op.RemoveItem(TEXT("messageread")); //hack
	return 1;
	unguard;
}

/*-----------------------------------------------------------------------------
	UuDemoConnection
-----------------------------------------------------------------------------*/
UuDemoConnection::UuDemoConnection(UNetDriver* InDriver, FURL& InURL)
	: UDemoRecConnection(InDriver, InURL)
{
	/*UuDemoPackageMap* DemoPackageMap = new(this) UuDemoPackageMap(this);
	delete PackageMap;
	PackageMap = DemoPackageMap;*/
}

/*-----------------------------------------------------------------------------
	GetDemoDriver
-----------------------------------------------------------------------------*/
UuDemoDriver* UuDemoConnection::GetDemoDriver() //new driver reading
{
	return (UuDemoDriver *)Driver;
}

/*-----------------------------------------------------------------------------
	HandleClientPlayer
-----------------------------------------------------------------------------*/
void UuDemoConnection::HandleClientPlayer( APlayerPawn* Pawn )
{
	guard(UAdvancedConnection::HandleClientPlayer);
	UViewport* Viewport = NULL;

	UClass* C = StaticLoadClass(AActor::StaticClass(), NULL, TEXT("Engine.DemoRecSpectator"), NULL, LOAD_NoFail, NULL);
	if (C && Pawn->IsA(C) && !GetDriver()->ClientThirdPerson)
		return;

	if (GetDemoDriver()->ClientHandled)
	{
		if (!GetDriver()->ClientThirdPerson) //when not server demo!
			GetDemoDriver()->SoundPlayer = Pawn;
		GetDemoDriver()->Interface->eventLinkToPlayer(GetDemoDriver()->SoundPlayer,!GetDemoDriver()->Want3rdP&&GetDemoDriver()->SoundPlayer); //give pawn reference!
		Pawn = GetDemoDriver()->Interface->DemoSpec;
		State = USOCK_Open;
		return;
	}
	GetDemoDriver()->ClientHandled = true;

	guard(SpawnSpectator);

	UClass* SpectatorClass = StaticLoadClass( APawn::StaticClass(), NULL, TEXT("udemo.DemoPlaybackSpec"), NULL, LOAD_NoFail, NULL );
	check(SpectatorClass);

	FVector Location(0,0,0);
	FRotator Rotation(0,0,0);

	guard(FindPlayerStart);
	for( INT i=0; i<Pawn->XLevel->Actors.Num(); i++ )
	{
		if( Pawn->XLevel->Actors(i) && Pawn->XLevel->Actors(i)->IsA(APlayerStart::StaticClass()) )
		{
			Location = Pawn->XLevel->Actors(i)->Location;
			Rotation = Pawn->XLevel->Actors(i)->Rotation;
			break;
		}
	}
	unguard;

	guard(SpawnDemoSpectator);
	GetDemoDriver()->SoundPlayer = NULL;
	if (!GetDriver()->ClientThirdPerson) //when not server demo!
		GetDemoDriver()->SoundPlayer = Pawn;
	Pawn = CastChecked<APlayerPawn>(Pawn->XLevel->SpawnActor( SpectatorClass, NAME_None, NULL, NULL, Location, Rotation, NULL, 1, 0 ));

	check(Pawn);
	check(Pawn->XLevel->Engine->Client);
	check(Pawn->XLevel->Engine->Client->Viewports.Num());

	guard(AssignPlayer);
	Viewport = Pawn->XLevel->Engine->Client->Viewports(0);
	Viewport->Actor->Player = NULL;
	Pawn->SetPlayer( Viewport );

	check (Pawn->Player);
	Viewport->Actor->Role		= ROLE_Authority;
	Viewport->Actor->ShowFlags	= SHOW_Backdrop | SHOW_Actors | SHOW_PlayerCtrl | SHOW_RealTime;
	Viewport->Actor->RendMap	= REN_DynLight;	
	Pawn->bNetOwner = 1;
	Pawn->Physics   = PHYS_Flying;
	Viewport->Input->ResetInput();

	//generate the interface object:
	guard(MakeInterface);
	UClass* DemoDriverClass = StaticLoadClass( UObject::StaticClass(), NULL, TEXT("udemo.DemoInterface"), NULL, LOAD_NoFail, NULL );
	GetDemoDriver()->Interface = (UDemoInterface*)ConstructObject<UObject>( DemoDriverClass );	
	check(GetDemoDriver()->Interface);
	GetDemoDriver()->Interface->DemoDriver=GetDemoDriver();
	GetDemoDriver()->Interface->DemoSpec=Pawn; //BE SURE THIS IS THE SPAWNED PAWN!!!!
	if (!GetDemoDriver()->TimeBased)
	{
		if (GetDemoDriver()->NoFrameCap)
			GetDemoDriver()->Interface->PlayBackMode=2;
		else
			GetDemoDriver()->Interface->PlayBackMode=1;
	}
	else
		GetDemoDriver()->Interface->PlayBackMode=0;
	GetDemoDriver()->Interface->bDoingMessagePlay = GetDemoDriver()->MessagePlay;
	GetDemoDriver()->Interface->mySpeed=1;
	GetDemoDriver()->Interface->eventLinkToPlayer(GetDemoDriver()->SoundPlayer,!GetDemoDriver()->Want3rdP&&GetDemoDriver()->SoundPlayer); //give pawn reference!
	unguard;
	unguard;
	unguard;
	unguard;

	// Mark this connection as open.
	State = USOCK_Open;		

	Viewport->Actor->Song        = Pawn->Level->Song;
	Viewport->Actor->SongSection = Pawn->Level->SongSection;
	Viewport->Actor->CdTrack     = Pawn->Level->CdTrack;
	Viewport->Actor->Transition  = MTRAN_Fade;
	check(Pawn->XLevel->Engine->Client);
	check(Pawn->XLevel->Engine->Client->Viewports.Num());

	unguard;
}

/*-----------------------------------------------------------------------------
	UuDemoRecPackageMap
-----------------------------------------------------------------------------*/

void UuDemoPackageMap::Compute()
{
	guard(UuDemoPackageMap::Compute);
	for (INT i = 0; i < List.Num(); i++)
		check(List(i).Linker);
	NameIndices.Empty(FName::GetMaxNames());
	NameIndices.Add(FName::GetMaxNames());
	for (INT i = 0; i < NameIndices.Num(); i++)
		NameIndices(i) = -1;
	LinkerMap.Empty();
	MaxObjectIndex = 0;
	MaxNameIndex = 0;
	//FString	Ver = UTexture::__Client->Viewports(0)->Actor->Level->EngineVersion;
	//INT iVer = strtol(TCHAR_TO_ANSI(*Ver), NULL, 10);

	{for (INT i = 0; i < List.Num(); i++)
	{
		FPackageInfo& Info = List(i);
		Info.ObjectBase = MaxObjectIndex;
		Info.NameBase = MaxNameIndex;
		Info.ObjectCount = Info.Linker->ExportMap.Num();
		Info.NameCount = Info.Linker->NameMap.Num();

		TArray<FGenerationInfo>* Generations = &Linker->Summary.Generations;

		Info.LocalGeneration = Generations->Num();
		if (Info.RemoteGeneration == 0)
			Info.RemoteGeneration = Info.LocalGeneration;

		Info.RemoteGeneration = LookupDemoGeneration(Info);
		if (Info.RemoteGeneration < Info.LocalGeneration)
		{
			Info.ObjectCount = Min(Info.ObjectCount, (*Generations)(Info.RemoteGeneration - 1).ExportCount);
			Info.NameCount = Min(Info.NameCount, (*Generations)(Info.RemoteGeneration - 1).NameCount);
			Info.LocalGeneration = Info.RemoteGeneration;
		}
		MaxObjectIndex += Info.ObjectCount;
		MaxNameIndex += Info.NameCount;

		for (INT j = 0; j < Min(Info.Linker->NameMap.Num(), Info.NameCount); j++)
			if (NameIndices(Info.Linker->NameMap(j).GetIndex()) == -1)
				NameIndices(Info.Linker->NameMap(j).GetIndex()) = Info.NameBase + j;
		LinkerMap.Set(Info.Linker, i);
	}}
	unguard;
}

INT UuDemoPackageMap::LookupDemoGeneration(FPackageInfo& PackageInfo)
{
	// Botpack
	if (PackageInfo.Guid == FGuid(0x1c696576, 0x11d38f44, 0x100067b9, 0xf6f8975a))
		return 14;
	// Core
	if (PackageInfo.Guid == FGuid(0x4770b884, 0x11d38e3e, 0x100067b9, 0xf6f8975a))
		return 10;
	// Editor
	if (PackageInfo.Guid == FGuid(0x4770b886, 0x11d38e3e, 0x100067b9, 0xf6f8975a))
		return 11;
	// Engine
	if (PackageInfo.Guid == FGuid(0xd18a7b92, 0x11d38f04, 0x100067b9, 0xf6f8975a))
		return 17;
	// Fire
	if (PackageInfo.Guid == FGuid(0x4770b888, 0x11d38e3e, 0x100067b9, 0xf6f8975a))
		return 10;
	// IpDrv
	if (PackageInfo.Guid == FGuid(0x4770b889, 0x11d38e3e, 0x100067b9, 0xf6f8975a))
		return 10;
	// IpServer
	if (PackageInfo.Guid == FGuid(0x4770b88f, 0x11d38e3e, 0x100067b9, 0xf6f8975a))
		return 11;
	// UBrowser
	if (PackageInfo.Guid == FGuid(0x4770b88b, 0x11d38e3e, 0x100067b9, 0xf6f8975a))
		return 10;
	// UTBrowser
	if (PackageInfo.Guid == FGuid(0x4770b893, 0x11d38e3e, 0x100067b9, 0xf6f8975a))
		return 10;
	// UTMenu
	if (PackageInfo.Guid == FGuid(0x1c696577, 0x11d38f44, 0x100067b9, 0xf6f8975a))
		return 11;
	// UTServerAdmin
	if (PackageInfo.Guid == FGuid(0x4770b891, 0x11d38e3e, 0x100067b9, 0xf6f8975a))
		return 10;
	// UWeb
	if (PackageInfo.Guid == FGuid(0x4770b88a, 0x11d38e3e, 0x100067b9, 0xf6f8975a))
		return 10;
	// UWindow
	if (PackageInfo.Guid == FGuid(0x4770b887, 0x11d38e3e, 0x100067b9, 0xf6f8975a))
		return 10;
	// UnrealI
	if (PackageInfo.Guid == FGuid(0x4770b88d, 0x11d38e3e, 0x100067b9, 0xf6f8975a))
		return 1;
	// UnrealShare
	if (PackageInfo.Guid == FGuid(0x4770b88c, 0x11d38e3e, 0x100067b9, 0xf6f8975a))
		return 1;
	// De
	if (PackageInfo.Guid == FGuid(0xfb1eb231, 0x4d8bf569, 0xae12c6bf, 0x1a08a2f7))
		return 1;
	// epiccustommodels
	if (PackageInfo.Guid == FGuid(0x13f8255a, 0x11d3dba0, 0x1000cbb9, 0xf6f8975a))
		return 2;
	// multimesh 
	if (PackageInfo.Guid == FGuid(0x2db53b00, 0x11d3e900, 0x1000d3b9, 0xf6f8975a))
		return 8;
	// relics
	if (PackageInfo.Guid == FGuid(0xd011f66e, 0x11d3e9b8, 0x1000d5b9, 0xf6f8975a))
		return 9;
	// relicsbindings
	if (PackageInfo.Guid == FGuid(0x465ad1fe, 0x11d3df5c, 0x1000cdb9, 0xf6f8975a))
		return 2;
	return PackageInfo.RemoteGeneration;
}

/*-----------------------------------------------------------------------------
	The End.
-----------------------------------------------------------------------------*/
