// =============================================================================
// UT Demo Manager v3.4
// Originally written by UsAaR33
// Project continued by AnthraX after v3.0
// =============================================================================
// udemo.PackageBasicInfoCW: This window simply displays basic information:
// bonus packs, CSHP version, as well as changing mode of grid.
// =============================================================================
class PackageBasicInfoCW expands UMenuDialogClientWindow;

// =============================================================================
// Variables
// =============================================================================
var bool                UsesBp1;    // Demo uses bonuspack 1?
var bool                Bp1INS;     // Bonuspack 1 installed by viewer?
var bool                UsesBP4;    // Demo uses bonuspack 4?
var bool                BP4INS;     // Bonuspack 4 installed by viewer?
var bool                UsesRA;    // Demo uses rocket arena?
var bool                RAINS;     // Rocket Arena installed by viewer?
var bool                CSHPIns;    // Cheatprotection installed by viewer?
var UWindowEditControl  CSHPVer;    // Cheatprotection used by demo
var UWindowComboControl PkgSelect;  //
var localized string	LocBonusPack1Required;
var localized string	LocBonusPack4Required;
var localized string	LocInstalled;
var localized string	LocNone;
var localized string	LocCheatProtection;
var localized string	LocTableMode;
var localized string	LocTableModeHelp;
var localized string	LocTableAllRequiredPackages;
var localized string	LocTableCustomPackages;
var localized string	LocTableAllMissingPackages;

// =============================================================================
// Paint ~
// =============================================================================
function Paint(Canvas C, float X, float Y)
{
    Super.Paint(C,X,Y);

    C.Font=root.fonts[F_Normal];

    Y=4;
    WriteTextCheck(C,LocBonusPack1Required,TA_Left,Y,UsesBp1);
    WriteTextCheck(C,LocInstalled,TA_Right,Y,Bp1INS,true,!UsesBp1);

    Y+=4;
    WriteTextCheck(C,LocBonusPack4Required,TA_Left,Y,UsesBp4);
    WriteTextCheck(C,LocInstalled,TA_Right,Y,Bp4INS,true,!UsesBp4);

    Y+=4;
    WriteTextCheck(C,"Rocket Arena Required",TA_Left,Y,UsesRA);
    WriteTextCheck(C,"Installed",TA_Right,Y,RAINS,true,!UsesRA);

    Y+=4;
    CSHPVer.WinTop=Y;
    WriteTextCheck(C,LocInstalled,TA_Right,Y,CSHPIns,true,CSHPVer.GetValue()=="None");
    PkgSelect.WinTop=Y+4;
}

// =============================================================================
// Reset ~ Called on demo change
// =============================================================================
function Reset()
{
    UsesBp1 = false;
    BP1INS  = false;
    UsesBP4 = false;
    BP4INS  = false;
    UsesRA = false;
    RAINS  = false;
    CSHPINS = false;
    CSHPVer.SetValue(LocNone);
}

// =============================================================================
// WriteTextCheck ~ Draw fake checkbox
// =============================================================================
function WriteTextCheck(canvas C, string text, TextAlign Align, out float Y,
    bool bchecked, optional bool Inc, optional bool hide)
{
    local float W, H;
    local int X;

    C.DrawColor.R = 0;
    C.DrawColor.G = 0;
    C.DrawColor.B = 0;

    TextSize(C, text, W, H);

    if (!hide)
    {
        if (Align==TA_Left)
            X=5;
        else if (Align==TA_Right)
            X=WinWidth-W-20;
        else
            X=(WinWidth - W)/2;

        ClipText(C, X, Y, text, true);

        X+=W+5;  //5 inc?
        C.DrawColor.R = 255;
        C.DrawColor.G = 255;
        C.DrawColor.B = 255;

        if (bchecked)
            DrawClippedTexture( C, X, Y, Texture'ChkChecked');
        else
            DrawClippedTexture( C, X, Y, Texture'ChkUnchecked');
    }

    if (Inc)
        Y+=H;
}

// =============================================================================
// Created ~ Create controls
// =============================================================================
function Created()
{
    Super.Created();

    CSHPVer = UWindowEditControl(CreateControl(class'UWindowEditControl', 5, 50, 2*winwidth/3-10, 1));
    CSHPVer.editboxwidth=0.45*CSHPVer.winwidth;
    CSHPVer.Align = TA_Left;
    CSHPVer.SetValue(LocNone);
    CSHPVer.SetText(LocCheatProtection);
    CSHPVer.EditBox.bCanEdit=false;

    PkgSelect = UWindowComboControl(CreateControl(class'UWindowComboControl', 5, 65, winwidth-10, 1));
    PkgSelect.SetButtons(True);
    PkgSelect.SetText(LocTableMode);
    PkgSelect.Align = TA_Left;
    PkgSelect.SetHelpText(LocTableModeHelp);
    PkgSelect.SetFont(F_Normal);
    PkgSelect.SetEditable(False);
    PkgSelect.editboxwidth=0.7*PkgSelect.winwidth;
    PkgSelect.additem(LocTableAllRequiredPackages);
    PkgSelect.AddItem(LocTableCustomPackages);
    PkgSelect.AddItem(LocTableAllMissingPackages);
    PKgSelect.SetSelectedIndex(class'DemoSettings'.default.DisplayMode);
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
                case PkgSelect:
                    class'DemoSettings'.default.DisplayMode=PKgSelect.GetSelectedIndex();
                    break;
            }
    }
}

// =============================================================================
// defaultproperties
// =============================================================================
defaultproperties
{
	LocBonusPack1Required="Bonus Pack 1 Required"
	LocBonusPack4Required="Bonus Pack 4 Required"
	LocInstalled="Installed"
	LocNone="None"
	LocCheatProtection="Cheat Protection"
	LocTableMode="Table Mode"
	LocTableModeHelp="Configure what packages the demo requirements table to the left should show."
	LocTableAllRequiredPackages="All Required Packages"
	LocTableCustomPackages="Custom Packages"
	LocTableAllMissingPackages="All Missing Packages"
}
