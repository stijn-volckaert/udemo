// =============================================================================
// UT Demo Manager v3.4
// Originally written by UsAaR33
// Project continued by AnthraX after v3.0
// =============================================================================
// udemo.UDFeaturesClient: this is only the recording each map thingy.
// =============================================================================
class UDFeaturesClient expands UMenuPageWindow;

var UWindowEditControl Format;
var UWindowLabelControl FormatPreview;
var UWindowCheckBox GenerateInfo;
var UWindowComboControl Activate;
var UWindowCheckBox RecordWhenSpectating;
var localized string LocAutoRecord;
var localized string LocAutoRecordHelp;
var localized string LocAutoRecordNever;
var localized string LocAutoRecordAlways;
var localized string LocAutoRecordSPOnly;
var localized string LocAutoRecordMPOnly;
var localized string LocRecordWhenSpectating;
var localized string LocRecordWhenSpectatingHelp;
var localized string LocRecordFormat;
var localized string LocRecordFormatHelp;
var localized string LocPreview;
var localized string LocFlags;
var localized string LocFlagsLevelName;
var localized string LocFlagsYear;
var localized string LocFlagsMonth;
var localized string LocFlagsDay;
var localized string LocFlagsHour;
var localized string LocFlagsMinutes;
var localized string LocFlagsSeconds;
var localized string LocFlagsServerName;
var localized string LocFlagsConsecutiveNames;
var localized string LocFlagsSymbol;

// =============================================================================
// Created ~
// =============================================================================
function Created()
{
    Super.Created();

    Activate = UWindowComboControl(CreateControl(class'UWindowComboControl', 10, 10, winwidth-18, 1));
    Activate.SetButtons(True);
    Activate.SetText(LocAutoRecord);
    Activate.Align = TA_Left;
    Activate.SetHelpText(LocAutoRecordHelp);
    Activate.SetFont(F_Normal);
    Activate.SetEditable(False);
    Activate.editboxwidth=0.7*Activate.winwidth;
    Activate.additem(LocAutoRecordNever);
    Activate.AddItem(LocAutoRecordAlways);
    Activate.AddItem(LocAutoRecordSPOnly);
    Activate.AddItem(LocAutoRecordMPOnly);
    Activate.SetSelectedIndex(class'DemoSettings'.default.LevelRecord);

    // (Anth) Added by request
    RecordWhenSpectating=UWindowCheckBox(CreateControl(class'UWindowCheckBox', 10, 30, winwidth-18, 1));
    RecordWhenSpectating.SetText(LocRecordWhenSpectating);
    RecordWhenSpectating.bchecked=class'DemoSettings'.default.bRecordWhenSpectating;
    RecordWhenSpectating.SetHelpText(LocRecordWhenSpectatingHelp);

    Format = UWindowEditControl(CreateControl(class'UWindowEditControl', 10, 50, winwidth-18, 1));
    Format.editboxwidth=0.7*Format.winwidth;
    Format.SetText(LocRecordFormat);
    Format.SetHelpText(LocRecordFormatHelp);
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
    FormatPreview.SetText(LocPreview$class'demosettings'.static.GetDemoName(GetPlayerOwner(),UWindowComboListItem(DemoMainClientWindow(GetParent(class'demomainclientwindow')).UserWindow.Demos.List.Items))$".dem");
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
    WriteText(C, LocFlags, Y);
    WriteText(C, "%L - "$LocFlagsLevelName, Y);
    WriteText(C, "%Y - "$LocFlagsYear$", %M - "$LocFlagsMonth$", %D - "$LocFlagsDay,  Y);
    WriteText(C, "%H - "$LocFlagsHour$", %O - "$LocFlagsMinutes$", %S - "$LocFlagsSeconds, Y);
//  WriteText(C, "%H - "$LocFlagsHour, Y);
//  WriteText(C, "%O - "$LocFlagsMinutes, Y);
//  WriteText(C, "%S - "$LocFlagsSeconds, Y);
    WriteText(C, "%V - "$LocFlagsServerName, Y);
    WriteText(C, "%N - "$LocFlagsConsecutiveNames, Y);
    WriteText(C, "%% - "$LocFlagsSymbol, Y);
}

defaultproperties
{
	LocAutoRecord="Auto-Record"
	LocAutoRecordHelp="Depending on the option you select, a demo will be recorded during every level with the format specified below.  Note: You must open Unreal Tournament Demo Manager every time you startup UT for this to work."
	LocAutoRecordNever="Never"
	LocAutoRecordAlways="Always"
	LocAutoRecordSPOnly="Single-player Only"
	LocAutoRecordMPOnly="Multiplayer Only"
	LocRecordWhenSpectating="Record when spectating"
	LocRecordWhenSpectatingHelp="If this option is activated, demos will also be auto-recorded when spectating"
	LocRecordFormat="Record Format"
	LocRecordFormatHelp="Type in the format you want demos to be auto-recorded in."
	LocPreview="Preview: "
	LocFlags="The following flags are replaced:"
	LocFlagsLevelName="Current Level Name"
	LocFlagsYear="Year"
	LocFlagsMonth="Month"
	LocFlagsDay="Day"
	LocFlagsHour="Hour"
	LocFlagsMinutes="Min"
	LocFlagsSeconds="Sec"
	LocFlagsServerName="Server Name"
	LocFlagsConsecutiveNames="A number of consecutive names"
	LocFlagsSymbol="The '%' symbol"
}
