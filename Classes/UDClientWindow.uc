// =============================================================================
// UT Demo Manager v3.4
// Originally written by UsAaR33
// Project continued by AnthraX after v3.0
// =============================================================================
// udemo.UDClientWindow:  pretty much it.  The demo manager itself (user window)
// =============================================================================
class UDClientWindow expands UMenuPageWindow;

// =============================================================================
// Variables
// =============================================================================
var UWindowComboControl demos;         // list to select demo
var UWindowComboControl timing;        // list to select timing
var UWindowComboControl drivers;       // list to select driver
var UWindowSmallButton  Record;        // start recording
var UWindowSmallButton  Play;          // play selected demo
var UWindowSmallButton  StopB;         // stop playback
var UWindowSmallButton  Delete;        // delete selected demo
var UWindowSmallButton  Rename;        // rename selected demo
var UWindowSmallButton  Write;         // write demo summary
var UWindowCheckBox     Spectate;      // tick to spectate
var UMenuLabelControl   sizelabel;     // how large is demo? KB
var UWindowMessageBox   DeleteMSG;     // delete warning
var UWindowMessageBox   doDlMsg;       // corrupted file warning. Asks for Download
var UWindowMessageBox   doGenWarnMsg;  // generation mismatch. Can't fix this by Download
var UDComboListItem     LastDemoItem;  // for list saving
var DemoReader          demreader;     // class that exists in C++ to search for demos and give info on them.
var string              last;          // to add new demos found later...
var byte                ShotTime;      // shot timer
var byte                LastInstalled; // speed
var bool                Initialized;   // Init done
var localized string    Spechelp;      // save file size
var localized string	LocDemos;
var localized string	LocDemosHelp;
var localized string	LocPlayDemo;
var localized string	LocPlayDemoHelp;
var localized string	LocRecordDemo;
var localized string	LocRecordDemoHelp;
var localized string	LocStopDemo;
var localized string	LocStopDemoHelp;
var localized string	LocRenameDemoFile;
var localized string	LocRenameDemoFileHelp;
var localized string	LocDeleteDemoFile;
var localized string	LocDeleteDemoFileHelp;
var localized string	LocWriteDemoSummary;
var localized string	LocWriteDemoSummaryHelp;
var localized string	LocSelectAdditionalOptions;
var localized string	LocAOTiming;
var localized string	LocAOTimingHelp;
var localized string	LocAOTimingFrameBased;
var localized string	LocAOTimingTimeBased;
var localized string	LocAOTimingFastAsPossible;
var localized string	LocAOSpectate;
var localized string	LocDrivers;
var localized string	LocDriversHelp;
var localized string	LocDriversStock;
var localized string	LocDriversUdemo;
var localized string	ConfirmSettingsRestartTitle;
var localized string	ConfirmSettingsRestartText;
var localized string	LocDemoUsesOutdatedVersionsWarning;
var localized string	LocDemoUsesOutdatedVersionsPrefix;
var localized string	LocDemoUsesOutdatedVersionsSuffix;
var localized string	LocDemoUsesOutdatedVersionsSuffix2;
var localized string	LocDemoCannotPlay;
var localized string	LocDemoCannotPlayPrefix;
var localized string	LocDemoCannotPlaySuffix;
var localized string	LocDemoCannotPlaySuffix2;
var localized string	LocDemoCannotPlaySuffix3;
var localized string	LocDemoCannotPlaySuffix4;
var localized string	LocDemoCannotPlaySuffix5;
var localized string	LocCannotRecordADemoTitle;
var localized string	LocCannotRecordADemoMessage;
var localized string	LocFailedToRemoveTitle;
var localized string	LocFailedToRemoveMessagePrefix;
var localized string	LocFailedToRemoveMessageSuffix;
var localized string	LocRenameDemoTitle;
var localized string	LocDemoSummarySuccessTitle;
var localized string	LocDemoSummarySuccessPrefix;
var localized string	LocDemoSummarySuccessSuffix;
var localized string	LocDemoSummaryErrorTitle;
var localized string	LocDemoSummaryErrorMessage;
var localized string	LocDeleteDemoTitle;
var localized string	LocDeleteDemoMessagePrefix;
var localized string	LocDeleteDemoMessageSuffix;
var localized string	LocThirdPersonAlwaysTrue;

// =============================================================================
// Created ~
// =============================================================================
function Created()
{
    local class<UWindowComboList> OldDefault;
    local int ControlOffset;
    local int CenterWidth, CenterPos, CenterWidth2, CenterPos2;
    local int i;
    local UWindowLabelControl Ctrl, Ctrl_dem;
    local bool B;

    CenterWidth2 = WinWidth - 20;//(WinWidth/8)*7; //combo width
    CenterWidth = (WinWidth - 30)/2; //button width
    CenterPos = 10;//(WinWidth - CenterWidth)/2;
    CenterPos2 = WinWidth - CenterWidth - 10; //right position for button
    ControlOffset = 5;

    super.created();

    Ctrl_dem = UWindowLabelControl(CreateControl(class'UWindowLabelControl', CenterPos, ControlOffset, CenterWidth, 16));
    Ctrl_dem.SetFont( F_Bold );
    Ctrl_dem.SetText(LocDemos);

    demreader = new class'DemoReader'; //create native reader object.
    demreader.control=DemoMainClientWindow(GetParent(class'DemoMainClientWindow'));   //link to main!

    sizelabel=UMenuLabelControl(CreateWindow(class'UMenuLabelControl', CenterPos2, ControlOffset,CenterWidth, 1));
    sizelabel.Align = TA_Right;

    //hack to use modified list class:
    OldDefault=Class'UwindowComboControl'.default.listclass;
    Class'UwindowComboControl'.default.listclass=class'UDComboList';
    ControlOffSet+=14;

    demos = UWindowComboControl(CreateControl(class'UWindowComboControl', CenterPos, ControlOffset, CenterWidth2, 1));
    Class'UwindowComboControl'.default.listclass=OldDefault;
    demos.SetButtons(True);
    demos.Align = TA_Left;
    demos.SetHelpText(LocDemosHelp);
    demos.SetFont(F_Normal);
    demos.SetEditable(False);
    demos.editboxwidth=CenterWidth2;
    ControlOffset+=20;

    Play = UWindowSmallButton(CreateControl(class'UWindowSmallButton', CenterPos2, ControlOffset, CenterWidth, 16));
    Play.SetFont(F_bold);
    Play.SetText(LocPlayDemo);
    Play.sethelptext(LocPlayDemoHelp);

    Record = UWindowSmallButton(CreateControl(class'UWindowSmallButton', CenterPos, ControlOffset, CenterWidth, 16));
    Record.SetText(LocRecordDemo);
    Record.sethelptext(LocRecordDemoHelp);

    stopb = UWindowSmallButton(CreateControl(class'UWindowSmallButton', CenterPos, ControlOffset, CenterWidth, 16));
    stopb.SetFont(F_bold);
    stopb.SetText(LocStopDemo);
    stopb.sethelptext(LocStopDemoHelp);
    //next buttons row
    ControlOffset+=20;

    Rename = UWindowSmallButton(CreateControl(class'UWindowSmallButton', CenterPos, ControlOffset, CenterWidth, 16));
    Rename.SetText(LocRenameDemoFile);
    Rename.sethelptext(LocRenameDemoFileHelp);
//  ControlOffset+=20;

    Delete = UWindowSmallButton(CreateControl(class'UWindowSmallButton', CenterPos2, ControlOffset, CenterWidth, 16));
    Delete.SetText(LocDeleteDemoFile);
    Delete.sethelptext(LocDeleteDemoFileHelp);
    ControlOffset+=20;

    Write = UWindowSmallButton(CreateControl(class'UWindowSmallButton', CenterPos, ControlOffset, CenterWidth2, 1));
    Write.SetText(LocWriteDemoSummary);
    Write.sethelptext(LocWriteDemoSummaryHelp);
    ControlOffset+=20;

    Ctrl = UWindowLabelControl(CreateControl(class'UWindowLabelControl', CenterPos, ControlOffset, CenterWidth2, 1));
    Ctrl.SetFont( F_Bold );
    Ctrl.SetText(LocSelectAdditionalOptions);
    ControlOffset+=16;

    timing = UWindowComboControl(CreateControl(class'UWindowComboControl',CenterPos, ControlOffset, CenterWidth2, 1));
    timing.SetButtons(True);
    timing.SetText(LocAOTiming);
    timing.Align = TA_Left;
    timing.SetHelpText(LocAOTimingHelp);
    timing.SetFont(F_Normal);
    timing.SetEditable(False);
    timing.editboxwidth=0.7*timing.winwidth;
    timing.additem(LocAOTimingFrameBased);
    timing.AddItem(LocAOTimingTimeBased$" (?timebased)");
    timing.AddItem(LocAOTimingFastAsPossible$" (?noframecap)");
    timing.setselectedindex(class'DemoSettings'.default.Timing); //FIX ME! SAVED ITEM!
    ControlOffset+=19;

    Spectate=UWindowCheckBox(CreateControl(class'UWindowCheckBox', CenterPos, ControlOffset, CenterWidth2, 16));
    Spectate.SetText(LocAOSpectate);
    Spectate.SetHelpText(spechelp);
    Spectate.bChecked=Class'DemoSettings'.default.SpecDemo;
    ControlOffset+=16;
    
    drivers = UWindowComboControl(CreateControl(class'UWindowComboControl',CenterPos, ControlOffset, CenterWidth2, 1));
    drivers.SetButtons(True);
    drivers.SetText(LocDrivers);
    drivers.Align = TA_Left;
    drivers.SetHelpText(LocDriversHelp);
    drivers.SetFont(F_Normal);
    drivers.SetEditable(False);
    drivers.EditBoxWidth = 0.7*drivers.WinWidth;
    drivers.AddItem(LocDriversStock, "Engine.DemoRecDriver");
    drivers.AddItem("udemo" @ LocDriversUdemo, "udemo.uDemoDriver");
    i = 0;
    if (demreader.SetDemoDriverClass("") ~= "udemo.uDemoDriver")
    	i = 1;
    drivers.SetSelectedIndex(i); //FIX ME! SAVED ITEM!
    ControlOffset+=19;
    
    Initialized = true;
}

// =============================================================================
// Refresh ~ Called on any open
// =============================================================================
function Refresh(optional bool init)
{
    local UDComboListItem L;

    SetupDemos(!init);

    if (!init)
    {
        for (L=UDComboListItem(demos.List.Items.Next); L!=none; L=UDComboListItem(L.next))
        {
            if (!L.Validated)
            {
                if (L==LastDemoItem)
                {
                    init=true;
                    demos.SetValue("");
                }
                L.Remove();
            }
            else
                L.Validated=false;
        }

        Demos.SetValue(Demos.GetValue(),Demos.GetValue2());  //hack :)
    }

    if (init && demos.GetValue()=="")
        Demos.SetSelectedIndex(0);
}

// =============================================================================
// SetupDemos ~ Use demoreader natives to get the list
// =============================================================================
function SetupDemos(bool Refreshing)
{
    local string demoinfo, toadd;
    local int pos;
    local UDComboListItem L;
    local int i;

    // Once for each path
    for (i=0; i<5; i++)
    {
        if (!(Class'DemoSettings'.default.DemoPaths[i]~=class'udpathsclient'.default.Empty))
        {
            demoinfo=demreader.getdemo(Class'DemoSettings'.default.DemoPaths[i]);

            //Null string=no more demos.
            while (demoinfo!="")
            {
                //log (demoinfo);
                pos=instr(demoinfo,"/");
                toadd=left(demoinfo,pos-4);     //commented=size
                if (!Refreshing)
                {
                    demos.additem(toadd,class'demosettings'.static.Path(i,demreader.BasePath()),int(mid(demoinfo,pos+1)));

                    if (toadd~=class'demosettings'.default.lastdemo)
                        demos.SetValue(toadd,class'demosettings'.static.Path(i,demreader.BasePath()));
                }
                else
                {
                    for (L=UDComboListItem(demos.List.Items.next);L!=none;L=UDComboListItem(L.next))
                    {
                        if (L.value==toadd)
                        {
                            L.Validated=true;
                            break;
                        }
                    }

                    if (L==none)
                        UDComboList(demos.List).AddSortedItem(toadd,class'demosettings'.static.Path(i,demreader.BasePath()),int(mid(demoinfo,pos+1))); //must add.
                }

                demoinfo=demreader.getdemo("");
            }
        }
    }

    if (!Refreshing)
        demos.sort();
}

// =============================================================================
// DemoChanged ~ Demo selected => Read Info
// =============================================================================
function demochanged()
{
    Write.bdisabled=true;

    if (demos.GetValue()=="")
        return;

    if (LastDemoItem!=none && DemReader.Control.Packages.Next!=none && LastDemoItem.MapName!="") //else would screw up :p
        LastDemoItem.Packages=DemoList(demreader.control.Packages.next);

    demreader.control.Packages.DisconnectList();
    LastDemoItem=UDComboList(Demos.List).FindItem(Demos.GetValue());
    shottime=0; //safety.
    sizelabel.settext(LastDemoItem.sortweight@"kb");
    demreader.control.PBI.Reset();
    demreader.control.ScreenShot.SetPending();

    //reset spec stuff:
    Spectate.bDisabled=false;
    Spectate.bChecked=Class'DemoSettings'.default.SpecDemo;
    Spectate.SetHelpText(spechelp);

     //already read
    if (LastDemoItem.Packages != none)
    {
        DemReader.bblocked=true;  //in case currently analyzing
        demreader.control.Packages.next=LastDemoItem.Packages;
        LastDemoItem.Packages.Refresh(demreader.control.PBI);

        if (bwindowvisible) //can accept ticks
            ShotTime=2;
        else
        {
            ShotTime=1;
            Tick(0.0);
        }
    }
    else
    {
        DemReader.bblocked=false; //allow analyze :)
        demreader.DemoRead(LastDemoItem.Value2$LastDemoItem.Value$"?noframecap",GetPlayerOwner().Xlevel);
    }
}

// =============================================================================
// PlayDemo ~ Check if demo can be played, then assemble demoplay URL and start
// =============================================================================
function PlayDemo(optional bool noInstallCheck)
{
    local string assembled;
    local int i, j;

    if (demos.getvalue() != "")
    {
        if (!noInstallCheck)
        {
            // we must call this repeatively, in order to force all linkers to load correctly! up to package amount is max!
            j = DemoMainClientWindow(GetParent(class'DemoMainClientWindow')).Packages.InternalCount;

            for (i=0; i<j; i++)
            {
                LastInstalled = DemoMainClientWindow(GetParent(class'DemoMainClientWindow')).Packages.AllInstalled();
                if (LastInstalled!=3) //if is 3, may need to load cached linkers
                    break;
            }

            switch (LastInstalled)
            {
                case 0:
                    break; //all is good

                case 1:
                    if (root.FindChildWindow(class'DownloadFramedWindow') == none)
                        doDlMsg = MessageBox(LocDemoUsesOutdatedVersionsWarning, LocDemoUsesOutdatedVersionsPrefix$" '"$demos.getvalue()$"' "$LocDemoUsesOutdatedVersionsSuffix, MB_YesNoCancel, MR_No, MR_None);
                    else
                        doGenWarnMsg = MessageBox(LocDemoUsesOutdatedVersionsWarning, LocDemoUsesOutdatedVersionsPrefix$" '"$demos.getvalue()$"' "$LocDemoUsesOutdatedVersionsSuffix2, MB_YesNo, MR_No, MR_None);
                    return;

                case 2:
                    if (root.FindChildWindow(class'DownloadFramedWindow')==none)
                        doDlMsg = MessageBox(LocDemoCannotPlay, LocDemoCannotPlayPrefix$" '"$demos.getvalue()$"' "$LocDemoCannotPlaySuffix, MB_YesNoCancel, MR_No, MR_None);
                    else
                        MessageBox(LocDemoCannotPlay, LocDemoCannotPlayPrefix$" '"$demos.getvalue()$"' "$LocDemoCannotPlaySuffix2, MB_OK, MR_OK, MR_OK);
                    return;

                case 3:
                    MessageBox(LocDemoCannotPlay, LocDemoCannotPlayPrefix$" '"$demos.getvalue()$"' "$LocDemoCannotPlaySuffix3, MB_OK, MR_OK, MR_OK);
                    return;

                case 4:
                    if (root.FindChildWindow(class'DownloadFramedWindow')==none)
                        doDlMsg = MessageBox(LocDemoCannotPlay, LocDemoCannotPlayPrefix$" '"$demos.getvalue()$"' "$LocDemoCannotPlaySuffix4, MB_YesNo, MR_No, MR_None);
                    else
                        MessageBox(LocDemoCannotPlay, LocDemoCannotPlayPrefix$" '"$demos.getvalue()$"' "$LocDemoCannotPlaySuffix5, MB_OK, MR_OK, MR_OK);
                    return;
            }
        }

        GetParent(class'UWindowFramedWindow').Close();
        Root.Console.CloseUWindow();

        getplayerowner().consolecommand("stopdemo"); //needed?

        assembled="demoplay \""$demos.getvalue2()$demos.getvalue();     //assemble command with options
        if (Spectate.bchecked)
            assembled=assembled$"?3rdperson";
        if (timing.GetSelectedIndex() == 1)
            assembled=assembled$"?timebased";
        else if (timing.GetSelectedIndex() == 2)
            assembled=assembled$"?noframecap";
        assembled=assembled$"\"";

        // (Anth) Linux FURL is fucked so we need to store the assembled URL somewhere and restore it in the native...
        demreader.DemoURL = assembled;
        getplayerowner().consolecommand(assembled); //play demo!
    }
}

// =============================================================================
// RecordDemo ~ Record a demo using the specified mask
// =============================================================================
function RecordDemo()
{
    local Uwindowwindow temp;

    if (GetLevel()!=GetEntryLevel())
    {
        temp = root.CreateWindow(class'UDnamewindow',10, 10, 200, 100,self);
        GetParent(class'UWindowFramedWindow').ShowModal(temp);
        UDnameclient(UWindowFramedWindow(temp).clientarea).NameEdit.SetValue(
            class'DemoSettings'.static.GetDemoName(GetPlayerOwner(),UWindowComboListItem(LastDemoItem.Sentinel))); //set to autorecord thing!
    }
    else //error
        MessageBox(LocCannotRecordADemoTitle, LocCannotRecordADemoMessage, MB_OK, MR_OK, MR_OK);
}

// =============================================================================
// DeleteDemo ~
// =============================================================================
function DeleteDemo()
{
    local int i;

    if (demreader.kill(demos.GetValue2()$demos.GetValue()$".dem"))
    {
        i=demos.GetSelectedIndex();
        demos.removeitem(i);
        demos.setselectedindex(max(0,i-1)); //move list back.
    }
    else //failed!
        MessageBox(LocFailedToRemoveTitle, LocFailedToRemoveMessagePrefix$" "@demos.getvalue()$".dem\\n"$LocFailedToRemoveMessageSuffix, MB_OK, MR_OK, MR_OK);
}

// =============================================================================
// RenameDemo ~
// =============================================================================
function RenameDemo()
{
    local Uwindowwindow temp;

    temp = root.CreateWindow(class'UDnamewindow',10, 10, 200, 100,self);      //create it
    GetParent(class'UWindowFramedWindow').ShowModal(temp); //show it.
    UDnameclient(UWindowFramedWindow(temp).clientarea).demreader=demreader; //when demreader!=none renaming occurs.
    UDnameclient(UWindowFramedWindow(temp).clientarea).NameEdit.SetValue(demos.getValue()); //requested by someone! ;p
    Uwindowframedwindow(temp).WindowTitle=LocRenameDemoTitle;
}

// =============================================================================
// BaseDirReplace ~
// =============================================================================
function string BaseDirReplace(UDComboListItem Demo)
{
    if (Demo.Value2!="")
        Return Demo.Value2;
    else
        Return demreader.BasePath();
}

function DriverChanged()
{
	if (!Initialized)
		return;
	demreader.SetDemoDriverClass(drivers.GetValue2());
	MessageBox(ConfirmSettingsRestartTitle, ConfirmSettingsRestartText, MB_OK, MR_OK, MR_OK);
}

// =============================================================================
// Notify ~ Control notification
// =============================================================================
function Notify(UWindowDialogControl C, byte E)
{
    Super.Notify(C, E);

    switch(E)
    {
        case DE_Change:    //combo
            switch(C)
            {
                case demos:
                    demochanged();
                    break;

                case Spectate:
                    if (!Spectate.bdisabled)
                        class'DemoSettings'.default.specdemo=Spectate.bchecked;
                    break;
                    
                case drivers:
                    DriverChanged();
                    break;
            }
            break;

        case DE_Click:    //buttons
            switch(C)
            {
                case Record:
                    RecordDemo();
                    break;

                case Play:
                    PlayDemo();
                    break;

                case Write: //write info :)
                    if (Write.bdisabled)
                        return;

                    if (DemReader.SaveInfo())
                        MessageBox(LocDemoSummarySuccessTitle, LocDemoSummarySuccessPrefix@" "@BaseDirReplace(LastDemoItem)$LastDemoItem.Value$"Info.TXT"$LocDemoSummarySuccessSuffix, MB_OK, MR_OK, MR_OK);
                    else
                        MessageBox(LocDemoSummaryErrorTitle, LocDemoSummaryErrorMessage, MB_OK, MR_OK, MR_OK);
                    break;

                case stopb:      //stop demo
                    stopb.hidewindow();
                    getplayerowner().consolecommand("stopdemo");
                    record.showwindow();
                    break;

                case Delete:
                    DeleteMSG = MessageBox(LocDeleteDemoTitle, LocDeleteDemoMessagePrefix$" "$demos.getvalue()$" "$LocDeleteDemoMessageSuffix, MB_YesNo, MR_No, MR_None);
                    break;

                case Rename:
                    RenameDemo();
                    break;
            }
            break;
    }
}

// =============================================================================
// MessageBoxDone ~ Overwritten
// =============================================================================
function MessageBoxDone(UWindowMessageBox W, MessageBoxResult Result)
{
    if(Result == MR_Yes)
    {
        switch(W)
        {
            case DeleteMSG:
                DeleteDemo(); //user has conformed he wishes to over-write file.
                break;

            case doDlMsg: //setup downloader
                DownloadClient(UWindowFramedWindow(root.CreateWindow(class'DownloadFramedWindow',10, 10, 200, 100,self)).ClientArea).SetPkgList(demreader.control.Packages,LastInstalled);
                break;

            case doGenWarnMsg:
                PlayDemo(true); //play!
                break;
        }
    }

    if (Result == MR_No && (LastInstalled == 1 || LastInstalled == 2) && W == doDlMsg)
        PlayDemo(true);
}

// =============================================================================
// Close ~ Save stuff
// =============================================================================
function Close (optional bool bByParent)
{
    Super.Close(bByParent);

    class'DemoSettings'.default.Timing=Timing.GetSelectedIndex();
    class'DemoSettings'.default.SpecDemo=Spectate.bchecked;
    class'DemoSettings'.default.LastDemo=Demos.GetValue();
    class'DemoSettings'.static.StaticSaveConfig();
}

// =============================================================================
// Tick ~ Ticks the demo reader
// =============================================================================
function Tick(float delta)
{
    if (ShotTime>0)
    {
        Write.bDisabled=false;
        ShotTime--;

        if (LastDemoItem.bServerDemo)
        {
            Spectate.bdisabled=true;
            Spectate.bchecked=true;
            Spectate.SetHelpText(LocThirdPersonAlwaysTrue);
        }

        if (ShotTime==0)
            DemReader.Control.ScreenShot.SetUDMap(LastDemoItem.MapName,LastDemoItem.bServerDemo,LastDemoItem.NumFrames,LastDemoItem.PlayTime);
    }

    //update stop button (can do console command or something else)
    //needed to check recording with native functions.
    if (demreader.demoactive(getplayerowner().xlevel) >0)
    {
        if (!stopb.bWindowVisible)
        {
            stopb.ShowWindow(); //hide if no demo playing.
            Record.HideWindow();
        }
    }
    else if (stopb.bWindowVisible)
    {
        stopb.hidewindow();
        Record.ShowWindow();
    }

    demreader.DispatchTick(delta/GetLevel().timedilation);
}

// =============================================================================
// defaultproperties
// =============================================================================

defaultproperties
{
    SpecHelp="If checked, you will be able to fly around the level when playing a demo"
	LocDemos="Demos:"
	LocDemosHelp="Select the demo that you wish to play."
	LocPlayDemo="PLAY"
	LocPlayDemoHelp="Click here to play the selected demo!  Note that your current game/demo will end."
	LocRecordDemo="RECORD DEMO"
	LocRecordDemoHelp="Click here to start recording a demo!"
	LocStopDemo="STOP"
	LocStopDemoHelp="Click here to stop playing/recording"
	LocRenameDemoFile="Rename file"
	LocRenameDemoFileHelp="Click here to rename this demo!"
	LocDeleteDemoFile="Delete file"
	LocDeleteDemoFileHelp="Click here to remove this demo from existance!"
	LocWriteDemoSummary="Write demo summary"
	LocWriteDemoSummaryHelp="Click here to cause a demo summary TXT file to be written."
	LocSelectAdditionalOptions="Select additional options"
	LocAOTiming="Timing"
	LocAOTimingHelp="Configure how playback timing should occur. Normal means FPS will slow to Recorder's, timing causes the file to be read only when enough time has passed, and Fast as Possible causes file reading every tick."
	LocAOTimingFrameBased="Frame Based (normal)"
	LocAOTimingTimeBased="Time Based"
	LocAOTimingFastAsPossible="Fast as Possible"
	LocAOSpectate="3rdPerson (Spectate)"
	LocDrivers="Demo Driver"
	LocDriversHelp="Choose which driver to use for demo recording and playback"
	LocDriversStock="Stock (basic)"
	LocDriversUdemo="(extended)"
	ConfirmSettingsRestartTitle="Demo Driver Changed"
	ConfirmSettingsRestartText="Your updated demo driver setting will take effect after restarting the game."
	LocDemoUsesOutdatedVersionsWarning="Warning"
	LocDemoUsesOutdatedVersionsPrefix="The demo file"
	LocDemoUsesOutdatedVersionsSuffix="is using outdated versions of some files that MAY result in semi-corrupt playback.\\nShould Unreal Tournament Demo Manager attempt to download updated versions from master servers?\\n(Clicking no will play the demo immediately)"
	LocDemoUsesOutdatedVersionsSuffix2="is using outdated versions of some files that MAY result in semi-corrupt playback.\\nAs a file download is currently occuring, you will need to terminate it to begin download of updated files if destired.\\nContinue to play demo without updating?"
	LocDemoCannotPlay="Cannot Play"
	LocDemoCannotPlayPrefix="Warning: The demo file"
	LocDemoCannotPlaySuffix="is using files that will cause a version mismatch with the demo.\\nShould Unreal Tournament Demo Manager attempt to download the appropriate versions from master servers?\\n(Note: this will cause exising file to be moved into cache!)"
	LocDemoCannotPlaySuffix2="is using files that will cause a version mismatch with the demo.\\nIf you wish to download correct files for this demo, please abort current download"
	LocDemoCannotPlaySuffix3="uses a file that will not load and udemo does not know what to do!  Please report this error to 'stidzjene@hotmail.com' immediately!"
	LocDemoCannotPlaySuffix4="is missing files that are required for playback.\\nShould Unreal Tournament Demo Manager attempt to download needed files from master servers?"
	LocDemoCannotPlaySuffix5="is missing files that are required for playback.\\nIf you wish to download needed files for this demo, please abort current download"
	LocCannotRecordADemoTitle="ERROR!"
	LocCannotRecordADemoMessage="Cannot record a demo in the entry level."
	LocFailedToRemoveTitle="WARNING!"
	LocFailedToRemoveMessagePrefix="FAILED TO REMOVE"
	LocFailedToRemoveMessageSuffix="Be sure that you are not currently playing this demo."
	LocRenameDemoTitle="Rename Demo"
	LocDemoSummarySuccessTitle="SUCCESS!"
	LocDemoSummarySuccessPrefix="Saved Demo Summary as"
	LocDemoSummarySuccessSuffix=""
	LocDemoSummaryErrorTitle="Unknown Error"
	LocDemoSummaryErrorMessage="Could not write demo summary."
	LocDeleteDemoTitle="Confirm delete"
	LocDeleteDemoMessagePrefix="Are you sure you want to remove"
	LocDeleteDemoMessageSuffix="permanently?"
	LocThirdPersonAlwaysTrue="3rd person mode is always true when recorded on a dedicated server"
}
