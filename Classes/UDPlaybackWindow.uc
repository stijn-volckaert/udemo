// =============================================================================
// UT Demo Manager v3.4
// Originally written by UsAaR33
// Project continued by AnthraX after v3.0
// =============================================================================
// udemo.UDPlaybackWindow: floating playback panel, opened with the "DemoPanel"
// console command during demo playback. It stays on screen while the demo keeps
// running, just like the speech binder window does.
// =============================================================================
class UDPlaybackWindow expands UWindowFramedWindow;

var localized string LocNoUWindow;
var bool bPlaced;               // position checked against the screen size once

const DefaultWidth  = 470;
const DefaultHeight = 226;

// =============================================================================
// Toggle ~ Show the panel, or close it when it is already up
// =============================================================================
static function Toggle(PlayerPawn P)
{
	local WindowConsole C;
	local UDPlaybackWindow W;
	local float X, Y, NewWidth, NewHeight;

	if (P.Player == None)
		return;

	C = WindowConsole(P.Player.Console);
	if (C == None)
	{
		P.ClientMessage(default.LocNoUWindow);
		return;
	}

	if (!C.bCreatedRoot)
		C.CreateRootWindow(None);

	W = UDPlaybackWindow(C.Root.FindChildWindow(class'UDPlaybackWindow'));

	if (W != None && C.bQuickKeyEnable && W.bWindowVisible)
	{
		W.Close();
		return;
	}

	C.bQuickKeyEnable = True;
	C.LaunchUWindow();

	// The panel was still around but UWindow got closed from under it
	if (W != None)
	{
		W.ShowWindow();
		W.BringToFront();
		return;
	}

	NewWidth  = FMax(class'DemoSettings'.default.PanelWidth, DefaultWidth);
	NewHeight = FMax(class'DemoSettings'.default.PanelHeight, DefaultHeight);
	X = class'DemoSettings'.default.PanelLeft;
	Y = class'DemoSettings'.default.PanelTop;

	W = UDPlaybackWindow(C.Root.CreateWindow(class'UDPlaybackWindow', X, Y, NewWidth, NewHeight));
	W.bLeaveOnScreen = True;
}

// The root window has no size until UWindow has painted once, so the panel is
// placed on the first paint instead of on creation.
function BeforePaint(Canvas C, float X, float Y)
{
	Super.BeforePaint(C, X, Y);

	if (bPlaced || Root.WinWidth <= 0)
		return;
	bPlaced = True;

	if (WinLeft < 0)
		WinLeft = (Root.WinWidth - WinWidth)/2;
	if (WinTop < 0)
		WinTop = Root.WinHeight - WinHeight - 24;

	WinLeft = FClamp(WinLeft, 0, FMax(0, Root.WinWidth - WinWidth));
	WinTop = FClamp(WinTop, 0, FMax(0, Root.WinHeight - WinHeight));
}

function Created()
{
	Super.Created();

	bStatusBar = True;
	bSizable = True;
	MinWinWidth = 380;
	MinWinHeight = 200;
}

function Close(optional bool bByParent)
{
	class'DemoSettings'.default.PanelLeft = WinLeft;
	class'DemoSettings'.default.PanelTop = WinTop;
	class'DemoSettings'.default.PanelWidth = WinWidth;
	class'DemoSettings'.default.PanelHeight = WinHeight;
	class'DemoSettings'.static.StaticSaveConfig();

	Super.Close(bByParent);

	// Nothing else needs the mouse cursor - give the demo the input back
	if (!bByParent && Root.Console.bQuickKeyEnable)
		Root.Console.CloseUWindow();
}

defaultproperties
{
	ClientClass=class'UDPlaybackClient'
	WindowTitle="Demo Playback"
	LocNoUWindow="The playback panel needs a UWindow console."
}
