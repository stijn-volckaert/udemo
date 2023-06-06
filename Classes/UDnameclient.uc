// =============================================================================
// UT Demo Manager v3.4
// Originally written by UsAaR33
// Project continued by AnthraX after v3.0
// =============================================================================
// udemo.UDnameclient: Input a file name here.
// =============================================================================
class UDNameClient expands UWindowDialogClientWindow;

var UWindowEditControl  NameEdit;
var UWindowMessageBox overwrite;
var DemoReader DemReader;          //if != None then this is meant for use with renamer.
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

	i = InStr(NameEdit.GetValue(), ".");  //check for .dem presense

	if (i != -1)
		NameEdit.EditBox.Value = Left(NameEdit.GetValue(), i);
	if (UDClientWindow(OwnerWindow).demos.FindItemIndex(NameEdit.GetValue(), true) != -1) //prompt user.
		overwrite = MessageBox(LocConfirmFileOverwrite, LocConfirmFileOverwritePrefix $ 
			NameEdit.GetValue() $ LocConfirmFileOverwriteSuffix, MB_YesNo, MR_No, MR_None);
	else
		record();  //record demo
}

// =============================================================================
// DoRename ~
// =============================================================================
function DoRename()
{
	local int i;

	i = InStr(NameEdit.GetValue(), ".");  //check for .dem presence

	if (i != -1)
		NameEdit.EditBox.Value = Left(NameEdit.GetValue(), i);
	if (DemReader.Rename(UDClientWindow(OwnerWindow).demos.GetValue2() $ 
		UDClientWindow(OwnerWindow).demos.GetValue() $ ".dem", 
		UDClientWindow(OwnerWindow).demos.GetValue2() $ NameEdit.GetValue() $ ".dem")) //attempt to rename
	{
		UWindowComboListItem(UDclientwindow(OwnerWindow).demos.List.Items).Value = NameEdit.GetValue();
		UDclientwindow(OwnerWindow).demos.EditBox.Value = NameEdit.GetValue();
		UDClientWindow(OwnerWindow).demos.Sort(); //resort.
	}
	else
		MessageBox(LocFailedToRenameWarning, LocFailedToRenamePrefix @ 
			UDClientWindow(OwnerWindow).demos.GetValue() $ ".dem" $ 
			LocFailedToRenameMidfix @ NameEdit.GetValue() $ ".dem\\n" $ 
			LocFailedToRenameSuffix, MB_OK, MR_OK, MR_OK);

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
