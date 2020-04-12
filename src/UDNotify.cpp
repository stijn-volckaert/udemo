/*=============================================================================
	UDNotify.cpp: Demo Reader. Handles Pendinglevel stuff

	Revision history:
		* Created by UsAaR33		
		* Anth: Cleaned up, made some cross-platform modifications
		* Anth: Linux FURL is borked. Added a hack for that...
=============================================================================*/

/*-----------------------------------------------------------------------------
	Includes/Definitions
-----------------------------------------------------------------------------*/
#include "udemoprivate.h"

/*-----------------------------------------------------------------------------
	UDemoPlayPendingLevel implementation.
-----------------------------------------------------------------------------*/
UDReader::UDReader( UEngine* InEngine, const FURL& InURL, Uudnative * Control )
:	ULevelBase( InEngine, InURL )
{
	guard(UDReader::UDReader);
	Controller=Control;

	// Try to create demo playback driver.
	UClass* DemoDriverClass = StaticLoadClass( UNetDriver::StaticClass(), NULL, TEXT("Engine.DemoRecDriver"), NULL, LOAD_NoFail, NULL );
	DemoRecDriver = ConstructObject<UNetDriver>( DemoDriverClass );
	if( !DemoRecDriver->InitConnect( this, URL, Error ) )
	{
		delete DemoRecDriver;
		DemoRecDriver = NULL;
	}

	unguard;
}

/*-----------------------------------------------------------------------------
	NotifyGetLevel - Not needed
-----------------------------------------------------------------------------*/
ULevel* UDReader::NotifyGetLevel()
{
	guard(UDReader::NotifyGetLevel);
	return NULL;
	unguard;
}

/*-----------------------------------------------------------------------------
	getTime - Calculate time and frames in the demo
-----------------------------------------------------------------------------*/
void UDReader::getTime(double * time, int * frames)
{
	guard(UDReader::getTime);
	FArchive*FileAr;
	guard(FileArProcess);
	FileAr =  static_cast<UDemoRecDriver*>(DemoRecDriver)->FileAr;
	if (!FileAr)
	{
		GLog->Logf(TEXT("error.. FARCHIVE COULD NOT BE READ FROM DEMO!"));
		return;
	}
	unguard;
	//DOUBLE oldtime;
	FTime ftime;
	int seekTo;
	DWORD PacketBytes; 
	while (!FileAr->AtEnd() && !FileAr->IsError() ){  //loop until done
		*FileAr << *frames;
		if (FileAr->AtEnd() || FileAr->IsError())
			break;
		*FileAr << ftime;
		//GLog->Logf(TEXT("time is %f"),ftime.GetFloat());
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
	*time=ftime.GetFloat();	
	
	unguard;
}

/*-----------------------------------------------------------------------------
	NotifyReceivedText - Needed for packagelist
-----------------------------------------------------------------------------*/
void UDReader::NotifyReceivedText( UNetConnection* Connection, const TCHAR* Text )
{
	guard(UDPlayPendingLevel::NotifyReceivedText);

	//GLog->Logf(TEXT("Received Text: %s from Connection %s"),Text,Connection->GetFullName());

	if( ParseCommand( &Text, TEXT("USES") ) )
	{
		// Dependency information.
		TCHAR Filename[256];
		int FileSize;
		TCHAR PackageName[NAME_SIZE]=TEXT("");
		FString FName;
		FGuid Guid;
		int Gen;
		Parse( Text, TEXT("GUID="), Guid );
		Parse( Text, TEXT("SIZE="), FileSize );
		Parse( Text, TEXT("PKG="), PackageName, ARRAY_COUNT(PackageName) );
		Parse( Text, TEXT("FNAME="), FName);
		Parse( Text, TEXT("GEN="), Gen);
		UBOOL Installed=appFindPackageFile( PackageName, &Guid, Filename );
		if (FName==TEXT("")||FName.Right(4)==TEXT(".uxx")) //old version or cache file
			FName=(TEXT("%s"),PackageName);	
		Controller->eventPackageRequired(FName,FileSize,Installed,Guid,Gen,appStrstr(Filename,TEXT(".uxx"))!=NULL);
		//note: filename out returns file path!  if it is in cache, there is no .uxx at end and gives Guid!
	}
	
	//Kill:
	else if( ParseCommand( &Text, TEXT("WELCOME") ) )
	{
		FURL URL;
	
		// Parse welcome message.
		Parse( Text, TEXT("LEVEL="), URL.Map );
		FString ServerDemo;
		int frames=0;
		double time=0.0;
		getTime(&time,&frames);
		Controller->eventDemoReadDone(URL.Map,Parse( Text, TEXT("SERVERDEMO"), ServerDemo),time,frames );
		guard(Closing);
		DemoRecDriver->LowLevelDestroy();
		DemoRecDriver->Notify=NULL;
		DemoRecDriver=NULL;
		Controller->DemoDriver=NULL;
		delete this;
		unguard;
	}
	unguard;
}

/*-----------------------------------------------------------------------------
	Destroy - Kill the demo driver
-----------------------------------------------------------------------------*/
void UDReader::Destroy()
{
	Controller->DemoDriver=NULL;
	Super::Destroy();
}

/*-----------------------------------------------------------------------------
	The End.
-----------------------------------------------------------------------------*/
