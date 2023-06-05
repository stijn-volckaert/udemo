// =============================================================================
// UT Demo Manager v3.4
// Originally written by UsAaR33
// Project continued by AnthraX after v3.0
// =============================================================================
// udemo.UDnamewindow: a framed window for entry into "record demo"
// ripped from edit favorite window.
// =============================================================================
class UDnamewindow expands UWindowFramedWindow;

var UWindowSmallCloseButton CloseButton;
var UWindowSmallButton OKButton;

// =============================================================================
// Created ~
// =============================================================================
function Created()
{
    Super.Created();

    OKButton = UWindowSmallButton(CreateWindow(class'UWindowSmallButton', WinWidth-108, WinHeight-24, 48, 16));
    CloseButton = UWindowSmallCloseButton(CreateWindow(class'UWindowSmallCloseButton', WinWidth-56, WinHeight-24, 48, 16));
    OKButton.Register(UDnameclient(ClientArea));
    OKButton.SetText(class'UBrowserEditFavoriteWindow'.default.OKText);
    SetSizePos();
}

// =============================================================================
// ResolutionChanged ~
// =============================================================================
function ResolutionChanged(float W, float H)
{
    Super.ResolutionChanged(W, H);
    SetSizePos();
}

// =============================================================================
// SetSizePos ~
// =============================================================================
function SetSizePos()
{
    SetSize(FMin(Root.WinWidth-20, 200), 100);

    WinLeft = Int((Root.WinWidth - WinWidth) / 2);
    WinTop = Int((Root.WinHeight - WinHeight) / 2);
}

// =============================================================================
// Resized ~
// =============================================================================
function Resized()
{
    Super.Resized();
    ClientArea.SetSize(ClientArea.WinWidth, ClientArea.WinHeight-24);
}

// =============================================================================
// BeforePaint ~
// =============================================================================
function BeforePaint(Canvas C, float X, float Y)
{
    Super.BeforePaint(C, X, Y);

    OKButton.WinLeft = ClientArea.WinLeft+ClientArea.WinWidth-104;
    OKButton.WinTop = ClientArea.WinTop+ClientArea.WinHeight+4;
    CloseButton.WinLeft = ClientArea.WinLeft+ClientArea.WinWidth-52;
    CloseButton.WinTop = ClientArea.WinTop+ClientArea.WinHeight+4;
}

// =============================================================================
// Paint ~
// =============================================================================
function Paint(Canvas C, float X, float Y)
{
    local Texture T;

    T = GetLookAndFeelTexture();
    DrawUpBevel( C, ClientArea.WinLeft, ClientArea.WinTop + ClientArea.WinHeight, ClientArea.WinWidth, 24, T);

    Super.Paint(C, X, Y);
}

defaultproperties
{
	ClientClass=Class'UDnameclient'
	WindowTitle="Enter Demo Name"
}
