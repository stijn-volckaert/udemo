/*=============================================================================
	UZHandler.cpp: Implementation of the demo manager file saver/decompressor

	Revision history:
		* Created by UsAaR33		
		* Anth: Total rewrite for better cross-platform and compiler support (06/2009)
=============================================================================*/

/*-----------------------------------------------------------------------------
	Includes/Definitions
-----------------------------------------------------------------------------*/
#include "udemoprivate.h"
IMPLEMENT_CLASS(UUZHandler);

/*-----------------------------------------------------------------------------
	execAppend - The files are downloaded using a uscript TcpLink class. Every
	file is received in chunks of 255 bytes. The 255 byte arrays are then pushed
	to this function and appended to a buffer
-----------------------------------------------------------------------------*/
void UUZHandler::execAppend (FFrame& Stack, RESULT_DECL)
{ 
	guard (UUZHandler::execAppend);
	P_GET_BYTE(Count);
	P_GET_ARRAY_REF(BYTE,B); //get byte array
	P_FINISH;		
	// Create FileWriter if needed
	if (!UzAr)
	{
		GLog->Logf(TEXT("Creating temporary file: udemouz.tmp"));
		UzAr = GFileManager->CreateFileWriter( TEXT("udemouz.tmp"), FILEWRITE_NoFail, GError );
	}	
	// Append
	((FArchive*)UzAr)->Serialize(B, Count);
	unguard;
}

/*-----------------------------------------------------------------------------
	FindDir - Find the path associated with this file extension
-----------------------------------------------------------------------------*/
const FString FindDir(const FString Filename)
{
	FString ext = Filename.Mid(Filename.InStr(TEXT("."),1));
	int i = 0;
	for (i=0;i<GSys->Paths.Num();i++)
	{
		if (GSys->Paths(i).Mid(GSys->Paths(i).InStr(TEXT("*"),1)+1) == ext)
			return (GSys->Paths(i).Left(GSys->Paths(i).InStr(TEXT("*")))); //return path
	}
	// Defaulted to system path
	return GSys->Paths(0).Left(GSys->Paths(i).InStr(TEXT("*")));
}

/*-----------------------------------------------------------------------------
	execSaveFile - Decompress the temporary file (the buffer to which all the
	chunks were appended) and then save it in the right folder
-----------------------------------------------------------------------------*/
void UUZHandler::execSaveFile (FFrame& Stack, RESULT_DECL)
{ 
	guard (UUZHandler::execSaveFile);
	P_GET_UBOOL(bCache);
	P_FINISH;	
	
	// Close temp file	
	delete ((FArchive*)UzAr);	

	// Reopen as file reader
	FArchive* Reader = GFileManager->CreateFileReader( TEXT("udemouz.tmp"), FILEREAD_NoFail, GError );

	// Check the file signature
	INT Signature;
	UBOOL NewVer = false;
    guard(UZSignatureTest);
	*Reader << Signature;   
	if (Signature == 5678)
		NewVer = true;
	else if (Signature != 1234)
	{ 
		*(BYTE*)Result=3; 
		GWarn->Logf(TEXT("Downloaded file has invalid signature: %i"),Signature);
		delete Reader; 
		return;
	}
	unguard;

	// Get the filename
	*Reader << Filename;
	GLog->Logf(TEXT("Beginning decompression sequence on '%s.uz'"),*Filename);
	FString Filepath = FindDir(Filename);	
	FString FilenameFull;
	FilenameFull = Filepath+Filename;
	GLog->Logf(TEXT("Target File: %s"),*FilenameFull);
	
	// Init the codec - Original codec broken in VC++ .NET
	FFCodecFull Codec; 
	Codec.AddCodec(new FFCodecRLE); 
	Codec.AddCodec(new FFCodecBWT); 
	Codec.AddCodec(new FFCodecMTF); 
	if( NewVer ) 
		Codec.AddCodec(new FFCodecRLE); 
	Codec.AddCodec(new FFCodecHuffman); 
  
	// Create filewriter for decompressed file and decompress
	guard(Decompress);
	if (bCache)
		UzDeCompAr = GFileManager->CreateFileWriter(TEXT("udemo.tmp"), FILEWRITE_NoFail, GError);
	else
		UzDeCompAr = GFileManager->CreateFileWriter( *FilenameFull, FILEWRITE_NoFail, GError );	
	Codec.Decode( *Reader, *(FArchive*)UzDeCompAr );
	delete (FArchive*)UzDeCompAr;
    delete Reader; 
	unguard;	

	// Delete temp file
	GLog->Logf(TEXT("Deleting temporary file: udemouz.tmp"));
	GFileManager->Delete( TEXT("udemouz.tmp"), true, true );
	
	// Now check the file integrity - reopen file for reading
	guard(PackageTests);
	// Ignore int files	
	if (Filename.Mid(Filename.InStr(TEXT("."),true)).Locs() == TEXT(".int"))
	{
		*(BYTE*)Result = 0;
		return;
	}

	// Not int file => must be upackage
	if (bCache)
		Reader = GFileManager->CreateFileReader(TEXT("udemo.tmp"), FILEREAD_NoFail, GError );
	else
		Reader = GFileManager->CreateFileReader(*FilenameFull, FILEREAD_NoFail, GError);
	
	// Check Tag
	INT Tag;
	*Reader << Tag;
	if (Tag != 0x9E2A83C1)
	{ 
		*(BYTE*)Result=3;
		GWarn->Logf(TEXT("Download file is NOT a valid UTPackage (has tag: %x)"),Tag);
		delete Reader;
		GFileManager->Delete( *FilenameFull, true, true );
		return;
	}

	// Check GUID
	Reader->Seek(36);
	FGuid dGuid;
	*Reader << dGuid;
	if (dGuid != FileGUID)
	{ 
		*(BYTE*)Result=2;
		GWarn->Logf(TEXT("Download file's GUID (%s) does not match goal GUID (%s)"),dGuid.String(),FileGUID.String());
		delete Reader;
		GFileManager->Delete( *FilenameFull, true, true );		
		return;
	}

	// Check Generations
	INT GenCount;
	*Reader << GenCount;
	if (GenCount < FileGen)
	{ 
		*(BYTE*)Result=1;
		GWarn->Logf(TEXT("Downloaded file has outdated generation (Goal: %i, downloaded: %i)"),FileGen,GenCount);
		delete Reader;
		return; //don't delete: user can "force save"
	}

	delete Reader;

	if (bCache)
	{
		FConfigCacheIni CacheIni;
		FString RealFileName = FString::Printf(TEXT("%s") PATH_SEPARATOR TEXT("%s.uxx"), *GSys->CachePath, dGuid.String());		
		FString IniName = FString::Printf( TEXT("%s") PATH_SEPARATOR TEXT("cache.ini"), *GSys->CachePath);
		CacheIni.SetString(TEXT("Cache"), dGuid.String(), *Filename, *IniName);

		GLog->Logf(TEXT("Moving udemo.tmp to %s"), *RealFileName);
		GFileManager->Move(*RealFileName, TEXT("udemo.tmp"), 1, 1);
	}

	unguard;
	*(BYTE*)Result = 0;
	unguard;
}

/*-----------------------------------------------------------------------------
	execForceSave - Removed in 3.3
-----------------------------------------------------------------------------*/
void UUZHandler::execForceSave (FFrame& Stack, RESULT_DECL)
{ 
	guard (UUZHandler::execForceSave);
	P_GET_UBOOL(bCache);
	P_FINISH;
	// Removed
	unguard
}

/*-----------------------------------------------------------------------------
	The End.
-----------------------------------------------------------------------------*/
