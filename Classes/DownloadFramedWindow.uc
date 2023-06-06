// =============================================================================
// UT Demo Manager v3.4
// Originally written by UsAaR33
// Project continued by AnthraX after v3.0
// =============================================================================
// udemo.DownloadFramedWindow: This is the "border" of the download window.
// has functions to force location, never active, etc.
// =============================================================================
class DownloadFramedWindow expands UWindowFramedWindow;

// =============================================================================
// Created ~
// =============================================================================
function Created()
{
	ResolutionChanged(0,0);
	Super.Created();
	CloseBox.HideWindow();
}

// =============================================================================
// ResolutionChanged ~
// =============================================================================
function ResolutionChanged(float W, float H)
{
	SetSize(280, 130);
	WinLeft = root.WinWidth - WinWidth;
	WinTop = 16; //correct relative to menu bar?
}

// =============================================================================
// EscClose ~
// =============================================================================
function EscClose()
{
	root.Console.CloseUWindow();
}

// =============================================================================
// IsActive ~ Hack
// =============================================================================
function bool IsActive()
{
	return true;
}

// =============================================================================
// Paint ~
// =============================================================================
function Paint(Canvas C, float X, float Y)
{
	local UWindowWindow Ac;

	Ac=ParentWindow.ActiveWindow;
	ParentWindow.ActiveWindow=self;
	super.Paint(C,X,Y);
	ParentWindow.ActiveWindow=Ac;
}

// =============================================================================
// LMouseDown ~ Don't allow movement!
// =============================================================================
function LMouseDown(float X, float Y);

defaultproperties
{
	ClientClass=Class'DownloadClient'
	WindowTitle="Downloading..."
	bTransient=True
}
