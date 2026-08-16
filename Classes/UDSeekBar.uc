// =============================================================================
// UT Demo Manager v3.4
// Originally written by UsAaR33
// Project continued by AnthraX after v3.0
// =============================================================================
// udemo.UDSeekBar: clickable/draggable timeline used by the playback panel.
// A click seeks right away, dragging shows a marker and seeks on release.
// =============================================================================
class UDSeekBar expands UWindowWindow;

var UDPlaybackClient Panel;   // panel the seeks are reported to
var float            Progress;// 0..1, part of the demo already played
var float            Marker;  // 0..1 mouse marker position, -1 when the mouse is away
var bool             bScrubbing;
var bool             bSeeking;// a seek is running - the game is about to freeze
var string           TimeText;// drawn on top of the bar

const BarInset = 2;

function Created()
{
	Super.Created();
	Marker = -1;
	Cursor = Root.HandCursor;
}

// Position (0..1) of a mouse X coordinate
function float FracAt(float X)
{
	return FClamp((X - BarInset) / FMax(1, WinWidth - 2*BarInset), 0.0, 1.0);
}

function Paint(Canvas C, float X, float Y)
{
	local float W, H, InnerW, InnerH;
	local Texture T;

	T = Texture'UWindow.WhiteTexture';
	InnerW = WinWidth - 2*BarInset;
	InnerH = WinHeight - 2*BarInset;

	DrawMiscBevel(C, 0, 0, WinWidth, WinHeight, LookAndFeel.Misc, 2);

	C.DrawColor.R = 40;
	C.DrawColor.G = 40;
	C.DrawColor.B = 40;
	DrawStretchedTexture(C, BarInset, BarInset, InnerW, InnerH, T);

	if (bSeeking)
	{
		C.DrawColor.R = 160;
		C.DrawColor.G = 75;
		C.DrawColor.B = 0;
	}
	else
	{
		C.DrawColor.R = 40;
		C.DrawColor.G = 110;
		C.DrawColor.B = 200;
	}
	DrawStretchedTexture(C, BarInset, BarInset, InnerW*Progress, InnerH, T);

	if (Marker >= 0.0 && !bSeeking)
	{
		C.DrawColor.R = 255;
		C.DrawColor.G = 220;
		C.DrawColor.B = 0;
		DrawStretchedTexture(C, BarInset + InnerW*Marker - 1, BarInset, 2, InnerH, T);
	}

	// shadow first - the text runs over both the filled and the empty part
	C.Font = Root.Fonts[F_Bold];
	TextSize(C, TimeText, W, H);

	C.DrawColor.R = 0;
	C.DrawColor.G = 0;
	C.DrawColor.B = 0;
	ClipText(C, (WinWidth - W)/2 + 1, (WinHeight - H)/2 + 1, TimeText);

	C.DrawColor.R = 255;
	C.DrawColor.G = 255;
	C.DrawColor.B = 255;
	ClipText(C, (WinWidth - W)/2, (WinHeight - H)/2, TimeText);
}

function LMouseDown(float X, float Y)
{
	Super.LMouseDown(X, Y);
	bScrubbing = True;
	Marker = FracAt(X);
	Root.CaptureMouse(Self);
}

function MouseMove(float X, float Y)
{
	Super.MouseMove(X, Y);
	if (!bMouseDown)
		bScrubbing = False;
	Marker = FracAt(X);
}

function LMouseUp(float X, float Y)
{
	Super.LMouseUp(X, Y);
	if (bScrubbing)
	{
		bScrubbing = False;
		Panel.SeekFraction(FracAt(X));
	}
	Marker = -1;
}

function MouseLeave()
{
	Super.MouseLeave();
	bScrubbing = False;
	Marker = -1;
}

// The wheel steps through the demo. Only the release event carries the direction.
function bool MouseWheelDown(float ScrollDelta)
{
	return True;
}

function bool MouseWheelUp(float ScrollDelta)
{
	Panel.SeekRelative(-5.0 * ScrollDelta);
	return True;
}

defaultproperties
{
	Marker=-1.000000
}
