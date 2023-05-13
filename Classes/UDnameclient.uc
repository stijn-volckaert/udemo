// =============================================================================
// UT Demo Manager v3.4
// Originally written by UsAaR33
// Project continued by AnthraX after v3.0
// =============================================================================
// udemo.UDnameclient: Input a file name here.
// =============================================================================
class UDnameclient expands UWindowDialogClientWindow;

// =============================================================================
// Variables
// =============================================================================
var UWindowEditControl  NameEdit;
var UWindowMessageBox overwrite;
var DemoReader demreader;          //if !=none then this is meant for use with renamer.
var localized string LocConfirmFileOverwrite;
var localized string LocConfirmFileOverwritePrefix;
var localized string LocConfirmFileOverwriteSuffix;
var localized string LocFailedToRenameWarning;
var localized string LocFailedToRenamePrefix;
var localized string LocFailedToRenameMidfix;
var localized string LocFailedToRenameSuffix;

// =============================================================================
// Created ~
// =============================================================================
function Created()
{
    super.created();

    NameEdit = UWindowEditControl(CreateControl(class'UWindowEditControl', 10, 10, 220, 1));
    NameEdit.SetFont(F_Normal);
    NameEdit.SetNumericOnly(False);
    NameEdit.SetMaxLength(300);
    NameEdit.EditBoxWidth = 220;
    NameEdit.BringToFront();
}

// =============================================================================
// BeforePaint ~
// =============================================================================
function BeforePaint(Canvas C, float X, float Y)
{
    Super.BeforePaint(C, X, Y);

    NameEdit.WinWidth = WinWidth - 20;
    NameEdit.EditBoxWidth = WinWidth - 50;
}

// =============================================================================
// Notify ~
// =============================================================================
function Notify(UWindowDialogControl C, byte E)
{
    Super.Notify(C, E);

    if((C == UDnamewindow(ParentWindow).OKButton && E == DE_Click))
    {
        if (demreader==none)
            CheckRec();
        else
            DoRename();
    }
}

// =============================================================================
// CheckRec ~ Pre-recording checks
// =============================================================================
function CheckRec()
{
    local int i;

    i=instr(nameedit.getvalue(),".");  //check for .dem presense

    if (i!=-1)
        nameedit.editbox.value=left(nameedit.getvalue(),i);
    if (UDClientWindow(ownerwindow).demos.finditemindex(nameedit.getvalue(),true)!=-1) //prompt user.
        overwrite=MessageBox(LocConfirmFileOverwrite, LocConfirmFileOverwritePrefix$nameedit.getvalue()$LocConfirmFileOverwriteSuffix, MB_YesNo, MR_No, MR_None);
    else
        record();  //record demo
}

// =============================================================================
// DoRename ~
// =============================================================================
function DoRename()
{
    local int i;

    i=instr(nameedit.getvalue(),".");  //check for .dem presence

    if (i!=-1)
        nameedit.editbox.value=left(nameedit.getvalue(),i);
    if (demreader.rename(UDClientWindow(ownerwindow).demos.getvalue2()$UDClientWindow(ownerwindow).demos.getvalue()$".dem",UDClientWindow(ownerwindow).demos.getvalue2()$nameedit.getvalue()$".dem")) //attempt to rename
    {
        UWindowComboListItem(UDclientwindow(ownerwindow).demos.list.items).value=nameedit.getvalue();
        UDclientwindow(ownerwindow).demos.EditBox.value=nameedit.getvalue();
        UDClientWindow(ownerwindow).demos.sort(); //resort.
    }
    else
        MessageBox(LocFailedToRenameWarning, LocFailedToRenamePrefix@UDClientWindow(ownerwindow).demos.getvalue()$".dem"$LocFailedToRenameMidfix@nameedit.getvalue()$".dem\\n"$LocFailedToRenameSuffix, MB_OK, MR_OK, MR_OK);

    ParentWindow.Close();
}

// =============================================================================
// record ~
// =============================================================================
function record()
{
    if (nameedit.getvalue()!="")
    {
        ParentWindow.Close();
        ownerwindow.GetParent(class'UWindowFramedWindow').Close();
        Root.Console.CloseUWindow();
        getplayerowner().consolecommand("stopdemo"); //stop any current demo
        getplayerowner().consolecommand("demorec \""$class'DemoSettings'.static.GetRecordingDir()$nameedit.getvalue()$"\"");
    }
}

// =============================================================================
// MessageBoxDone ~ overwrite
// =============================================================================
function MessageBoxDone(UWindowMessageBox W, MessageBoxResult Result)
{
    if(Result == MR_Yes)
    {
        switch(W)
        {
            case overwrite:
                record(); //user has confirmed he wishes to over-write file.
            break;
        }
    }
}

// =============================================================================
// defaultproperties
// =============================================================================
defaultproperties
{
	LocConfirmFileOverwrite="Confirm file overwrite"
	LocConfirmFileOverwritePrefix="Are you sure you wish to overwrite "
	LocConfirmFileOverwriteSuffix="?"
	LocFailedToRenameWarning="WARNING!"
	LocFailedToRenamePrefix="FAILED TO RENAME "
	LocFailedToRenameMidfix=" to "
	LocFailedToRenameSuffix="Be sure that you are not currently playing this demo."
}
