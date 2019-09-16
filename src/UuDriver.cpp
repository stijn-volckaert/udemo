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
		if (GetLevel()->GetLevelInfo()->Pauser == TEXT("")
			&& GetLevel()->GetLevelInfo()->TimeSeconds + Interface->ltsoffset - Interface->DemoSpec->GameReplicationInfo->SecondCount > RealDilation)
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
void UuDemoDriver::TickDispatch( FLOAT DeltaTime )
{
	guard(UuDemoDriver:TickDispatch);	
	
	// Calc deltatime
	if(ServerConnection)
	{
		if (!NoFrameCap)
			DeltaTime*=Speed; //alter speed! 
		if (Paused)
		{
			if (Interface)
			{
				Interface->DemoSpec->eventPlayerInput(DeltaTime);
				Interface->DemoSpec->eventUpdateEyeHeight(DeltaTime);
				Interface->DemoSpec->eventPlayerTick(DeltaTime);
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
				//detatch demo link!
				if (FileAr)
				{ 
					delete FileAr;
					FileAr = NULL;
				}
				if( Loop || MessagePlay)
					GetLevel()->Exec( *(FString(TEXT("DEMOPLAY "))+(*LoopURL.String())), *GLog );
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
			if (SoundPlayer)
				SoundPlayer->Player = GetLevel()->Engine->Client->Viewports(0);

			// (Anth) Being called in normal playback mode...
			CheckActors();

			//((UAdvancedConnection*)ServerConnection)->UuReceivedRawPacket( Data, PacketBytes );
			ServerConnection->ReceivedRawPacket( Data, PacketBytes );

			TimeSync(ServerPacketTime,Time);

			if (SoundPlayer)
				SoundPlayer->Player=NULL;
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

	unguard;
 }

/*-----------------------------------------------------------------------------
	CheckActors - (Anth) Uber lame hack to disable illegal actors
-----------------------------------------------------------------------------*/
void UuDemoDriver::CheckActors()
{
	if (Interface)
	{		
		for( INT i=0; i<Interface->DemoSpec->XLevel->Actors.Num(); i++ )
		{			
			if (Interface->DemoSpec->XLevel->Actors(i) && Interface->DemoSpec->XLevel->Actors(i)->Tag != TEXT("UDEMO"))
			{
				bool bNoTag = false;
				FString ActorName = Interface->DemoSpec->XLevel->Actors(i)->GetName();

				for ( INT j=0; j<20; j++)
				{
					// Check if actor is illegal!
					if (Interface->IllegalActors[j] != TEXT("") && ActorName.InStr(Interface->IllegalActors[j]) != -1 )
					{
						bNoTag = true;
						
						if (Interface->DemoSpec->XLevel->Actors(i)->bDeleteMe)
						{
							Interface->DemoSpec->XLevel->DestroyActor(Interface->DemoSpec->XLevel->Actors(i),1);
							Interface->DemoSpec->XLevel->CleanupDestroyed(true);
							bNoTag=false;
						}
						else
							Interface->DemoSpec->XLevel->Actors(i)->bDeleteMe = true;
					}
				}

				if (!bNoTag)
					Interface->DemoSpec->XLevel->Actors(i)->Tag = TEXT("UDEMO");
			}
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
	while (!FileAr->AtEnd() && !FileAr->IsError() )
	{  
		oldFrame = ServerFrameNum;
		OldTime = ServerPacketTime;
		*FileAr << ServerFrameNum;
		if (FileAr->AtEnd() || FileAr->IsError())
			return ServerPacketTime;
		*FileAr << ServerPacketTime;
		if (FileAr->AtEnd() || FileAr->IsError())
			return ServerPacketTime;
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
			return OutTime;
		}
		*FileAr << PacketBytes;
		if (FileAr->AtEnd() || FileAr->IsError())
			return ServerPacketTime;
		seekTo=FileAr->Tell() + PacketBytes;
		if (seekTo>FileAr->TotalSize()) //stops crashes on truncated demos
			return ServerPacketTime;
		if (!bPacketRead)
			FileAr->Seek(seekTo); //move ahead by packetbytes
		else
		{
			TimeSync(ServerPacketTime,OldTime);
			FileAr->Serialize( Data, PacketBytes );
			ServerConnection->ReceivedRawPacket( Data, PacketBytes );
		}
	}
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
	ServerConnection					= new UAdvancedConnection( this, ConnectURL );			
	ServerConnection->CurrentNetSpeed	= 1000000;
	ServerConnection->State				= USOCK_Pending;

	// Start stream
	FileAr								= GFileManager->CreateFileReader( *DemoFilename );
	if( !FileAr )
	{
		Error = FString::Printf( TEXT("Couldn't open demo file %s for reading"), *DemoFilename );//!!localize!!
		return 0;
	}

	getTime(); //figure out the time
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
	UuReceivedRawPacket - (Anth) ReceivedRawPacket Reimplementation. 
	Super hack to check demo format. Can maybe use this to restore net 
	compatibility later on... Ideally the demo recording should be modified
	though! Need some more reversing to fix this.
-----------------------------------------------------------------------------*/
void UAdvancedConnection::UuReceivedRawPacket(void* InData, INT Count)
{
	BYTE* Data = (BYTE*)InData;

	InByteAcc += Count + PacketOverhead;
	InPktAcc++;
	if( Count>0 )
	{
		BYTE LastByte = Data[Count-1];
		if( LastByte )
		{
			INT BitSize = Count*8-1;
			while( !(LastByte & 0x80) )
			{
				LastByte *= 2;
				BitSize--;
			}

			// Manually parse bunches until the first actorchannel bunch is received
			// v451b and later will send a playerpawn ref in the first actorchannel bunch
			// v451a and earlier will send the levelinfo from the mapfile first...
#if 0
			if (!CheckedFormat)
			{
				DWORD PacketId			= 0;
				BYTE IsAck				= 0;
				BYTE IsControlChannel	= 0;
				BYTE ShouldOpenChannel	= 0;
				BYTE ShouldCloseChannel	= 0;
				BYTE ReliableBunch		= 0;
				INT ChannelId			= 0;
				INT ChannelSequence		= 0;
				INT ChannelType			= 0;
				INT BunchSize			= 0;
			
				FBitReader TempReader( Data, BitSize );
				PacketId = TempReader.ReadInt(MAX_PACKETID);				
				IsAck = TempReader.ReadBit();				
				IsControlChannel = TempReader.ReadBit();				
				if (IsControlChannel)
				{
					ShouldOpenChannel  = TempReader.ReadBit();
					ShouldCloseChannel = TempReader.ReadBit();
				}
				ReliableBunch = TempReader.ReadBit();				
				ChannelId = TempReader.ReadInt(MAX_CHANNELS);
				if (ReliableBunch)				
					ChannelSequence = TempReader.ReadInt(MAX_CHSEQUENCE);								
				if (ShouldOpenChannel || ReliableBunch)				
					ChannelType = TempReader.ReadInt(CHTYPE_MAX);									
				BunchSize = TempReader.ReadInt(MaxPacket*8);

				if (ChannelType == CHTYPE_Actor)
				{
					CheckedFormat = 1;

					BYTE IsDynamic = TempReader.ReadBit();
					INT Index = TempReader.ReadInt(PackageMap->GetMaxObjectIndex());

					if (Index >= PackageMap->List(0).ObjectCount)
					{
						GLog->Logf(TEXT("udemo: demo was recorded by UTv451b or later."));
						Is451bClient = 1;


						// Attempted fix. Works to fix PackageMaps but doesn't really help with ClassNetCaches
						// Need some serious changes to make this work
						/*
						for (INT i = 0; i < PackageMap->List.Num(); ++i)
						{							
							if (appStrcmp(PackageMap->List(i).Guid.String(), TEXT("D18A7B9211D38F04100067B9F6F8975A")) == 0)		// Engine
							{
								if (PackageMap->List(i).ObjectCount < 5421)
								{
									GLog->Logf(TEXT("udemo: Using udemo SuperDuperHack to modify Engine.ObjectCount/NameCount: %d/%d => %d/%d"), 
										PackageMap->List(i).ObjectCount, PackageMap->List(i).NameCount, 5421, 3390);
									PackageMap->List(i).ObjectCount = 5421;
									PackageMap->List(i).NameCount	= 3390;
								}
							}
							else if (appStrcmp(PackageMap->List(i).Guid.String(), TEXT("4770B88411D38E3E100067B9F6F8975A")) == 0)	// Core
							{
								if (PackageMap->List(i).ObjectCount < 674)
								{
									GLog->Logf(TEXT("udemo: Using udemo SuperDuperHack to modify Core.ObjectCount/NameCount: %d/%d => %d/%d"), 
										PackageMap->List(i).ObjectCount, PackageMap->List(i).NameCount, 674, 333);
									PackageMap->List(i).ObjectCount = 674;
									PackageMap->List(i).NameCount	= 333;
								}
							}
						}

						// Recalc bases
						INT NameBase = 0, ObjectBase = 0;
						GLog->Logf(TEXT("udemo: Recalculating bases..."));
						for (INT i = 0; i < PackageMap->List.Num(); ++i)
						{
							PackageMap->List(i).NameBase	= NameBase;
							PackageMap->List(i).ObjectBase	= ObjectBase;
							NameBase	+= PackageMap->List(i).NameCount;
							ObjectBase	+= PackageMap->List(i).ObjectCount;	
							GLog->Logf(TEXT("udemo: PackageMap[%02d] -> %s:%s - %d:%d - %d:%d"), i, PackageMap->List(i).Guid.String(), *PackageMap->List(i).Linker->Filename, 
								PackageMap->List(i).ObjectBase, PackageMap->List(i).ObjectCount, PackageMap->List(i).NameBase, PackageMap->List(i).NameCount);
						}

						GLog->Logf(TEXT("udemo: Done!"));
						*/
					}
				}
			}
#endif
			
			FBitReader Reader( Data, BitSize );
			ReceivedPacket( Reader );
		}
	}
}

/*-----------------------------------------------------------------------------
	StaticConstructor
-----------------------------------------------------------------------------*/
void UAdvancedConnection::StaticConstructor()
{
	guard(UAdvancedConnection::StaticConstructor);
	unguard;
}

/*-----------------------------------------------------------------------------
	Constructor
-----------------------------------------------------------------------------*/
UAdvancedConnection::UAdvancedConnection( UNetDriver* InDriver, const FURL& InURL )
: UDemoRecConnection( InDriver, InURL )
{
	guard(UAdvancedConnection::UAdvancedConnection);	
	CheckedFormat	= 0;
	Is451bClient	= 0;
	unguard;
}

/*-----------------------------------------------------------------------------
	GetDemoDriver
-----------------------------------------------------------------------------*/
UuDemoDriver* UAdvancedConnection::GetDemoDriver() //new driver reading
{
	return (UuDemoDriver *)Driver;
}

/*-----------------------------------------------------------------------------
	HandleClientPlayer
-----------------------------------------------------------------------------*/
void UAdvancedConnection::HandleClientPlayer( APlayerPawn* Pawn )
{
	guard(UAdvancedConnection::HandleClientPlayer);
	UViewport* Viewport = NULL;
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
	The End.
-----------------------------------------------------------------------------*/
