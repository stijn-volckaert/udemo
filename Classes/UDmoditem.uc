// =============================================================================
// UT Demo Manager v3.4
// Originally written by UsAaR33
// Project continued by AnthraX after v3.0
// =============================================================================
// udemo.UDmoditem: The entry point :)
// =============================================================================
class UDModItem expands UMenuModMenuItem;

const w = 510;
const h = 340;
const MinX = 0;
const MinY = 15; // for not cover window title with menu bar

// =============================================================================
// Execute ~ Create Window
// =============================================================================
function Execute()
{
	if (!OpenOldWindow())
		MenuItem.Owner.Root.CreateWindow(class'UDframedwindow',
			Max(MinX, MenuItem.Owner.Root.WinWidth/2 - w/2), 
			Max(MinY, MenuItem.Owner.Root.WinHeight/2 - h/2), w, h, None, True);
}

// =============================================================================
// OpenOldWindow ~
// =============================================================================
function bool OpenOldWindow()
{
	local UWindowWindow Child;

	for (Child = MenuItem.Owner.Root.LastChildWindow; Child != None; Child = Child.PrevSiblingWindow)
	{
		if (Child.Class == class'AutoRecorder')
		{
			Child.OwnerWindow.ShowWindow();
			if (Child.OwnerWindow.WinLeft < MinX || Child.OwnerWindow.WinTop < MinY)
			{
				Child.OwnerWindow.WinLeft = Max(MinX, MenuItem.Owner.Root.WinWidth/2 - w/2);
				Child.OwnerWindow.WinTop = Max(MinY, MenuItem.Owner.Root.WinHeight/2 - h/2);
			}
			DemoMainClientWindow(UWindowFramedWindow(Child.OwnerWindow).ClientArea).Refresh(); //redo stuff
			Child.HideWindow();
			return true;
		}
	}
	return false;
}

// =============================================================================
// Setup ~ Called when menu system is initialized...
// =============================================================================
function Setup()
{
	local UWindowRootWindow Root;
	local UWindowWindow UFW;
	local Player p;
	local WindowConsole WC;

	if (MenuItem != None)
		return;

	p = class'UdNative'.static.FindViewPort();
	if (p == None)
	{
		log("Unable to find player!!!",'UDemoError');
		return;
	}

	WC = WindowConsole(p.Console);
	if (WC == None)
	{
		log("Unable to find Window Console!",'UDemoError');
		return;
	}

	Root = WC.Root;
	if (Root == None)
	{
		log("Unable to find rootwindow!",'UDemoError');
		return;
	}

	log("Startup hack successful!",'Udemo');
	UFW = Root.CreateWindow(class'UDframedwindow', 
		Max(MinX, Root.winwidth/2 - w/2), 
		Max(MinY, Root.winheight/2 - h/2), w, h, None, True);
	UFW.Close();
}

defaultproperties
{
	MenuCaption="&Demo Manager"
	MenuHelp="Play and Record demos!"
}
