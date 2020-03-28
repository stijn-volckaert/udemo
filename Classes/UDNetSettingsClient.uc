// =============================================================================
// UT Demo Manager v3.4
// Originally written by UsAaR33
// Project continued by AnthraX after v3.0
// =============================================================================
// udemo.UDNetSettingsClient: options for use with the master server file downloader.
// =============================================================================
class UDNetSettingsClient expands UMenuPageWindow;

// =============================================================================
// Variables
// =============================================================================
var UWindowEditControl Servers[6];
var UWindowComboControl DLType;
var localized string Empty;

// =============================================================================
// Created ~
// =============================================================================
function Created()
{
    local int i;
    local int ControlOffset;
    local int CenterWidth, CenterPos, CenterWidth2, CenterPos2;
    local UWindowLabelControl Info;

    Super.Created();

    //new stuff from that d00d
    CenterWidth2  = WinWidth - 10;               //(WinWidth/8)*7; //combo width
    CenterWidth   = (WinWidth - 30)/2;           //button width
    CenterPos     = 5;                           //(WinWidth - CenterWidth)/2;
    CenterPos2    = WinWidth - CenterWidth - 10; //right position for button
    ControlOffset = 10;

    DLType = UWindowComboControl(CreateControl(class'UWindowComboControl',CenterPos, ControlOffset, CenterWidth2, 1));
    DLType.SetText("Save Type:");
    DLType.Align = TA_Left;
    DLType.SetHelpText("Configure where demos should be saved to.  If saved in main directories, the file will be usable in singleplayer, but may lead to version mismatches in other demos or netplay.");
    DLType.SetFont(F_Normal);
    DLType.editboxwidth=0.78*DLType.winwidth;
    DLType.SetEditable(False);
    DLType.additem("In Cache Directory");
    DLType.AddItem("In Main Directories");
//    DLType.AddItem("Main Directories w/ INT Installing");
    DLType.setselectedindex(class'DemoSettings'.default.DownloadType);
    ControlOffset += 22;

    Info = UWindowLabelControl(CreateControl(class'UWindowLabelControl', CenterPos, ControlOffset, CenterWidth2, 1));
    Info.Align = TA_Left;
    Info.setfont(F_Bold);
    Info.SetText("UZ redirect Servers:");
    ControlOffset += 15;

    //generate stuff:
    for (i=0;i<6;i++)
    {
        Servers[i] = UWindowEditControl(CreateControl(class'UWindowEditControl',CenterPos, ControlOffset, CenterWidth2-5, 1));
        Servers[i].editboxwidth=0.78*Servers[i].winwidth;
        Servers[i].SetFont( F_Normal );
        Servers[i].Align = TA_Left;
        Servers[i].SetDelayedNotify(true);
        Servers[i].SetValue(class'DemoSettings'.default.RedirectServers[i]);
        Servers[i].SetText("#"$i+1@"HTTP://");
        Servers[i].SetHelpText("Enter in an HTTP Unreal UZ redirect server to use.");
        ControlOffset += 20;
    }
}

// =============================================================================
// WindowHidden ~ Save properties here
// =============================================================================
function WindowHidden()
{
    local int i;

    Super.WindowHidden();

    if (!DemoMainClientWindow(GetParent(class'DemoMainClientWindow')).bInitialized)
        return;

    class'DemoSettings'.default.DownloadType=DLType.GetSelectedIndex();

    for (i=0;i<6;i++)
    {
        if (Servers[i].GetValue()~=Empty||Servers[i].GetValue()=="")
            Servers[i].SetValue(Empty);
        class'DemoSettings'.default.RedirectServers[i]=Servers[i].GetValue();
    }
}

// =============================================================================
// defaultproperties
// =============================================================================
defaultproperties
{
  Empty="(Empty)"
}
