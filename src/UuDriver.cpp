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
				if (FileAr->IsError())
					debugf(TEXT("udemo: This demo is corrupt!"));
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
	ServerConnection					= new UuDemoConnection( this, ConnectURL );			
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
	FString	Ver = UTexture::__Client->Viewports(0)->Actor->Level->EngineVersion;
	INT iVer = strtol(TCHAR_TO_ANSI(*Ver), NULL, 10);

	{for (INT i = 0; i < List.Num(); i++)
	{
		FPackageInfo& Info = List(i);
		Info.ObjectBase = MaxObjectIndex;
		Info.NameBase = MaxNameIndex;
		Info.ObjectCount = Info.Linker->ExportMap.Num();
		Info.NameCount = Info.Linker->NameMap.Num();

		TArray<FGenerationInfo>* Generations = (iVer < 469) ?
			reinterpret_cast<TArray<FGenerationInfo>*>(reinterpret_cast<unsigned long>(&Info.Linker->Summary.Guid) + sizeof(FGuid)) :
			*reinterpret_cast<TArray<FGenerationInfo>**>(reinterpret_cast<unsigned long>(&Info.Linker->Summary.Guid) + sizeof(FGuid));

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
	return PackageInfo.RemoteGeneration;
}

/*-----------------------------------------------------------------------------
	The End.
-----------------------------------------------------------------------------*/
