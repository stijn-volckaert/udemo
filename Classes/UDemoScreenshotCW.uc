// =============================================================================
// UT Demo Manager v3.4
// Originally written by UsAaR33
// Project continued by AnthraX after v3.0
// =============================================================================
// udemo.UDemoScreenshotCW: Custom screenshot window to display information even when no screenshot.
// =============================================================================
class UDemoScreenshotCW expands UMenuScreenshotCW;

var localized string LocCannotPlayDemoPrefix;
var localized string LocCannotPlayDemoSuffix;
var localized string LocPlayingOn;
var localized string LocPlayTime;
var localized string LocRecordedOnADedicatedServer;
var localized string LocRecordedThroughAPlayer;
var localized string LocPleaseWait;
var localized string LocReadingInformationFromDemoFile;

var string MapAuthor2;

// =============================================================================
// SetUDMap ~
// =============================================================================
function SetUDMap(string mapname, bool bServerDemo, int NumFrames, float PlayTime)
{
	SetMap(MapName);

	if (DemoMainClientWindow(GetParent(class'DemoMainClientWindow')).Packages.FindPackage(mapname).binstalled==0)
		MapTitle=LocCannotPlayDemoPrefix@" "@mapname@" "@LocCannotPlayDemoSuffix;
	else
		MapTitle=LocPlayingOn@" "@mapname;

	MapAuthor=LocPlayTime@" "@class'DemoSettings'.static.ParseTime(PlayTime)$","@NumFrames@"Frames";
	MapAuthor2 = "(Avg. FPS:"@class'demosettings'.static.FloatString(NumFrames/PlayTime)$")";

	if (bServerDemo)
		IdealPlayerCount=LocRecordedOnADedicatedServer;
	else
		IdealPlayerCount=LocRecordedThroughAPlayer;

	DemoMainClientWindow(GetParent(class'DemoMainClientWindow')).Packages.FindPackage(mapname).bpbishows=true;
}

// =============================================================================
// SetPending ~
// =============================================================================
function SetPending()
{
	Screenshot=none;
	MapTitle=LocPleaseWait;
	MapAuthor="";
	IdealPlayerCount=LocReadingInformationFromDemoFile;
}

// =============================================================================
// Paint ~ for writing with no screenshot and no playerstext stuff.
// =============================================================================
function Paint(Canvas C, float MouseX, float MouseY)
{
	local float X, Y, W, H;

	DrawStretchedTexture(C, 0, 0, WinWidth, WinHeight, Texture'BlackTexture');
	C.Font=root.fonts[F_Normal];

	if(Screenshot != None)
	{
		W = Min(WinWidth, Screenshot.USize);
		H = Min(WinHeight, Screenshot.VSize);

		if(W > H)
			W = H;
		if(H > W)
			H = W;

		X = (WinWidth - W) / 2;
		Y = (WinHeight - H) / 2;

		C.DrawColor.R = 255;
		C.DrawColor.G = 255;
		C.DrawColor.B = 255;

		DrawStretchedTexture(C, X, Y, W, H, Screenshot);

		C.Font = Root.Fonts[F_Normal];
	}

	if(IdealPlayerCount != "")
	{
		TextSize(C, IdealPlayerCount, W, H);
		X = (WinWidth - W) / 2;
		Y = WinHeight - H*1;
		ClipText(C, X, Y, IdealPlayerCount);
	}
	
	if (MapAuthor2 != "")
	{
		TextSize(C, MapAuthor2, W, H);
		X = (WinWidth - W) / 2;
		Y = WinHeight - H*2;
		ClipText(C, X, Y, MapAuthor2);
	}

	if(MapAuthor != "")
	{
		TextSize(C, MapAuthor, W, H);
		X = (WinWidth - W) / 2;
		Y = WinHeight - H*3;
		ClipText(C, X, Y, MapAuthor);
	}

	if(MapTitle != "")
	{
		TextSize(C, MapTitle, W, H);
		X = (WinWidth - W) / 2;
		Y = WinHeight - H*4;
		ClipText(C, X, Y, MapTitle);
	}
}

defaultproperties
{
	LocCannotPlayDemoPrefix="Warning: Cannot play demo:"
	LocCannotPlayDemoSuffix="not found!"
	LocPlayingOn="Playing on"
	LocPlayTime="Play Time:"
	LocRecordedOnADedicatedServer="Recorded on a dedicated server (server-side)"
	LocRecordedThroughAPlayer="Recorded through a player (client-side)"
	LocPleaseWait="Please wait..."
	LocReadingInformationFromDemoFile="Reading information from demo file."
}
