// =============================================================================
// UT Demo Manager v3.4
// Originally written by UsAaR33
// Project continued by AnthraX after v3.0
// =============================================================================
// udemo.udnative: By UsAaR33.  native class which allows the reader to get a list of demos and their sizes.
// also can delete demos and rename them, as well as a cool analysis :)
// Note, this was the first native class.  Now two otehrs exist in the udemo pacakge (as of ud 3.0).
// However, this is still the native class used by the actual manager windows.
// =============================================================================
class udnative expands Object
    native;

// =============================================================================
// Structures
// =============================================================================
//
//redefined here to make compiler happy!
//
struct HUDLocalizedMessage
{
    var Class<LocalMessage> Message;
    var int Switch;
    var PlayerReplicationInfo RelatedPRI;
    var Object OptionalObject;
    var float EndOfLife;
    var float LifeTime;
    var bool bDrawing;
    var int numLines;
    var string StringMessage;
    var color DrawColor;
    var font StringFont;
    var float XL, YL;
    var float YPos;
};

// =============================================================================
// Variables
// =============================================================================
var const DemoRecDriver DemoDriver; // valid when reading
var string DemoURL;                 // (Anth) Lame Linux FURL hack...

// =============================================================================
// File Functions
// =============================================================================
//
// returns a demo/size (oh and maybe date in future?) path is where to search (full or from base)
//
native final function string getdemo(string path);
//
// deletes a file (in this case a demo)
//
native final static function bool kill(string file);
//
// renames a file to a new name.
//
native final static function bool rename(string file, string newfile);
//
// returns the base directory the native is in.
//
native final static function string BasePath();
//
// writes DemoNameINFO.txt with contents. returns sucess.
//
native final static function bool WriteDemoInfo(string DemoName, string contents);

// =============================================================================
// Miscellaneous Functions
// =============================================================================
//
// hack for var size limits!
//
native final static function HUDLocalizedMessage GetArray(HUD aChallengeHUD, name ArrayName, byte Element);
//
// super hack: RETURNS THE VIEWPORT!
//
native final static function Player FindViewPort();
//
// checks ULevel's (aPawn->Xlevel) DemoRecDriver pointer. 0 if no, 1 if recording, 2 if playing
//
native final static function byte DemoActive(level Xlevel);
//
// converts GUID to string :)
//
native final static function string GUIDString(GUID a);
//
// checks if a given custom file has a non-desired GUID or gen. (gen fails if demos is > than file)
// 0=passed. 1=bad gen; 2=bad guid; 3=cannot load??? //add pkg size check?
// REMOVED: Currently FileSize is only set to the file's size
//
native static final function byte IsMismatch(string FileName, GUID desiredGUID, int desiredGen/*, out int FileSize*/);
//
// Set non-empty value into [Engine.Engine] DemoRecordingDevice and return current value
//
native final static function string SetDemoDriverClass(string DemoDriverClass);
//
// read demo information
//
native final function DemoRead(string file, level XLevel);
//
// must propogate ticks to object :)
//
native final function DispatchTick (float deltatime);
//
// a required package. Called while demo is being read
//
event PackageRequired (string package, int size, bool Installed, GUID myGUID, int gen, bool Cached);
//
// called when demo done being read.
//
event DemoReadDone (string Map, bool bServerDemo, float Time, int NumFrames);
