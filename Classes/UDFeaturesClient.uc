// =============================================================================
// UT Demo Manager v3.4
// Originally written by UsAaR33
// Project continued by AnthraX after v3.0
// =============================================================================
// udemo.UDFeaturesClient: this is only the recording each map thingy.
// =============================================================================
class UDFeaturesClient expands UMenuPageWindow;

// =============================================================================
// Variables
// =============================================================================
var UWindowEditControl Format;
var UWindowLabelControl FormatPreview;
var UWindowCheckBox GenerateInfo;
var UWindowComboControl Activate;
var UWindowCheckBox RecordWhenSpectating;

// =============================================================================
// Created ~
// =============================================================================
function Created()
{
    Super.Created();

    Activate = UWindowComboControl(CreateControl(class'UWindowComboControl', 10, 10, winwidth-18, 1));
    Activate.SetButtons(True);
    Activate.SetText("Auto-Record");
    Activate.Align = TA_Left;
    Activate.SetHelpText("Depending on the option you select, a demo will be recorded during every level with the format specified below.  Note: You must open Unreal Tournament Demo Manager every time you startup UT for this to work.");
    Activate.SetFont(F_Normal);
    Activate.SetEditable(False);
    Activate.editboxwidth=0.7*Activate.winwidth;
    Activate.additem("Never");
    Activate.AddItem("Always");
    Activate.AddItem("SinglePlayer Only");
    Activate.AddItem("MultiPlayer Only");
    Activate.SetSelectedIndex(class'DemoSettings'.default.LevelRecord);

    // (Anth) Added by request
    RecordWhenSpectating=UWindowCheckBox(CreateControl(class'UWindowCheckBox', 10, 30, winwidth-18, 1));
    RecordWhenSpectating.SetText("Record when spectating");
    RecordWhenSpectating.bchecked=class'DemoSettings'.default.bRecordWhenSpectating;
    RecordWhenSpectating.SetHelpText("If this option is activated, demos will also be auto-recorded when spectating");

    Format = UWindowEditControl(CreateControl(class'UWindowEditControl', 10, 50, winwidth-18, 1));
    Format.editboxwidth=0.7*Format.winwidth;
    Format.SetText("Record Format");
    Format.SetHelpText("Type in the format you want demos to be auto-recorded in.");
    Format.Align = TA_Left;
    Format.SetValue(class'DemoSettings'.default.Format);

    FormatPreview = UWindowLabelControl(CreateControl(class'UWindowLabelControl', 10, 70, winwidth-18, 1));
    FormatPreview.Align = TA_Center;
}

// =============================================================================
// Notify ~
// =============================================================================
function Notify(UWindowDialogControl C, byte E)
{
    local string Str, Str2;
    local int j;

    Super.Notify(C, E);

    switch(E)
    {
        case DE_Change:    //combo
            switch(C)
            {
                case Activate:
                    class'DemoSettings'.default.LevelRecord=Activate.GetSelectedIndex();
                break;
                case GenerateInfo:
                    break;
                case RecordWhenSpectating:
                    class'DemoSettings'.default.bRecordWhenSpectating=RecordWhenSpectating.bChecked;
                    class'DemoSettings'.SaveConfig();
                    break;
                case Format:
                    //check bad characters:
                    C.NotifyWindow=none;
                    Str=Format.GetValue();
                    for (j = 0; j<Len(Str); j++)
                    {
                        if (InStr("\\/*?<:>\"|", Mid(str, j, 1)) != -1)
                            continue;
                        else if (InStr(" ", Mid(str, j, 1)) != -1)
                            str2 = str2 $ "_";
                        else
                            str2 = str2 $ Mid(str, j, 1);
                    }
                    Format.SetValue(str2);
                    C.NotifyWindow=self;
                    class'DemoSettings'.default.Format=Format.GetValue();
                    break;
            }
    }
}

// =============================================================================
// Tick ~ update preview thing (so seconds stuff)
// =============================================================================
function Tick(float delta)
{
    FormatPreview.SetText("Preview: "$class'demosettings'.static.GetDemoName(GetPlayerOwner(),UWindowComboListItem(DemoMainClientWindow(GetParent(class'demomainclientwindow')).UserWindow.Demos.List.Items))$".dem");
}

// =============================================================================
// WriteText ~
// =============================================================================
function WriteText(canvas C, string text, out float Y)
{
    local float W, H;

    TextSize(C, text, W, H);
    ClipText(C, (WinWidth - W)/2, Y, text, false);
    Y+=H;
}

// =============================================================================
// Paint ~
// =============================================================================
function Paint(Canvas C, float X, float Y)
{
    Super.Paint(C,X,Y);

    //Set black:
    c.drawcolor.R=0;
    c.drawcolor.G=0;
    c.drawcolor.B=0;
    Y=FormatPreview.Wintop+FormatPreview.WinHeight-1;
    WriteText(C, "", Y);
    WriteText(C, "The following flags are replaced:", Y);
    WriteText(C, "%L - Current Level Name", Y);
    WriteText(C, "%Y - Year, %M - Month, %D - Day",  Y);
    WriteText(C, "%H - Hour, %O - Min, %S - Sec", Y);
//  WriteText(C, "%H-Hour", Y);
//  WriteText(C, "%O-Minute", Y);
//  WriteText(C, "%S-Seconds", Y);
    WriteText(C, "%V - Server Name", Y);
    WriteText(C, "%N - A number of consecutive names", Y);
    WriteText(C, "%% - The '%' symbol", Y);
}

// =============================================================================
// defaultproperties
// =============================================================================
defaultproperties
{
}