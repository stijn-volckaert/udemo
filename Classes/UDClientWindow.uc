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
var localized string    Spechelp;      // save file size

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
    ControlOffset = 10;

    super.created();

    Ctrl_dem = UWindowLabelControl(CreateControl(class'UWindowLabelControl', CenterPos, ControlOffset, CenterWidth, 16));
    Ctrl_dem.SetFont( F_Bold );
    Ctrl_dem.SetText("Demos:");

    demreader = new class'DemoReader'; //create native reader object.
    demreader.control=DemoMainClientWindow(GetParent(class'DemoMainClientWindow'));   //link to main!

    sizelabel=UMenuLabelControl(CreateWindow(class'UMenuLabelControl', CenterPos2, ControlOffset,CenterWidth, 1));
    sizelabel.Align = TA_Right;

    //hack to use modified list class:
    OldDefault=Class'UwindowComboControl'.default.listclass;
    Class'UwindowComboControl'.default.listclass=class'UDComboList';
    ControlOffSet+=10;

    demos = UWindowComboControl(CreateControl(class'UWindowComboControl', CenterPos, ControlOffset, CenterWidth2, 1));
    Class'UwindowComboControl'.default.listclass=OldDefault;
    demos.SetButtons(True);
    demos.Align = TA_Left;
    demos.SetHelpText("Select the demo that you wish to play.");
    demos.SetFont(F_Normal);
    demos.SetEditable(False);
    demos.editboxwidth=CenterWidth2;
    ControlOffset+=20;

    Play = UWindowSmallButton(CreateControl(class'UWindowSmallButton', CenterPos2, ControlOffset, CenterWidth, 16));
    Play.SetFont(F_bold);
    Play.SetText("PLAY");
    Play.sethelptext("Click here to play the selected demo!  Note that your current game/demo will end.");

    Record = UWindowSmallButton(CreateControl(class'UWindowSmallButton', CenterPos, ControlOffset, CenterWidth, 16));
    Record.SetText("RECORD DEMO");
    Record.sethelptext("Click here to start recording a demo!");

    stopb = UWindowSmallButton(CreateControl(class'UWindowSmallButton', CenterPos, ControlOffset, CenterWidth, 16));
    stopb.SetFont(F_bold);
    stopb.SetText("STOP");
    stopb.sethelptext("Click here to stop playing/recording");
    //next buttons row
    ControlOffset+=20;

    Rename = UWindowSmallButton(CreateControl(class'UWindowSmallButton', CenterPos, ControlOffset, CenterWidth, 16));
    Rename.SetText("Rename file");
    Rename.sethelptext("Click here to rename this demo!");
//  ControlOffset+=20;

    Delete = UWindowSmallButton(CreateControl(class'UWindowSmallButton', CenterPos2, ControlOffset, CenterWidth, 16));
    Delete.SetText("Delete file");
    Delete.sethelptext("Click here to remove this demo from existance!");
    ControlOffset+=20;

    Write = UWindowSmallButton(CreateControl(class'UWindowSmallButton', CenterPos, ControlOffset, CenterWidth2, 1));
    Write.SetText("Write demo summary");
    Write.sethelptext("Click here to cause a demo summary TXT file to be written.");
    ControlOffset+=25;

    Ctrl = UWindowLabelControl(CreateControl(class'UWindowLabelControl', CenterPos, ControlOffset, CenterWidth2, 1));
    Ctrl.SetFont( F_Bold );
    Ctrl.SetText("Select additional options");
    ControlOffset+=18;

    timing = UWindowComboControl(CreateControl(class'UWindowComboControl',CenterPos, ControlOffset, CenterWidth2, 1));
    timing.SetButtons(True);
    timing.SetText("Timing");
    timing.Align = TA_Left;
    timing.SetHelpText("Configure how playback timing should occur.  Normal means FPS will slow to Recorder's, timing causes the file to be read only when enough time has passed, and Fast AS Possible causes file reading every tick.");
    timing.SetFont(F_Normal);
    timing.SetEditable(False);
    timing.editboxwidth=0.7*timing.winwidth;
    timing.additem("Frame Based (normal)");
    timing.AddItem("Time Based (?timebased)");
    timing.AddItem("Fast As possible (?noframecap)");
    timing.setselectedindex(class'DemoSettings'.default.Timing); //FIX ME! SAVED ITEM!
    ControlOffset+=19;

    Spectate=UWindowCheckBox(CreateControl(class'UWindowCheckBox', CenterPos, ControlOffset, CenterWidth2, 16));
    Spectate.SetText("3rdPerson (Spectate)");
    Spectate.SetHelpText(spechelp);
    Spectate.bChecked=Class'DemoSettings'.default.SpecDemo;
    ControlOffset+=18;
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
    local byte LastInstalled;
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
                        doDlMsg = MessageBox("Warning", "'"$demos.getvalue()$"' is using outdated versions of some files that MAY result in semi-corrupt playback.\\nShould Unreal Tournament Demo Manager attempt to download updated versions from master servers?\\n(Clicking no will play the demo immediately)", MB_YesNo, MR_No, MR_None);
                    else
                        doGenWarnMsg = MessageBox("Warning", "'"$demos.getvalue()$"' is using outdated versions of some files that MAY result in semi-corrupt playback.\\nAs a file download is currently occuring, you will need to terminate it to begin download of updated files if destired.\\nContinue to play demo without updating?", MB_YesNo, MR_No, MR_None);
                    return;

                case 2:
                    if (root.FindChildWindow(class'DownloadFramedWindow')==none)
                        doDlMsg = MessageBox("Cannot Play", "Warning: '"$demos.getvalue()$"' is using files that will cause a version mismatch with the demo.\\nShould Unreal Tournament Demo Manager attempt to download the appropriate versions from master servers?\\n(Note: this will cause exising file to be moved into cache!)", MB_YesNo, MR_No, MR_None);
                    else
                        MessageBox("Cannot Play", "Warning: '"$demos.getvalue()$"' is using files that will cause a version mismatch with the demo.\\nIf you wish to download correct files for this demo, please abort current download", MB_OK, MR_OK, MR_OK);
                    return;

                case 3:
                    MessageBox("Cannot Play", "Warning: a file '"$demos.getvalue()$"' uses will not load and udemo does not know what to do!  Please report this error to 'stidzjene@hotmail.com' immediately!", MB_OK, MR_OK, MR_OK);
                    return;

                case 4:
                    if (root.FindChildWindow(class'DownloadFramedWindow')==none)
                        doDlMsg = MessageBox("Cannot Play", "Warning: '"$demos.getvalue()$"' is missing files that are required for playback.\\nShould Unreal Tournament Demo Manager attempt to download needed files from master servers?", MB_YesNo, MR_No, MR_None);
                    else
                        MessageBox("Cannot Play", "Warning: '"$demos.getvalue()$"' is missing files that are required for playback.\\nIf you wish to download needed files for this demo, please abort current download", MB_OK, MR_OK, MR_OK);
                    return;
            }
        }

        GetParent(class'UWindowFramedWindow').Close();
        Root.Console.CloseUWindow();

        getplayerowner().consolecommand("stopdemo"); //needed?

        assembled="demoplay "$demos.getvalue2()$demos.getvalue();     //assemble command with options
        if (Spectate.bchecked)
            assembled=assembled$"?3rdperson";
        if (timing.GetSelectedIndex() == 1)
            assembled=assembled$"?timebased";
        else if (timing.GetSelectedIndex() == 2)
            assembled=assembled$"?noframecap";

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
        MessageBox("ERROR!", "Cannot record a demo in the entry level.", MB_OK, MR_OK, MR_OK);
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
        MessageBox("WARNING!", "FAILED TO REMOVE"@demos.getvalue()$".dem \\n Be sure that you are not currently playing this demo.", MB_OK, MR_OK, MR_OK);
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
    Uwindowframedwindow(temp).WindowTitle="Rename Demo";
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
                        MessageBox("SUCCESS!", "Saved Demo Summary as"@BaseDirReplace(LastDemoItem)$LastDemoItem.Value$"Info.TXT", MB_OK, MR_OK, MR_OK);
                    else
                        MessageBox("Unknown Error", "Could not write demo summary.", MB_OK, MR_OK, MR_OK);
                    break;

                case stopb:      //stop demo
                    stopb.hidewindow();
                    getplayerowner().consolecommand("stopdemo");
                    record.showwindow();
                    break;

                case Delete:
                    DeleteMSG = MessageBox("Confirm delete", "Are you sure you want to remove "$demos.getvalue()$" permanently?", MB_YesNo, MR_No, MR_None);
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

    if (Result == MR_No && LastInstalled == 1 && W == doDlMsg)
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
            Spectate.SetHelpText("3rd person mode is always true when recorded on a dedicated server");
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
}
