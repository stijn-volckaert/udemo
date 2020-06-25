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

#if __STATIC_LINK
void InitUdemo();
#endif

#endif
