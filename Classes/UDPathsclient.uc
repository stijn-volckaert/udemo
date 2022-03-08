// =============================================================================
// UT Demo Manager v3.4
// Originally written by UsAaR33
// Project continued by AnthraX after v3.0
// =============================================================================
// udemo.UDPathsclient: options for the directories where demos are stored + recording path
// =============================================================================
class UDPathsclient expands UMenuPageWindow;

// =============================================================================
// Variables
// =============================================================================
var UWindowEditControl Paths[5];
var UWindowCheckBox RecordPath[5];
var UWindowLabelControl BaseDir;
var localized string Empty;
var localized string LocBaseDirectory;
var localized string LocDemoPaths;
var localized string LocRecordingDir;
var localized string LocDemFilesAreStoredHelp;
var localized string LocShouldDemosBeRecorded;

// =============================================================================
// Created
// =============================================================================
function Created()
{
    local int i;
    local bool bOneSet;
    local int ControlOffset;
    local int CenterWidth, CenterPos, CenterWidth2, CenterPos2;
    local UWindowLabelControl path, rec;

    Super.Created();

    //new stuff from that d00d
    CenterWidth2  = WinWidth - 5;                //(WinWidth/8)*7; //combo width
    CenterWidth   = (WinWidth - 30)/2;           //button width
    CenterPos     = 5;                           //(WinWidth - CenterWidth)/2;
    CenterPos2    = WinWidth - CenterWidth - 10; //right position for button
    ControlOffset = 10;

    path = UWindowLabelControl(CreateControl(class'UWindowLabelControl', CenterPos, ControlOffset, CenterWidth2, 1));
    path.Align = TA_Left;
    path.setfont(F_Bold);
    path.SetText(LocBasedDirectory);
    ControlOffset += 15;

    BaseDir = UWindowLabelControl(CreateControl(class'UWindowLabelControl', CenterPos, ControlOffset, CenterWidth2, 1));
    BaseDir.Align = TA_Left;
    BaseDir.SetText(DemoMainClientWindow(GetParent(class'DemoMainClientWindow')).UserWindow.DemReader.BasePath());
    ControlOffset += 20;

    path = UWindowLabelControl(CreateControl(class'UWindowLabelControl', CenterPos, ControlOffset, CenterWidth2, 1));
    path.SetFont( F_Bold );
    path.SetText(LocDemoPaths);

    rec = UMenuLabelControl(CreateWindow(class'UMenuLabelControl', CenterPos - 8, ControlOffset,CenterWidth2, 1));
    rec.Align = TA_Right;
    rec.SetFont( F_Bold );
    rec.SetText(LocRecordingDir);
    ControlOffset += 15;

    //generate stuff:
    for (i=0; i<5; i++)
    {
        Paths[i] = UWindowEditControl(CreateControl(class'UWindowEditControl',CenterPos, ControlOffset, CenterWidth2 - 35, 1));
        Paths[i].editboxwidth=0.9*Paths[i].winwidth;
        paths[i].SetFont( F_Normal );
        Paths[i].Align = TA_Left;
        Paths[i].SetDelayedNotify(true);
        Paths[i].SetValue(class'DemoSettings'.default.DemoPaths[i]);

        if (class'DemoSettings'.default.DemoPaths[i] != Empty)
            bOneSet=true;

        Paths[i].SetText("#"$i+1);
        Paths[i].SetHelpText(LocDemFilesAreStoredHelp);
        RecordPath[i]=UWindowCheckBox(CreateControl(class'UWindowCheckBox', WinWidth - 56 , ControlOffset+1, 50, 1));
        RecordPath[i].bdisabled=(Paths[i].GetValue()==Empty);
        RecordPath[i].SetHelpText(LocShouldDemosBeRecorded);
        ControlOffset += 20;
    }

    //delete me!
    RecordPath[class'demosettings'.default.RecordingDir].bchecked = true;

    if (!bOneSet)
    {
        Paths[0].SetValue(DemoMainClientWindow(GetParent(class'DemoMainClientWindow')).UserWindow.DemReader.BasePath());
        class'DemoSettings'.default.DemoPaths[0]=Paths[0].GetValue();
    }

    DemoMainClientWindow(GetParent(class'DemoMainClientWindow')).UserWindow.Refresh(true); //do it here.
}

// =============================================================================
// CheckSomePath ~ Check a non-disabled record path
// =============================================================================
function CheckSomePath()
{
    local int i;

    for (i=0;i<5;i++)
    {
        if (!RecordPath[i].bdisabled)
        {
            RecordPath[i].bchecked=true;
            return;
        }
    }
    RecordPath[0].bchecked=true; //this one...
}

// =============================================================================
// Notify ~ Fix illegal paths! works on linux
// =============================================================================
function Notify(UWindowDialogControl C, byte E)
{
    local int i, j;
    local string str, str2;
    local bool bLinux;
    local string PathSeperator;
	local string FirstChar;

    Super.Notify(C, E);

    if (!DemoMainClientWindow(GetParent(class'DemoMainClientWindow')).bInitialized)
        return;

	FirstChar = Left(DemoMainClientWindow(GetParent(class'DemoMainClientWindow')).UserWindow.DemReader.BasePath(), 1);
    if (FirstChar == "\\" || 
	   FirstChar == "/" ||
	   FirstChar == "~")
    {
        bLinux = true;
        PathSeperator = "/";
    }
    else
    {
        PathSeperator = "\\";
    }

    switch(E)
    {
        case DE_Change:    //combo
            if (C.IsA('UWindowEditControl'))
            {
                C.NotifyWindow=none; //or else infinite iterator.

                for (i=0;i<5;i++)
                    if (Paths[i]==C)
                        break;

                if (Paths[i].GetValue()==""||Paths[i].GetValue()~=Empty)
                {
                    Paths[i].SetValue(Empty);
                    RecordPath[i].bdisabled=true;
                    if (RecordPath[i].bchecked)
                    {
                        RecordPath[i].bchecked=false;
                        CheckSomePath();
                    }
                }
                else
                {
                    RecordPath[i].bdisabled=false;

                    Str=Paths[i].GetValue();

                    for (j = 0; j<Len(Str); j++)
                    {
                        //USE reads bad!              Note that ":" is legal dir path, just not legal file name.
                        if (InStr("*?<>\"|", Mid(str, j, 1)) != -1)
                            continue;
                        else if (InStr("/", Mid(str, j, 1)) != -1 && !bLinux)
                            str2 = str2 $ PathSeperator;
                        else
                            str2 = str2 $ Mid(str, j, 1);
                    }

                    if (Right(Str2,1) != PathSeperator)
                        Str2 = Str2 $ PathSeperator;

                    if (left(Str2,1) == PathSeperator && !bLinux) //force .. in front
                        Str2 = ".." $ Str2;

                    for (j = 0; j<5; j++)    //detect similar.
                    {
                        if (J!=I && Paths[j].GetValue()~=Str2)
                        {
                            Str2=empty;
                            RecordPath[i].bdisabled = true;
                            if (RecordPath[i].bchecked)
                            {
                                RecordPath[i].bchecked=false;
                                CheckSomePath();
                            }
                        }
                    }

                    Paths[i].SetValue(Str2);
                }
                C.NotifyWindow=self;
                return;
            }

            if (!C.IsA('UWindowCheckBox')||UWindowCheckBox(C).bdisabled)
                return;

            for (i=0;i<5;i++)
                if (RecordPath[i]==C)
                    break;

            if (i==5) //???
                return;

            if (!recordPath[i].bchecked)
            { //no unchecking!
                RecordPath[i].bchecked=true;
                return;
            }

            for (j=0;j<5;j++)
                if (J!=I&&RecordPath[j].bchecked)
                {
                    RecordPath[j].bchecked=false;
                    break;
                }

            class'DemoSettings'.default.RecordingDir=I;
            break;
    }
}

// =============================================================================
// WindowHidden ~ Ensure one path is set
// =============================================================================
function WindowHidden()
{
    local int i;
    local bool bOneSet;

    Super.WindowHidden();

    if (!DemoMainClientWindow(GetParent(class'DemoMainClientWindow')).bInitialized)
        return;

    for (i=0; i<5; i++)
    {
        Notify(Paths[i],DE_Change); //force update stuff.

        if (Paths[i].GetValue()~=Empty||Paths[i].GetValue()=="")
            Paths[i].SetValue(Empty);
        if (Paths[i].GetValue()!=Empty)
            bOneSet=true;
        class'DemoSettings'.default.DemoPaths[i]=Paths[i].GetValue();
    }

    if (!bOneSet)
    {
        Paths[0].SetValue(DemoMainClientWindow(GetParent(class'DemoMainClientWindow')).UserWindow.DemReader.BasePath());
        class'DemoSettings'.default.DemoPaths[0]=Paths[0].GetValue();
        RecordPath[0].bchecked=true;
        Notify(RecordPath[0],DE_Change);
    }

    DemoMainClientWindow(GetParent(class'DemoMainClientWindow')).UserWindow.Refresh(); //in case path swap...
}

// =============================================================================
// defaultproperties
// =============================================================================
defaultproperties
{
  Empty="Empty"
  LocBasedDirectory="Base directory:"
  LocDemoPaths="Demo Paths:"
  LocRecordingDir="Recording Dir?"
  LocDemFilesAreStoredHelp="Enter in the directory path where .dem files are stored."
  LocShouldDemosBeRecorded="Should demos be recorded into this directory?"
}
