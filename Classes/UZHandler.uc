// =============================================================================
// UT Demo Manager v3.4
// Originally written by UsAaR33
// Project continued by AnthraX after v3.0
// =============================================================================
class UZHandler expands Object
    native;

// =============================================================================
// Variables
// =============================================================================
var const int UzAr;        // C++ FArchive*. (as downloading)
var const int UzDeCompAr;  // C++ FArchive*. (decompressed)
var const string FileName; // temporary during decompress cycle
var GUID FileGUID;         // required file's GUID!
var int FileGen;           // required file's generation   Note: if -1, then ignore guid/gen checks (int file)

// =============================================================================
// Native Functions
// =============================================================================
//
// append a byte array to the UzAr.
//
native final function Append (byte count, byte B[255]);
//
// try to save a file either in cache or in the main paths.
// if cache is true, will move any file already found!  (guid updates)
// if false, will simply overwrite the current filename! (generation update)
// error codes returned:
// 0: Successful
// 1: generation older than demo (warning only)
// 2: GUID mismatch
// 3: unknown saving error
//
native final function int SaveFile (bool bInCache);
//
// force save if gen mismatch
//
native final function ForceSave(bool bInCache);
