// =============================================================================
// UT Demo Manager v3.4
// Originally written by UsAaR33
// Project continued by AnthraX after v3.0
// =============================================================================
// udemo.UDmoditem: The entry point :)
// =============================================================================
class UDmoditem expands UMenuModMenuItem;

const w = 510;
const h = 340;

// =============================================================================
// Execute ~ Create Window
// =============================================================================
function Execute()
{
    if (!OpenOldWindow())
        MenuItem.Owner.Root.CreateWindow(class'UDframedwindow',
	        Max(0, MenuItem.Owner.Root.winwidth/2 - w/2), Max(15, MenuItem.Owner.Root.winheight/2 - h/2), w, h);
}

// =============================================================================
// OpenOldWindow ~
// =============================================================================
function bool OpenOldWindow()
{
    local UWindowWindow Child;

    for(Child = MenuItem.Owner.Root.LastChildWindow;Child != None;Child = Child.PrevSiblingWindow)
    {
        if(Child.Class == class'AutoRecorder')
        {
            Child.OwnerWindow.ShowWindow();
            DemoMainClientWindow(UWindowFramedWindow(Child.OwnerWindow).ClientArea).Refresh(); //redo stuff
            Child.HideWindow();
            return true;
        }
    }
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

    if (MenuItem!=none)
        return;

    p = class'UdNative'.static.FindViewPort();
    if (p==none)
    {
        log("Unable to find player!!!",'UDemoError');
        return;
    }

    WC = WindowConsole(p.console);
    if (WC==none)
    {
        log("Unable to find Window Console!",'UDemoError');
        return;
    }

    Root = WC.Root;
    if (Root==none)
    {
        log("Unable to find rootwindow!",'UDemoError');
        return;
    }

    log("Startup hack successful!",'Udemo');
    UFW = Root.CreateWindow(class'UDframedwindow', Max(0, Root.winwidth/2 - w/2), Max(15, Root.winheight/2 - h/2), w, h);
    UFW.Close();
}

defaultproperties
{
	MenuCaption="&Demo Manager"
	MenuHelp="Play and Record demos!"
}
