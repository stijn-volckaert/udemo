/*=============================================================================
	udnative.cpp: All of the demo file management stuff is here! Listing demos,
	deleting, renaming, ...

	Revision history:
		* Created by UsAaR33		
		* Anth: Cleaned up
		* Anth: No longer uses win32 api for anything. (06/2009)
		This should make Linux porting much easier
		* Anth: More Linux FURL hacks
		* Anth: Added linux basepath method (appBasepath broken)
=============================================================================*/

/*-----------------------------------------------------------------------------
	Includes/Definitions
-----------------------------------------------------------------------------*/
#include "udemoprivate.h"
#ifndef WIN32
#include <sys/stat.h>
#include <sys/types.h>
#include "FFileManagerLinux.h"
#endif

#include <time.h>

/*-----------------------------------------------------------------------------
	Global vars
-----------------------------------------------------------------------------*/
TArray<FString> FileList; // File list containing demo names
FString FilePath;         // Path from which the list was retrieved
INT ListPos;              // Pos of the last demo returned from this list

/*-----------------------------------------------------------------------------
	execDemoActive - Get the current demo status
-----------------------------------------------------------------------------*/
void Uudnative::execDemoActive (FFrame& Stack, RESULT_DECL)
{ 
	guard (Uudnative::execDemoActive); 
	P_GET_OBJECT(ULevel,mylevel); //xlevel
	P_FINISH;
	if (mylevel==NULL||mylevel->DemoRecDriver==NULL)
		*(BYTE*)Result=0;
	else if (!mylevel->DemoRecDriver->ServerConnection) //no server connection = recording.
		*(BYTE*)Result=1;
	else
		*(BYTE*)Result=2;	
	unguard;
}

/*-----------------------------------------------------------------------------
	execRename - Rename a demo or a file
-----------------------------------------------------------------------------*/
void Uudnative::execRename (FFrame& Stack, RESULT_DECL)
{ 
	guard (Uudnative::execRename); 
	P_GET_STR(myfile);
	P_GET_STR(mynewfile);
	P_FINISH;
	if (DemoDriver)
	{
		DemoDriver->LowLevelDestroy();
		UDReader * Reader=(UDReader*)DemoDriver->Notify;
		Reader->Destroy();
	}	
	UBOOL Success = GFileManager->Move( *mynewfile, *myfile, true, true, true );
	GLog->Logf(TEXT("Rename: %s -> %s - Success: %d"),*myfile,*mynewfile,Success);
	if (Success==1)
		*(UBOOL*)Result=1; 
	unguard;
}

/*-----------------------------------------------------------------------------
	execkill - Delete a demo
-----------------------------------------------------------------------------*/
void Uudnative::execkill (FFrame& Stack, RESULT_DECL)
{ 
	guard (Uudnative::execkill); 
	P_GET_STR(myfile);
	P_FINISH;
	
	if (DemoDriver)
	{ 
		DemoDriver->LowLevelDestroy();
		UDReader * Reader=(UDReader*)DemoDriver->Notify;
		Reader->Destroy();
	}
	// fix name
	INT i = myfile.Caps().InStr(TEXT(".DEM"));
	if( i != -1)
		myfile = myfile.Left(i);
	myfile += TEXT(".dem");
	// Delete if exists
	UBOOL Success = GFileManager->Delete( *myfile, false, true );
	if (Success)
	{
		GLog->Logf(TEXT("Deleted file: %s"),*myfile);
		*(UBOOL*)Result = 1;
	}
	else
	{
		GLog->Logf(TEXT("Couldn't delete: %s"),*myfile);
		*(UBOOL*)Result = 0;
	}
	unguard;
}

/*-----------------------------------------------------------------------------
	execBasePath - Get the base directory
-----------------------------------------------------------------------------*/
void Uudnative::execBasePath (FFrame& Stack, RESULT_DECL)
{ 
	guard (Uudnative::execBasePath); 
	P_FINISH;
#if !__LINUX_X86__ && !MACOSX
	*(FString*)Result = appBaseDir();
#else
	FFileManagerLinux* FileMan = dynamic_cast<FFileManagerLinux*>(GFileManager);
	if (FileMan && FileMan->BaseDir.Len() > 0)
	{
		*(FString*)Result = FileMan->BaseDir;
	}
	else
	{
		char cCurrentPath[FILENAME_MAX];
		if (getcwd(cCurrentPath, sizeof(cCurrentPath)))
			*(FString*)Result = ANSI_TO_TCHAR(cCurrentPath);
	}
#endif
	unguard;
}

/*-----------------------------------------------------------------------------
	execgetdemo - Get the list of demos in this directory
-----------------------------------------------------------------------------*/
void Uudnative::execgetdemo (FFrame& Stack, RESULT_DECL)
{ 
	guard (Uudnative::execgetdemo);  
	P_GET_STR(path); 
    P_FINISH;
 	
	// If refresh => Get new list
	if (path!=TEXT(""))
	{ 
		FilePath = path;
		path+=TEXT("*.dem");		
		FileList = GFileManager->FindFiles( *path, true, false );
		ListPos = 0;
	}

	// Safe to return
	if (FileList.Num() > ListPos)
	{
		FString Filename = FilePath + FileList(ListPos);
		INT FileSize = GFileManager->FileSize(*Filename);
		SQWORD FileTime = GFileManager->GetGlobalTime(*Filename);
		FString FileDate;
		
		time_t ltime = FileTime != ~0 ? FileTime : time(NULL);
		char DateTime[100] = {0};
		struct tm *tmp;
		tmp = localtime(&ltime);
		if (tmp && strftime(DateTime, sizeof(DateTime), "%Y-%m-%d %H:%M:%S", tmp) != 0)
			FileDate = DateTime;
		else
			FileDate = FString::Printf(TEXT("%010llu"), FileTime);

		*(FString*)Result = FString::Printf(TEXT("%ls/%u/%ls"), *FileList(ListPos), (FileSize+512)/1024, *FileDate);
		ListPos++;
	}
	else
	{
		*(FString*)Result = FString::Printf(TEXT(""));
		GLog->Logf(TEXT("UDEMO: Successfully got list of demos"));
	}
	unguard;
}

/*-----------------------------------------------------------------------------
	execDemoRead - Created new Demo Driver etc!
-----------------------------------------------------------------------------*/
void Uudnative::execDemoRead (FFrame& Stack, RESULT_DECL)
{ 
	guard (Uudnative::execDemoRead);  
	UDReader * Reader;
	P_GET_STR(myfile);
	P_GET_OBJECT(ULevel,mylevel); //xlevel
	P_FINISH;

	UGameEngine* GameEngine = CastChecked<UGameEngine>( mylevel->Engine );
	FURL BaseURL;
	if (GameEngine)
		BaseURL = GameEngine->LastURL;
	else
		BaseURL.LoadURLConfig( TEXT("DefaultPlayer"), TEXT("User") );

	FURL URL(&BaseURL, *myfile, TRAVEL_Absolute);
	URL.Map += TEXT(".dem");		
	debugf( TEXT("Opening demo driver to read demo file '%s'"), *URL.Map );
	
	if (DemoDriver)
	{
		DemoDriver->LowLevelDestroy();
		Reader=(UDReader*)DemoDriver->Notify;
		Reader->Destroy();

	}
	Reader= new UDReader( CastChecked<UGameEngine>( mylevel->Engine ), URL, this);

	if( !Reader->DemoRecDriver)
	{
		GWarn->Logf( TEXT("Failed to read demo: %s"), *(URL.Map) );
		delete Reader;
	}
	else
		DemoDriver=(UDemoRecDriver*) Reader->DemoRecDriver;
	unguard;

}

/*-----------------------------------------------------------------------------
	execDispatchTick - Tick the serverconnection
-----------------------------------------------------------------------------*/
void Uudnative::execDispatchTick (FFrame& Stack, RESULT_DECL)
{ 
	guard (Uudnative::execDispatchTick);
	P_GET_FLOAT(DeltaTime);
	P_FINISH;

	if (DemoDriver)
	{
		UNetConnection*	ServerConnection=DemoDriver->ServerConnection;
		DemoDriver->TickDispatch( DeltaTime );
		if (DemoDriver)
			DemoDriver->TickFlush();
		else if (ServerConnection)
			ServerConnection->State = USOCK_Closed;	
	}
	unguard;
}

/*-----------------------------------------------------------------------------
	execGUIDString - Converts a GUID to an FString
-----------------------------------------------------------------------------*/
void Uudnative::execGUIDString (FFrame& Stack, RESULT_DECL)
{ 
	guard (Uudnative::execGUIDString);
	P_GET_STRUCT(FGuid,inGUID);
	P_FINISH;
	*(FString*)Result = inGUID.String();
	unguard;
}

/*-----------------------------------------------------------------------------
	execWriteDemoInfo - Write a demo summary to a file
-----------------------------------------------------------------------------*/
void Uudnative::execWriteDemoInfo (FFrame& Stack, RESULT_DECL)
{ 
	guard (Uudnative::execWriteDemoInfo); 
	P_GET_STR(DemoFilename);
	P_GET_STR(Contents);
	P_FINISH;
	DemoFilename+=TEXT("Info.TXT");
	if (appSaveStringToFile(Contents,*DemoFilename,GFileManager))
	{
		GLog->Logf(TEXT("Sucessfully wrote to '%s'"), *DemoFilename );
		*(UBOOL*)Result = 1;
	}
	else
		GLog->Logf(TEXT("Unknown error while writing to'%s'"), *DemoFilename );

	unguard;
}

/*-----------------------------------------------------------------------------
	execIsMismatch - Check if the file matches the GUID and the generations
-----------------------------------------------------------------------------*/
void Uudnative::execIsMismatch (FFrame& Stack, RESULT_DECL)
{ 
	guard (Uudnative::execIsMismatch); 
	P_GET_STR(FileName);
	P_GET_STRUCT(FGuid,PackageGUID); //guid
	P_GET_INT(Gen);
	P_FINISH;	
	
	// Null filename => should never happen
	if (FileName==TEXT(""))
	{ 
		*(BYTE*)Result=0;
		return;
	}
	
	BeginLoad(); 	
	ULinkerLoad* Linker = GetPackageLinker( NULL, *FileName, LOAD_None, NULL, &PackageGUID); //load with GUID!
	// No linker => file not present or access denied?
	if (!Linker)
	{ 
		*(BYTE*)Result=3;
		EndLoad();
		return;
	}
	// GUID mismatch => happens quite frequently
	else if ((Linker->Summary.Guid) != PackageGUID) //mismatch!
		*(BYTE*)Result=2;
	// Generations mismatch => recompiled but conformed files?
	else
	{
		TArray<FGenerationInfo>* Generations = &Linker->Summary.Generations;

		if (Generations->Num() < Gen)
		{
			GLog->Logf(TEXT("udemo: %s have generation error! desired: %d actual: %d"), *FileName, Gen, Generations->Num());
			*(BYTE*)Result = 1;
		}
		// Seems ok
		else
			*(BYTE*)Result = 0;
	}
	
	EndLoad();
	unguard;
}

/*-----------------------------------------------------------------------------
	execSetDemoDriverClass - Set non-empty value into [Engine.Engine] DemoRecordingDevice and return current value
-----------------------------------------------------------------------------*/
void Uudnative::execSetDemoDriverClass(FFrame& Stack, RESULT_DECL)
{ 
	guard (Uudnative::execSetDemoDriverClass); 
	P_GET_STR(ClassName);
	P_FINISH;	
	
	if (ClassName != TEXT(""))
		GConfig->SetString(TEXT("Engine.Engine"), TEXT("DemoRecordingDevice"), *ClassName);
	GConfig->GetString(TEXT("Engine.Engine"), TEXT("DemoRecordingDevice"), ClassName);
	*(FString*)Result = ClassName;
	
	unguard;
}

/*-----------------------------------------------------------------------------
	execFindViewPort - get the main viewport
-----------------------------------------------------------------------------*/
void Uudnative::execFindViewPort (FFrame& Stack, RESULT_DECL)
{ 
	guard (Uudnative::execFindViewPort); 
	P_FINISH;	
	*(UPlayer**)Result = UTexture::__Client->Viewports(0); //thx mongo! (amazing this works)
	unguard;
}

/*-----------------------------------------------------------------------------
	execGetArray - Get HUD messages array
-----------------------------------------------------------------------------*/
void Uudnative::execGetArray (FFrame& Stack, RESULT_DECL)
{ 
	guard (Uudnative::execGetArray); 
	P_GET_OBJECT(AHUD,aChallengeHUD);
	P_GET_NAME(ArrayName);
	P_GET_BYTE(element);
	P_FINISH;
	const TCHAR *p=*ArrayName;
	UStructProperty* StructPropertyObject = (UStructProperty*)StaticFindObject(UStructProperty::StaticClass(),StaticFindObject(UClass::StaticClass(),ANY_PACKAGE,TEXT("ChallengeHUD")),p);
	*(HUDLocalizedMessage*)Result = *(HUDLocalizedMessage*)( (BYTE*)aChallengeHUD + StructPropertyObject->Offset+element*(StructPropertyObject->ElementSize) );
	unguard;
}

/*-----------------------------------------------------------------------------
	The End.
-----------------------------------------------------------------------------*/
