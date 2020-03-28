/*=============================================================================
	UuDriver.h: Definitions of the UuDemoDriver

	Revision history:
		* Created by UsAaR33		
		* Anth: Added CheckActors function in UuDemoDriver
=============================================================================*/

class UuDemoDriver;
class UDemoRecConnection;

/*-----------------------------------------------------------------------------
	UuDemoDriver - Advanced Demo Driver, supports speed toggling etc	
-----------------------------------------------------------------------------*/
class UuDemoDriver : public UDemoRecDriver
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
	UBOOL CompatDemos;
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