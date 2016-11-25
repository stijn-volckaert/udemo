// =============================================================================
// UT Demo Manager v3.4
// Originally written by UsAaR33
// Project continued by AnthraX after v3.0
// =============================================================================
// udemo.UDemoScreenshotCW: Custom screenshot window to display information even when no screenshot.
// =============================================================================
class UDemoScreenshotCW expands UMenuScreenshotCW;

// =============================================================================
// SetUDMap ~
// =============================================================================
function SetUDMap(string mapname, bool bServerDemo, int NumFrames, float PlayTime)
{
    SetMap(MapName);

    if (DemoMainClientWindow(GetParent(class'DemoMainClientWindow')).Packages.FindPackage(mapname).binstalled==0)
        MapTitle="Warning: Cannot play demo:"@mapname@"not found!";
    else
        MapTitle="Playing on"@mapname;

    MapAuthor="Play Time:"@class'DemoSettings'.static.ParseTime(PlayTime)$","@NumFrames@"Frames (Avg. FPS:"@class'demosettings'.static.FloatString(NumFrames/PlayTime)$")";

    if (bServerDemo)
        IdealPlayerCount="Recorded on a dedicated server (server-side)";
    else
        IdealPlayerCount="Recorded through a player (client-side)";

    DemoMainClientWindow(GetParent(class'DemoMainClientWindow')).Packages.FindPackage(mapname).bpbishows=true;
}

// =============================================================================
// SetPending ~
// =============================================================================
function SetPending()
{
    Screenshot=none;
    MapTitle="Please wait...";
    MapAuthor="";
    IdealPlayerCount="Reading information from demo file.";
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
        Y = WinHeight - H*2;
        ClipText(C, X, Y, IdealPlayerCount);
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

// =============================================================================
// defaultproperties
// =============================================================================
defaultproperties
{
}