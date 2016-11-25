/*=============================================================================
	udemoprivate.h: Demo manager private header

	Revision history:
		* Created by UsAaR33
		* Anth: Cross-platform update (19/06/2009)
=============================================================================*/

#ifndef _INC_UDEMO
#define _INC_UDEMO

/*-----------------------------------------------------------------------------
	Import/Export definitions - not needed for linux
-----------------------------------------------------------------------------*/
#ifndef __LINUX_X86__
	#define CORE_API DLL_IMPORT
	#define UDEMO_API DLL_EXPORT
	typedef char CHAR;
#else
	#include <unistd.h>	
#endif

/*-----------------------------------------------------------------------------
	Engine includes
-----------------------------------------------------------------------------*/
#include "Engine.h" 
#include "udemoClasses.h"
#include "UnNet.h" 
#include "UuDriver.h"
#include "UnLinker.h" 
#include "FConfigCacheIni.h"
#include "UDCodecs.h"

/*-----------------------------------------------------------------------------
	(Anth) Lame GCC-2.95 fix :(
-----------------------------------------------------------------------------*/
#ifdef __LINUX_X86__
	#undef CPP_PROPERTY
	#define CPP_PROPERTY(name) \
		EC_CppProperty, (BYTE*)&((ThisClass*)1)->name - (BYTE*)1
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
	UBOOL NotifyAcceptingChannel( class UChannel* Channel ) { return 1; }
	ULevel* NotifyGetLevel();
	void NotifyReceivedText( UNetConnection* Connection, const TCHAR* Text );
	void NotifyReceivedFile( UNetConnection* Connection, INT PackageIndex, const TCHAR* Error, UBOOL Skipped ) {}
	UBOOL NotifySendingFile( UNetConnection* Connection, FGuid GUID ) {return 0;}
	void Destroy();

	// Custom functions
	void getTime(double * time, int * frames);
};

#endif
