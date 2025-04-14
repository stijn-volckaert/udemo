/*=============================================================================
	udemoprivate.h: Demo manager private header

	Revision history:
		* Created by UsAaR33
		* Anth: Cross-platform update (19/06/2009)
=============================================================================*/

#ifndef _INC_UDEMO
#define _INC_UDEMO

/*-----------------------------------------------------------------------------
	Engine includes
-----------------------------------------------------------------------------*/
#include "Engine.h" 
#include "udemoClasses.h"
#include "UnNet.h" 
#include "UuDriver.h"
#include "UnLinker.h" 
#include "FConfigCacheIni.h"
#if !UNREAL_TOURNAMENT_UTPG
#include "UDCodecs.h"
#endif

/*-----------------------------------------------------------------------------
	HUDLocalizedMessage - Redefined because of some compiler problems
-----------------------------------------------------------------------------*/
struct HUDLocalizedMessage
{
	class UClass* Message;
	INT Switch;
	class APlayerReplicationInfo* RelatedPRI;
	class UObject* OptionalObject;
	FLOAT EndOfLife;
	FLOAT LifeTime;
	BITFIELD bDrawing:1 GCC_PACK(4);
	INT NumLines;
	FStringNoInit StringMessage;
	FColor DrawColor;
	class UFont* StringFont;
	FLOAT XL;
	FLOAT YL;
	FLOAT YPos;
};

/*-----------------------------------------------------------------------------
	UDReader - Handles all the Pending Level stuff!
-----------------------------------------------------------------------------*/
class UDEMO_API UDReader : public ULevelBase
{
	DECLARE_CLASS(UDReader,ULevelBase,0,udemo)
	NO_DEFAULT_CONSTRUCTOR(UDReader)
    Uudnative * Controller;
	FString		Error;
	
	// Constructors.
	UDReader( UEngine* InEngine, const FURL& InURL,Uudnative * Control);

	// FNetworkNotify interface.
	EAcceptConnection NotifyAcceptingConnection() { return ACCEPTC_Reject; }
	void NotifyAcceptedConnection( class UNetConnection* Connection ) {}
	UBOOL NotifyAcceptingChannel(class UChannel* Channel) { return 1; }
	ULevel* NotifyGetLevel();
	void NotifyReceivedText( UNetConnection* Connection, const TCHAR* Text );
	void NotifyReceivedFile( UNetConnection* Connection, INT PackageIndex, const TCHAR* Error, UBOOL Skipped ) {}
	UBOOL NotifySendingFile( UNetConnection* Connection, FGuid GUID ) {return 0;}
	void Destroy();

	// Custom functions
	void getTime(double * time, int * frames);
};

class UuDemoDriver;
class UDemoRecConnection;

#define LTS_OFFSET 1000.0F

/*-----------------------------------------------------------------------------
	UuDemoDriver - Advanced Demo Driver, supports speed toggling etc	
-----------------------------------------------------------------------------*/
class UDEMO_API UuDemoDriver : public UDemoRecDriver
{
	DECLARE_CLASS(UuDemoDriver,UDemoRecDriver,CLASS_Transient|CLASS_Config,udemo)
	//new vars:
	UBOOL	MessagePlay;   	       // if true, tick 4ever!
	UDemoInterface* Interface;     // uscript interface pointer
	float Speed;
	UBOOL Paused;                  // true if demo client has paused demo!
	FTime StartTime;               // time when player joined?
	FTime TotalTime;               // total time in demo.  		
	FTime GameTime;				   // helper for calculate game time.
	int TotalFrames;               // total frames in demo
	float RealDilation;            // the real time dilation!
	INT ServerFrameNum;            // demo frame #
	FTime ServerPacketTime;        // demo time
	void StaticConstructor();
	UBOOL bNoTick;
	UBOOL Want3rdP;
	APlayerPawn* SoundPlayer;      // must make this guy have a viewport!
	UBOOL ClientHandled;           // if client already handled!
	UBOOL Seeking;					// ignore bNetTemporary actors when seeking
	DOUBLE AccumulatedTime;
	UuDemoDriver();

	// FExec interface.
	INT Exec( const TCHAR* Cmd, FOutputDevice& Ar=*GLog );
	
	//custom tick to support time control
	void TickDispatch( FLOAT DeltaTime );
	FTime ReadTo(FTime GoalTime, UBOOL bPacketRead = true); //read demo x ammount
	void getTime();                // um.. just something to get the time!
	ULevel* GetLevel();            // the assertion pissed me off
	
	// (Anth) Semi-working attempt to sync level.timeseconds properly...
	void TimeSync(FTime NewTime, FTime OldTime);

	//custom init connect for more options!
	UBOOL InitConnect( FNetworkNotify* InNotify, FURL& ConnectURL, FString& Error );
	
	// (Anth) Spawnnotification-like routine for destroying UTDC etc...
	void CheckActors();

	// Seeking hax
	void UuReceivedRawPacket(void* Data, INT Count);
	void UuReceivedPacket(FBitReader& Reader);
};

/*-----------------------------------------------------------------------------
	UuDemoRecPackageMap. - Overrides the packagemap so we can record in 
	v436 format
-----------------------------------------------------------------------------*/
class UDEMO_API UuDemoPackageMap : public UPackageMapLevel
{
	DECLARE_CLASS(UuDemoPackageMap, UPackageMapLevel, CLASS_Config | CLASS_Transient, udemo)

	void Compute();
	INT LookupDemoGeneration(FPackageInfo& PackageInfo);

	UuDemoPackageMap()
	{}
	UuDemoPackageMap(UNetConnection* InConnection)
		: UPackageMapLevel(InConnection)
	{}
};

/*-----------------------------------------------------------------------------
	UuDemoRecConnection. - Does little more than a different HandleClientPlayer()
	Also spawns the demo interface for the player.
-----------------------------------------------------------------------------*/
class UDEMO_API UuDemoConnection : public UDemoRecConnection
{
	DECLARE_CLASS(UuDemoConnection,UDemoRecConnection,CLASS_Config|CLASS_Transient,udemo)
	NO_DEFAULT_CONSTRUCTOR(UuDemoConnection)

	DWORD dwPadding[20];			// (Anth) Compensation for mismatches between v436/440/451 definitions of UNetConnection

	UuDemoConnection(UNetDriver* InDriver, FURL& InURL);
	UuDemoDriver* GetDemoDriver(); //convenience function
	void HandleClientPlayer( APlayerPawn* Pawn );	
};

/*-----------------------------------------------------------------------------
	UStubPlayer - Stub UPlayer for use in LinkedPlayer for make some mods works properly	
-----------------------------------------------------------------------------*/
class UDEMO_API UStubPlayer : public UPlayer
{
	DECLARE_CLASS(UStubPlayer, UPlayer, CLASS_Transient, udemo)

	UPlayer* Proxy;
	UDemoInterface* Interface;

	UStubPlayer(): Proxy(NULL), Interface(NULL) {}

	UStubPlayer(UPlayer* InProxy, UDemoInterface* InInterface):
		Proxy(InProxy),
		Interface(InInterface)
	{
		guard(UStubPlayer::UStubPlayer);
		CopyFromProxy();
		unguard;
	}

	void CopyFromProxy()
	{
		guard(UStubPlayer::CopyFromProxy);
		if (!Proxy)
			return;
		Console = Proxy->Console;
		bWindowsMouseAvailable = Proxy->bWindowsMouseAvailable;
		bShowWindowsMouse = Proxy->bShowWindowsMouse;
		bSuspendPrecaching = Proxy->bSuspendPrecaching;
		WindowsMouseX = Proxy->WindowsMouseX;
		WindowsMouseY = Proxy->WindowsMouseY;
		CurrentNetSpeed = Proxy->CurrentNetSpeed;
		ConfiguredInternetSpeed = Proxy->ConfiguredInternetSpeed;
		ConfiguredLanSpeed = Proxy->ConfiguredLanSpeed;
		SelectedCursor = Proxy->SelectedCursor;
		unguard;
	}

	// FArchive interface.
	void Serialize( const TCHAR* Data, EName MsgType ){}
	
	// UPlayer interface.
	void ReadInput( FLOAT DeltaSeconds )
	{
		guard(UStubPlayer::ReadInput);
		CopyFromProxy();

		// apply smooth movement via perform physics as prediction
		if (Interface && Interface->SmoothRecorderMovement != Smooth_None && 
			DeltaSeconds > 0 && Actor && Actor->Role == ROLE_AutonomousProxy && Actor->Physics != PHYS_None &&
			//HIWORD(GetKeyState(VK_SHIFT)) && // dbg: apply only when hold SHIFT
			Actor->Level && Actor->Level->Pauser == TEXT("") && // ignore pause
			// detect if we need apply it in first person view
			(Interface->SmoothRecorderMovement == Smooth_All || !Proxy || !Proxy->Actor || Proxy->Actor->ViewTarget != Actor || Proxy->Actor->bBehindView))
		{
			Actor->Role = ROLE_DumbProxy; // hack for avoid call scripts events, produce unwanted sounds and so on
			const UBOOL bCollideWorld = Actor->bCollideWorld;
			Actor->bCollideWorld = TRUE; // avoid prediction goes inside level geometry
			const BYTE Physics = Actor->Physics;
			if (Actor->Velocity.Z != 0 && Actor->Physics == PHYS_Walking) // PHYS_Walking ALWAYS mean Velocity.Z == 0
				Actor->Physics = PHYS_Falling;
			AActor* Base = Actor->Base;
			// hack for avoid prediction fall from ledges
			const UBOOL bCanJump = Actor->bCanJump;
			Actor->bCanJump = FALSE;
			const UBOOL bAvoidLedges = Actor->bAvoidLedges;
			Actor->bAvoidLedges = TRUE;
			const UBOOL bStopAtLedges = Actor->bStopAtLedges;
			Actor->bStopAtLedges = TRUE;
			const UBOOL bIsWalking = Actor->bIsWalking;
			Actor->bIsWalking = TRUE;

			Actor->performPhysics(DeltaSeconds);

			Actor->Role = ROLE_AutonomousProxy;
			Actor->bCollideWorld = bCollideWorld;
			Actor->Physics = Physics; // direct assign for avoid call setbase 
			Actor->Base = Base; // direct assign for avoid call events
			Actor->bCanJump = bCanJump;
			Actor->bAvoidLedges = bAvoidLedges;
			Actor->bStopAtLedges = bStopAtLedges;
			Actor->bIsWalking = bIsWalking;
		}
		unguard;
	}

	void Destroy()
	{
		guard(UStubPlayer::Destroy);
		if (Actor)
		{
			Actor->Player = NULL;
			Actor = NULL;
		}
		Super::Destroy();
		unguard;
	}
};

/*-----------------------------------------------------------------------------
    Static Linking Support
-----------------------------------------------------------------------------*/

#if __STATIC_LINK
#define NAMES_ONLY
#define NATIVE_DEFS_ONLY
#define AUTOGENERATE_NAME(a)
#define AUTOGENERATE_FUNCTION(a,b,c)
#include "udemoClasses.h"
#undef NAMES_ONLY
#undef NATIVE_DEFS_ONLY
#undef AUTOGENERATE_NAME
#undef AUTOGENERATE_FUNCTION
#endif

#endif
