/*=============================================================================
	DemoInterface.cpp: Demo control interface. Allows seeking, speed control etc

	Revision history:
		* Created by UsAaR33
		* Anth: Cleaned up, made some cross-platform modifications
		* Anth: Added several fixes, added UTPG compatibility for demo restarting
=============================================================================*/

/*-----------------------------------------------------------------------------
	Includes/Definitions
-----------------------------------------------------------------------------*/
#include "udemoprivate.h"

/*-----------------------------------------------------------------------------
	Package/Name registration definitions - must be done once per package
-----------------------------------------------------------------------------*/
// Register package - Case sensitive
IMPLEMENT_PACKAGE(udemo);
// Register class - Case sensitive
IMPLEMENT_CLASS(UDemoInterface);
IMPLEMENT_CLASS(UuDemoDriver);
IMPLEMENT_CLASS(UAdvancedConnection);
IMPLEMENT_CLASS(Uudnative);
IMPLEMENT_CLASS(UDReader);

// Register names & functions
#define NAMES_ONLY
// Redefinition of AUTOGENERATE_NAME
#define AUTOGENERATE_NAME(name) UDEMO_API FName UDEMO_##name=FName(TEXT(#name));
// Redefinition of AUTOGENERATE_FUNCTION (auto implement)
#define AUTOGENERATE_FUNCTION(cls,idx,name) IMPLEMENT_FUNCTION(cls,idx,name)
// Reinclude classes header for name registration
#include "udemoClasses.h"
// All done!
#undef AUTOGENERATE_FUNCTION
#undef AUTOGENERATE_NAME
#undef NAMES_ONLY

/*-----------------------------------------------------------------------------
	execGetStartTime - The timestamp when the demo was started
-----------------------------------------------------------------------------*/
void UDemoInterface::execGetStartTime (FFrame& Stack, RESULT_DECL)
{
	guard (UDemoInterface::execGetStartTime);
	P_FINISH;
	*(FLOAT*)Result = DemoDriver->StartTime.GetFloat();
	unguard;
}

/*-----------------------------------------------------------------------------
	execSetPlayBackMode - set the playback mode. Options:
	* Time based (PMode 0)
	* Frame based (PMode 1)
	* No frame cap (PMode 2)
-----------------------------------------------------------------------------*/
void UDemoInterface::execSetPlayBackMode (FFrame& Stack, RESULT_DECL)
{
	guard (UDemoInterface::execSetPlayBackMode);
	P_GET_BYTE(PMode);
	P_FINISH;
	if (PMode==PlayBackMode)
		return;
	// going to timebased from framebased. synch!
	if (PMode == 0 && PlayBackMode == 1)
		DemoDriver->Time = DemoDriver->ServerPacketTime;
	DemoDriver->TimeBased = false;
	DemoDriver->NoFrameCap = false;
	// no frame cap!
	if (PMode == 2)
	{
		DemoDriver->NoFrameCap = true;
		DemoSpec->Level->TimeDilation = DemoDriver->RealDilation;
	}
	// allow speed control!
	else
		DemoSpec->Level->TimeDilation = DemoDriver->RealDilation*DemoDriver->Speed;
	//time based
	if (PMode == 0)
		DemoDriver->TimeBased = true;

	PlayBackMode = PMode;
	unguard;
}

/*-----------------------------------------------------------------------------
	execPauseDemo - safely pause a demo
	Note: uscript should check for admin pause state!
-----------------------------------------------------------------------------*/
void UDemoInterface::execPauseDemo (FFrame& Stack, RESULT_DECL)
{
	guard (UDemoInterface::execPauseDemo);
	P_GET_UBOOL(doPause);
	P_FINISH;
	DemoDriver->Paused=doPause;
	if (doPause)
		DemoSpec->Level->Pauser=TEXT("ClientPaused"); //flag.. hack sorta.
	else
		DemoSpec->Level->Pauser=TEXT("");
	unguard;
}

/*-----------------------------------------------------------------------------
	execIsPaused - determine how the demo is currently paused
-----------------------------------------------------------------------------*/
void UDemoInterface::execIsPaused (FFrame& Stack, RESULT_DECL)
{
	guard (UDemoInterface::execIsPaused);
	P_FINISH;
	if (DemoDriver->Paused)
		*(BYTE*)Result = 2;
	else if (DemoSpec->Level->Pauser!=TEXT("")) //admin paused
		*(BYTE*)Result = 1;
	else
		*(BYTE*)Result = 0;
	unguard;
}

/*-----------------------------------------------------------------------------
	execGetTotalFrames - Get total amount of frames in the demo
-----------------------------------------------------------------------------*/
void UDemoInterface::execGetTotalFrames (FFrame& Stack, RESULT_DECL)
{
	guard (UDemoInterface::execGetTotalFrames);
	P_FINISH;
	*(INT*)Result = DemoDriver->TotalFrames;
	unguard;
}

/*-----------------------------------------------------------------------------
	execGetCurrentFrame - Get the frame the demo is on
	i.e. framenum at start of last packet read
-----------------------------------------------------------------------------*/
void UDemoInterface::execGetCurrentFrame (FFrame& Stack, RESULT_DECL)
{
	guard (UDemoInterface::execGetCurrentFrame);
	*(INT*)Result = DemoDriver->ServerFrameNum;
	P_FINISH;
	unguard;
}

/*-----------------------------------------------------------------------------
	execGetTotalTime - Get the total playtime of the demo at normal speed
-----------------------------------------------------------------------------*/
void UDemoInterface::execGetTotalTime (FFrame& Stack, RESULT_DECL)
{
	guard (UDemoInterface::execGetTotalTime);
	*(FLOAT*)Result = DemoDriver->TotalTime.GetFloat();
	P_FINISH;
	unguard;
}

/*-----------------------------------------------------------------------------
	execGetCurrentTime - Get the timestamp of the start of last packet read
-----------------------------------------------------------------------------*/
void UDemoInterface::execGetCurrentTime (FFrame& Stack, RESULT_DECL)
{
	guard (UDemoInterface::execGetCurrentTime);
	*(FLOAT*)Result = DemoDriver->ServerPacketTime.GetFloat();
	P_FINISH;
	unguard;
}

/*-----------------------------------------------------------------------------
	execReadCache - Read a certain amount of packets from the UuDriver.
	Reading in steps of inc until ServerPacketTime >= TimeTo
-----------------------------------------------------------------------------*/
void UDemoInterface::execReadCache (FFrame& Stack, RESULT_DECL)
{
	guard (UDemoInterface::execReadCache);
	P_GET_FLOAT(TimeTo);
	P_GET_FLOAT(inc); //increment
	P_FINISH;
	FTime Res;
	BYTE Done = 0;

	// Assertions
	check(inc>0);
	check(DemoSpec->XLevel);
	check(DemoSpec->XLevel->Actors.Num());

	DemoDriver->bNoTick=true;
	ltsoffset += (TimeTo-DemoDriver->ServerPacketTime.GetFloat())*DemoDriver->RealDilation;

	// Looping until diff between TimeTo and ServerPacketTime is less than inc
	while(!Done)
	{
		Res = DemoDriver->ReadTo(DemoDriver->ServerPacketTime + inc);
		if (TimeTo-Res.GetFloat()<inc)
			Done = 1;
		guard(ActorTick);
		DemoSpec->GetLevel()->Tick( LEVELTICK_All, DemoDriver->RealDilation*inc );
		unguard;
	}

	// Because we might have stopped before TimeTo ...
	if (TimeTo-Res.GetFloat()>0)
	{
		DemoDriver->ReadTo(TimeTo);
		guard(ActorTick2);
		DemoSpec->GetLevel()->Tick( LEVELTICK_All, DemoDriver->RealDilation*(TimeTo-Res.GetFloat()) );
		unguard;
	}

	/*guard(UDemoInterface::ChannelSync);
	for (int i=0;i<DemoDriver->ServerConnection->MAX_CHANNELS;i++)
		if (DemoDriver->ServerConnection->Channels[i])
			DemoDriver->ServerConnection->Channels[i]->Connection = DemoDriver->ServerConnection;
	unguard;*/

	DemoDriver->bNoTick=false;
	DemoDriver->Time=DemoDriver->ServerPacketTime; //double hack.. geez
	eventLinkToPlayer(DemoDriver->SoundPlayer,DemoDriver->Want3rdP&&DemoDriver->SoundPlayer); //reset if lost!
	unguard;
}

/*-----------------------------------------------------------------------------
	execReadTo - This would be the seekto thingie! Need to fix this, crashes
	very often on modern systems!
-----------------------------------------------------------------------------*/
void UDemoInterface::execReadTo (FFrame& Stack, RESULT_DECL)
{
	guard (UDemoInterface::execReadTo);
	P_GET_FLOAT(TimeTo);
	P_FINISH;

	//update timeseconds
	ltsoffset += (TimeTo-DemoDriver->ServerPacketTime.GetFloat())*DemoDriver->RealDilation;
	GLog->Logf(*FString::Printf(TEXT("udemo: ReadTo %f. Now = %f. Dilation = %f."),TimeTo,DemoDriver->ServerPacketTime.GetFloat(),DemoDriver->RealDilation));
	DemoDriver->ReadTo(FTime(TimeTo));

	unguard;
}

/*-----------------------------------------------------------------------------
	execJumpBack - Wipes out channel table for the serverconnection and restarts
	the demo. We can then seek to a specific location inside the demo...
-----------------------------------------------------------------------------*/
void UDemoInterface::execJumpBack (FFrame& Stack, RESULT_DECL)
{
	guard (UDemoInterface::execJumpBack);
	P_FINISH;

	INT								i;
	INT*							InPacketId;			// Ptr to INT UNetConnection::InPacketId
	INT*							OutPacketId;		// Ptr to INT UNetConnection::OutPacketId
	INT*							OutAckPacketId;		// Ptr to INT UNetConnection::OutAckPacketId
	UChannel**						Channels;			// Ptr to UChannel* UNetConnection::Channels[]
	INT*							InReliable;			// Ptr to INT UNetConnection::InReliable[]
	INT*							OutReliable;		// Ptr to INT UNetConnection::OutReliable[]
	TArray<UChannel*>*				OpenChannels;		// Ptr to TArray<UChannel*> UNetConnection::OpenChannels
	TMap<AActor*,UActorChannel*>*	ActorChannels;		// Ptr to TMap<AActor*,UActorChannel*> UNetConnection::ActorChannels

	FString	Ver = UTexture::__Client->Viewports(0)->Actor->Level->EngineVersion;
	INT iVer = strtol(TCHAR_TO_ANSI(*Ver), NULL, 10);

	GLog->Logf(TEXT("UDEMO: Calculating Channel Positions..."));

	// (Anth) New uber hack here. This was fun to figure out.
	if (iVer > 436 && iVer < 469)
	{
		// Must be UTPG patch...
		InPacketId		= (INT*)							( (DWORD)DemoDriver->ServerConnection + 0x0E68 );
		OutPacketId		= (INT*)							( (DWORD)DemoDriver->ServerConnection + 0x0E6C );
		OutAckPacketId	= (INT*)							( (DWORD)DemoDriver->ServerConnection + 0x0E70 );
		Channels		= (UChannel**)						( (DWORD)DemoDriver->ServerConnection + 0x0E74 );
		OutReliable		= (INT*)							( (DWORD)DemoDriver->ServerConnection + 0x1E70 );
		InReliable		= (INT*)							( (DWORD)DemoDriver->ServerConnection + 0x2E6C );
		OpenChannels	= (TArray<UChannel*>*)				( (DWORD)DemoDriver->ServerConnection + 0x3E80 );
		ActorChannels	= (TMap<AActor*,UActorChannel*>*)	( (DWORD)DemoDriver->ServerConnection + 0x3E98 );
	}
	else if (iVer > 400 && iVer <= 436)
	{
		// Standard v432 structures
		InPacketId		= (INT*)							( (DWORD)DemoDriver->ServerConnection + 0x0E54 );
		OutPacketId		= (INT*)							( (DWORD)DemoDriver->ServerConnection + 0x0E58 );
		OutAckPacketId	= (INT*)							( (DWORD)DemoDriver->ServerConnection + 0x0E5C );
		Channels		= (UChannel**)						( (DWORD)DemoDriver->ServerConnection + 0x0E60 );
		OutReliable		= (INT*)							( (DWORD)DemoDriver->ServerConnection + 0x1E5C );
		InReliable		= (INT*)							( (DWORD)DemoDriver->ServerConnection + 0x2E58 );
		OpenChannels	= (TArray<UChannel*>*)				( (DWORD)DemoDriver->ServerConnection + 0x3E6C );
		ActorChannels	= (TMap<AActor*,UActorChannel*>*)	( (DWORD)DemoDriver->ServerConnection + 0x3E84 );
	}
	else
	{
		InPacketId = &DemoDriver->ServerConnection->InPacketId;
		OutPacketId = &DemoDriver->ServerConnection->OutPacketId;
		OutAckPacketId = &DemoDriver->ServerConnection->OutAckPacketId;
		Channels = reinterpret_cast<UChannel**>(&DemoDriver->ServerConnection->Channels);
		OutReliable = reinterpret_cast<INT*>(&DemoDriver->ServerConnection->OutReliable);
		InReliable = reinterpret_cast<INT*>(&DemoDriver->ServerConnection->InReliable);
		OpenChannels = &DemoDriver->ServerConnection->OpenChannels;
		ActorChannels = &DemoDriver->ServerConnection->ActorChannels;
	}

	// Destroy ALL actor channels (but not control channel!!!)
	GLog->Logf(TEXT("UDEMO: Destroying Channels..."));
	for (i = 0; i < UNetConnection::MAX_CHANNELS; i++)
	{
		// Close and Destroy the channel and the actor associated with it
		if (Channels[i])
		{
			if (Channels[i]->ChType == CHTYPE_Actor)
			{
				//GLog->Logf(TEXT("UDEMO: >>> Associated Actor: %s"),((UActorChannel*)Channels[i])->Actor->GetFullName());

				if (((UActorChannel*)Channels[i])->Actor)
					DemoSpec->XLevel->DestroyActor(((UActorChannel*)Channels[i])->Actor, 1);

				Channels[i]->Connection = DemoDriver->ServerConnection;
				Channels[i]->Close();
				Channels[i]->ConditionalDestroy();

				if (Channels[i])
				{
					Channels[i]->Connection = DemoDriver->ServerConnection;
					delete Channels[i];
					Channels[i] = 0;
				}
			}
			// Reset control channel
			else if (Channels[i]->ChType == CHTYPE_Control)
			{
				Channels[i]->NumInRec	= 0;
				Channels[i]->NumOutRec	= 0;
				Channels[i]->InRec		= NULL;
				Channels[i]->OutRec		= NULL;
				Channels[i]->Broken		= 0;
			}
		}
		if (!Channels[i] || Channels[i]->ChType != CHTYPE_Control)
		{
			InReliable[i]	= 0;
			OutReliable[i]	= 0;
			Channels[i]		= 0;
		}
	}

	// (Anth) Can't call Empty cause it will kill the control channel
	// ==> NULLing channels instead (hf garbagecollector)
	GLog->Logf(TEXT("UDEMO: Killing Open Channels (%d)"),	OpenChannels->Num());
	for (i = 1; i < OpenChannels->Num(); ++i)
		(*OpenChannels)(i) = NULL;

	// (Anth) Should be empty already?!
	GLog->Logf(TEXT("UDEMO: Killing Actor Channels (%d)"),	ActorChannels->Num());
	ActorChannels->Empty();

	// Kill all actors without an actor channel (but not the demospec!)
	GLog->Logf(TEXT("UDEMO: Killing Static Actors"));
	UClass* EffectsClass = StaticLoadClass( AActor::StaticClass(), NULL, TEXT("engine.Effects"), NULL, LOAD_NoFail, NULL );
	for( i=0; i<DemoSpec->XLevel->Actors.Num(); i++ )
	{
		// Player owned actor that is not the demo spec?
		if (DemoSpec->XLevel->Actors(i)
			&& DemoSpec->XLevel->Actors(i) != DemoSpec
			&& DemoSpec->XLevel->Actors(i)->Role == ROLE_Authority
			&& !(DemoSpec->XLevel->Actors(i)->bStatic && DemoSpec->XLevel->Actors(i)->bNoDelete))
		{
			// (Anth)
			// Projectiles, decals, effects have no actor channel but still have to be deleted
			// Keeping AInfo objects because destroying them would ruin huds, scoreboards and whatnot
			if (DemoSpec->XLevel->Actors(i)->IsA(AProjectile::StaticClass())
				|| DemoSpec->XLevel->Actors(i)->IsA(ADecal::StaticClass())
				|| DemoSpec->XLevel->Actors(i)->IsA(ALight::StaticClass())
				|| DemoSpec->XLevel->Actors(i)->IsA(EffectsClass)
				/*|| DemoSpec->XLevel->Actors(i)->IsA(AInfo::StaticClass())*/) //keep AInfo?
			{
				DemoSpec->XLevel->DestroyActor(DemoSpec->XLevel->Actors(i), 1); //even if net!
			}
		}
	}

	// Garbage collect yay
	DemoSpec->XLevel->CleanupDestroyed(true);

	GLog->Logf(TEXT("UDEMO: Restarting demo stream"));

	// Reset UNetConnection packet indices
	(*InPacketId) = (*OutPacketId) = (*OutAckPacketId) = 0;

	// Reset Demo driver
	DemoDriver->ServerPacketTime	= FTime(0.0);
	DemoDriver->Time				= FTime(0.0);
	DemoDriver->ServerFrameNum		= 0;
	DemoDriver->FrameNum			= 0;
	DemoDriver->FileAr->Seek(0);

	// Reset Level time
	DemoSpec->Level->TimeSeconds	= 0;
	ltsoffset = 0.0; // resync level.TimeSeconds

	GLog->Logf(TEXT("UDEMO: Done!"));
	unguard;
}

/*-----------------------------------------------------------------------------
	execSetSpeed - Set the playback speed. Doesn't work with no frame cap
-----------------------------------------------------------------------------*/
void UDemoInterface::execSetSpeed (FFrame& Stack, RESULT_DECL)
{
	guard (UDemoInterface::execSetSpeed);
	P_GET_FLOAT(newSpeed);
	P_FINISH;
	mySpeed = newSpeed;
	if (PlayBackMode != 2) //not in timebased!
		DemoSpec->Level->TimeDilation=newSpeed*(DemoDriver->RealDilation); //ratios own!
	DemoDriver->Speed = newSpeed;
	unguard;
}

/*-----------------------------------------------------------------------------
	The End.
-----------------------------------------------------------------------------*/
