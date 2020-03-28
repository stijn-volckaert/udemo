// =============================================================================
// UT Demo Manager v3.4
// Originally written by UsAaR33
// Project continued by AnthraX after v3.0
// =============================================================================
// udemo.UDframedwindow: just a frame...
// =============================================================================
class UDframedwindow expands UWindowFramedWindow;

// =============================================================================
// Variables
// =============================================================================
var AutoRecorder MemHolder;

// =============================================================================
// Close ~ Creates invisible window to keep udemo in memory
// =============================================================================
function Close(optional bool bByParent)
{
    Super.Close(bByParent);

    if (MemHolder==None)
        MemHolder=AutoRecorder(root.createwindow(class'AutoRecorder',0,0,1,1,self));

    MemHolder.UDemo=DemoMainClientWindow(ClientArea).UserWindow;
    MemHolder.SendToBack();
}

// =============================================================================
// defaultproperties
// =============================================================================
defaultproperties
{
    ClientClass=Class'DemoMainClientWindow'
    WindowTitle="Unreal Tournament Demo Manager 3.5.1 - By UsAaR33 and AnthraX"
}

