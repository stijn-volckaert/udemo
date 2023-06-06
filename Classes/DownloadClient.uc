// =============================================================================
// UT Demo Manager v3.4
// Originally written by UsAaR33
// Project continued by AnthraX after v3.0
// =============================================================================
// udemo.DownloadClient: a rip-off of a web browser download window
// also had a log (ripped from console)
// =============================================================================
class DownloadClient expands UWindowDialogClientWindow;

var UWindowConsoleTextAreaControl eLog;
var DemoList                      PkgList;
var DemoList                      Cur;
var UwindowSmallButton            Cancel;
var UZDownloader                  Downloader;
var UZHandler                     TempSaver;        // only temporary reference to this
var bool                          bKnowExtension;   // is file extension known?
var string                        curExt;           // current extension trying..
var int                           MasterServer;     // # of master server I am on...
var byte                          DownloadType;     // 0=not installed, 1=gen update, 2=guid correct   (if true, always set lastsize to pkg size!)
var float                         UpdateTimer;
var string                        Floc;             // file location + speed
var string                        Transfered;       // received x of y (x% complete)
var string                        ETR;              // x:y remaining
var int                           LastSize;         // for guid/gen mismatch.. don't download same file!
var UWindowMessageBox             GenMismatch;
var UWindowMessageBox             BadFile;
var localized string			  LocUnknownState;
var localized string			  LocNoCurrentActivity;
var localized string			  LocConnectingToPrefix;
var localized string              LocConnectingToSuffix;
var localized string			  LocDownloadTransferOf;
var localized string			  LocDownloadTransferComplete;
var localized string			  LocDownloadTransferETR;
var localized string			  LocFullSuccessTitle;
var localized string			  LocFullSuccessMessage;
var localized string			  LocFailureTitle;
var localized string			  LocFailureMessagePrefix;
var localized string			  LocFailureMessageSuffix;
var localized string			  LocDownloadWarningTitle;
var localized string			  LocDownloadWarningMessagePrefix;
var localized string			  LocDownloadWarningMessageSuffix;
var localized string			  LocDownloadErrorTitle;
var localized string			  LocDownloadErrorMessagePrefix;
var localized string			  LocDownloadErrorMessageSuffix;
var localized string			  LocDecompressingAndSavingPrefix;
var localized string			  LocDecompressingAndSavingSuffix;
var localized string			  LocDecompressingAndSavingReceivedPrefix;
var localized string			  LocDecompressingAndSavingReceivedSuffix;
var localized string			  LocCancel;
var localized string			  LocCancelHelp;

// =============================================================================
// LMouseDown ~ Movement not allowed
// =============================================================================
function LMouseDown(float X, float Y);

// =============================================================================
// CheckCache ~ returns true if NOT to be cached!
// =============================================================================
function bool CheckCache()
{
	switch (DownLoadType)
	{
		case 0:
			return class'DemoSettings'.default.DownloadType>=1;
		case 1:
			return (cur.binstalled==1&&class'DemoSettings'.default.DownloadType==0);
		case 2:
			return true;
	}
}

// =============================================================================
// Tick ~
// =============================================================================
function Tick (float delta)
{
	UpdateTimer+=delta;
	if (UpdateTimer<0.3)
		return;
	UpdateTimer=0; //always resets timer
	DoUpdates();
}

// =============================================================================
// DoUpdates ~ update paint info
// =============================================================================
function DoUpdates()
{
	local float speed;
  
	if (Downloader==none)
	{
		Floc=LocUnknownState;
		Transfered=LocNoCurrentActivity;
		ETR="";
		return;
	}
	
	Floc=class'DemoSettings'.default.RedirectServers[MasterServer]$"/"$Cur.PackageName$curext$".uz";
	
	if (DownLoader.Downloaded<=0)
	{
		Transfered=LocConnectingToPrefix$" http://"$DownLoader.ServerAddr$LocConnectingToSuffix;
		Etr="";
		return;
	}
	
	speed=(Downloader.Downloaded/Downloader.ElapsedTime);
	Transfered=Downloader.Downloaded/1024@"kb";
	
	if (Downloader.TotalSize!=-1)
	{
		Transfered=Transfered$" "$LocDownloadTransferOf$" "$Downloader.totalSize/1024$"kb @ "$class'demosettings'.static.FloatString(speed/1024.0)$"kb/s ("$int(100*float(Downloader.Downloaded)/DownLoader.TotalSize)$"% "$LocDownloadTransferComplete$")";
		ETR=LocDownloadTransferETR$" "$class'DemoSettings'.static.parseTime((Downloader.totalSize-Downloader.Downloaded)/speed);
	}
	else
		Transfered=Transfered@"@ "$class'demosettings'.static.FloatString(speed/1024.0)@"kb/s";
}

// =============================================================================
// Paint ~ download update info
// =============================================================================
function Paint(Canvas C, float X, float Y)
{
	Super.Paint(C,X,Y);
	c.drawcolor.R=0;
	c.drawcolor.G=0;
	c.drawcolor.B=0;
	Y=5.0;
	WriteText(C, FLoc, Y);
	WriteText(C, Transfered, Y);
	WriteText(C, ETR, Y);
	DrawStretchedTexture(C, 0, WinHeight-35, WinWidth, 35, Texture'BlackTexture');
}

// =============================================================================
// xLog ~ log to the text area
// =============================================================================
function xLog(string text)
{
	log (text,'UdemoDownload'); //keep?
	eLog.AddText(text);
}

// =============================================================================
// FullSuccess ~ found all files
// =============================================================================
event FullSuccess()
{
	xlog("UT Demo Manager sucessfully downloaded all necessary files for Demo!");
	MessageBox(LocFullSuccessTitle,LocFullSuccessMessage, MB_OK, MR_OK, MR_OK);
	Close();
}

// =============================================================================
// GiveUp ~ Cannot find file at all
// =============================================================================
event GiveUp()
{
	xlog("Sorry, UT Demo Manager was unable to locate (correct version of)'"$Cur.PackageName$"'. Demo will be unable to play.");
	MessageBox(LocFailureTitle,LocFailureMessagePrefix$" '"$Cur.PackageName$"'"$LocFailureMessageSuffix, MB_OK, MR_OK, MR_OK);
	Close();
}

// =============================================================================
// setError ~
// =============================================================================
function setError (int code)
{
	switch (code)
	{
		case -1:
			xLog (class'DemoSettings'.default.RedirectServers[MasterServer]$"/"$Cur.PackageName$curext$".uz Timed out!");
			if (!bKnowExtension)
				curExt=".umx";
			break;
		case -2:
			xLog ("Critical error! Cannot find free port to bind to!  Try to close some connections");
			GiveUp();
			return;
		case -3:
			xlog("Cannot resolve '"$class'DemoSettings'.default.RedirectServers[MasterServer]$"' Please be sure that you have entered a valid server in the master servers list and that you are connected to the internet.");
			if (!bKnowExtension)
				curExt=".umx";
			break;
		case 404:
			xlog("Error 404: '"@Cur.PackageName$curext$".uz' not found on '"$class'DemoSettings'.default.RedirectServers[MasterServer]$"'.");
			break;
		default:
			xlog("Unnown Error"@code$": '"@Cur.PackageName$curext$".uz' cannot be download from '"$class'DemoSettings'.default.RedirectServers[MasterServer]$"'.");
			break;
	}

	if (Cur.bIsInt) //don't try more servers.. just give up!
		DLNextPkg();
	else if (!TryNewPlace())
		Giveup();
}

// =============================================================================
// MessageBoxDone ~
// =============================================================================
function MessageBoxDone(UWindowMessageBox W, MessageBoxResult Result)
{
	Switch (W)
	{
		case GenMismatch:
			switch(Result)
			{
				case MR_Yes:
					TempSaver.ForceSave(!CheckCache());
					SavedFile(0);
					break;
				case MR_No:
					if (!TryNewPlace())
						GiveUp();
					break;
			}
			break;
		case BadFile:
			switch(Result)
			{
				case MR_Yes:    //simply start download directly
					TempSaver=none;
					Downloader = getEntryLevel().Spawn(class'UzDownLoader');
					DownLoader.Setup (self,class'DemoSettings'.default.RedirectServers[MasterServer],Cur.PackageName$curext,Cur.PackageGUID,Cur.Generation);
					xlog ("Resolving"@class'DemoSettings'.default.RedirectServers[MasterServer]);
					DoUpdates();
					break;
				case MR_No:
					if (!TryNewPlace())
						GiveUp();
					break;
				case MR_Cancel:
					Canceled();
					break;
			}
			break;
	}
}

// =============================================================================
// DlInt ~ Attempt to download associated int file
// =============================================================================
function bool DlInt(string f)
{
	local int pos;
	local string tmp;
	local DemoList tmpList;
  
	pos = instr(f,".");
	tmp = mid(f,pos+1);
	if (!(tmp~=".u")&&!(tmp~=".utx"))
		return false; //generally no accociated int file with non-.u/.utx files
	lastsize=0;
	UDClientWindow(ParentWindow.OwnerWindow).ShotTime=1;
	curExt="";
	bKnowExtension=true;
	tmpList = new(none) class'DemoList';
	tmpList.next=cur.Next;
	tmpList.PackageName=left(f,pos);
	cur=tmplist;
	cur.bIsInt = true;
	TempSaver=none;
	Downloader = getEntryLevel().Spawn(class'UzDownLoader');
	DownLoader.Setup (self,class'DemoSettings'.default.RedirectServers[MasterServer],Cur.PackageName$curext,Cur.PackageGUID,-1);
	xlog ("Resolving"@class'DemoSettings'.default.RedirectServers[MasterServer]);
	DoUpdates();
	return true;
}

// =============================================================================
// SavedFile ~ called when file got saved
// =============================================================================
function SavedFile (int retCode)
{
	switch (retCode)
	{
		case 0:
			xLog (Cur.PackageName$curext@"Saved successfully");
			if (!Cur.bIsInt)
				Cur.bInstalled=byte(CheckCache())+1;
			if (!Cur.bIsInt&& DownloadType ==0&&class'DemoSettings'.default.DownloadType==2 && DlInt(Cur.PackageName$curext)) //try to get int file
				return;
			DlNextPkg(); //might as well keep d/loading
			break;
		case 1:
			if (DownloadType==1){
				xLog (Cur.PackageName$curext@"is an older version than the one the demo uses.  As downloading update, ignoring file.");
			if (!TryNewPlace())
				GiveUp();
			}
			else
			{
				xLog ("Warning!"@Cur.PackageName$curext@"is an older version than the one the demo uses.  Demo playback may contain errors.");
				TempSaver=Downloader.Saver;
				GenMismatch = MessageBox(LocDownloadWarningTitle, LocDownloadWarningMessagePrefix$" '"$Cur.PackageName$curext$"' "$LocDownloadWarningMessageSuffix, MB_YesNo, MR_No, MR_Yes);
			}
			break;
		case 2:
			xLog ("Warning!"@Cur.PackageName$curext@" will mismatch with demo.  Attempting to download from new location");
			if (!TryNewPlace())
				GiveUp();
			break;
		case 3:
			xLog ("Warning!"@Cur.PackageName$curext@" is invalid.");
			BadFile = MessageBox(LocDownloadErrorTitle, LocDownloadErrorMessagePrefix$" '"$Cur.PackageName$curext$"' "$LocDownloadErrorMessageSuffix, MB_YesNoCancel, MR_Cancel, MR_No);
			lastsize=0;
			break;
	}
}

// =============================================================================
// DlSuccess ~
// =============================================================================
function DlSuccess (int level)
{
	DoUpdates();
	switch (level)
	{
		Case 0: //resolved domain name
			xLog ("Connecting to:"@class'DemoSettings'.default.RedirectServers[MasterServer]);
			break;
		Case 1: //connected to server
			xLog ("Atempting to download:"@class'DemoSettings'.default.RedirectServers[MasterServer]$"/"$Cur.PackageName$curext$".uz");
			break;
		Case 2:
			if (Downloader.TotalSize == -1)
				xLog("Starting Download of:"@Cur.PackageName$curext$".uz (unknown size)");
			else if (LastSize != Downloader.TotalSize)
				xLog ("Starting Download of:" @ Cur.PackageName$curext $ ".uz (" $ Downloader.TotalSize/1024 @ "kb)");
			else
			{
				xLog(Cur.PackageName$curext $ ".uz is incorrect version.  Aborting this download");
				Downloader.destroy();
				if (!TryNewPlace())
					Giveup();
			}
			break;
		Case 3:
			xLog("Successfully downloaded:"@Cur.PackageName$curext$".uz ("$Downloader.Downloaded/1024@"kb)");
			Floc = LocDecompressingAndSavingPrefix$" '"$Cur.PackageName$curext$"' "$LocDecompressingAndSavingSuffix;
			Transfered = LocDecompressingAndSavingReceivedPrefix$Downloader.Downloaded/1024$"kb"$LocDecompressingAndSavingReceivedSuffix;
			Etr = "";
			lastsize = Downloader.Downloaded;
			break;
	}
}

// =============================================================================
// TryNewPlace ~ Try next uz server
// =============================================================================
function bool TryNewPlace()
{
	TempSaver=none;
	if (!bKnowExtension)
		switch (curExt){
		  case "":
			curExt=".u";
			break;
		  case ".u":
			curExt=".utx";
			break;
		  case ".utx":
			curExt=".uax";
			break;
		  case ".uax":
			curExt=".umx";
			break;
		  default:
			curExt=".u";
			MasterServer++;
			break;
		}
	else
		MasterServer++;
	if (MasterServer > 23 || class'DemoSettings'.default.RedirectServers[MasterServer] == "" || class'DemoSettings'.default.RedirectServers[MasterServer] ~= "(empty)")
		return false; //failed to find file!
	Downloader = getEntryLevel().Spawn(class'UzDownLoader');
	DownLoader.Setup (self,class'DemoSettings'.default.RedirectServers[MasterServer],Cur.PackageName$curext,Cur.PackageGUID,Cur.Generation);
	xlog ("Resolving"@class'DemoSettings'.default.RedirectServers[MasterServer]);
	DoUpdates();
	return true;
}

// =============================================================================
// CheckUntil ~
// =============================================================================
function bool CheckUntil(DemoList Cur){ //for below
	if (DownloadType==0)
		return Cur.bInstalled == 0;
	//1=guid, 2=generation
	return (Cur.IsMisMatch() == DownLoadType);
}

// =============================================================================
// DlNextPkg ~
// =============================================================================
function bool DlNextPkg(){
	lastsize=0;
	UDClientWindow(ParentWindow.OwnerWindow).ShotTime=1;    //force reload of shot
	do
	{
		Cur = DemoList(Cur.Next);
		if (Cur == none)
		{
			FullSuccess();
			return false; //no more entries
		}
	}
	until (CheckUntil(cur));
	bKnowExtension = InStr(Cur.PackageName,".") != -1;
	curExt = "";
	if (bKnowExtension)
		MasterServer = -1;
	else
		MasterServer = 0;
	TryNewPlace();   //should always return true
	return true;
}

// =============================================================================
// SetPkgList ~
// =============================================================================
function SetPkgList (DemoList nList, byte DlType){     //must be called after creation!
	PkgList=nList;
	Cur = nList;
	DownloadType = DLType % 4;
	DlNextPkg();
}

// =============================================================================
// Canceled ~
// =============================================================================
function Canceled(){
	if (Downloader!=none)
		Downloader.Destroy();
	xLog("Download Cancelled by user");
	ParentWindow.Close();
}

// =============================================================================
// Created ~
// =============================================================================
function Created()
{
	eLog = UWindowConsoleTextAreaControl(CreateWindow(class'UWindowConsoleTextAreaControl', 0, WinHeight-35, WinWidth, WinHeight));
	Cancel = UWindowSmallButton(CreateControl(class'UWindowSmallButton', 70, WinHeight-57, (winwidth-70)/2, 16));
	Cancel.SetFont(F_bold);
	Cancel.SetText(LocCancel);
	Cancel.sethelptext(LocCancelHelp);
}

// =============================================================================
// BeforePaint ~
// =============================================================================
function BeforePaint(Canvas C, float X, float Y)
{
	Super.BeforePaint(C, X, Y);
	eLog.SetSize(WinWidth, 35);
}

// =============================================================================
// WriteText ~
// =============================================================================
//write text:
function WriteText(canvas C, string text, out float Y)
{
	local float W, H;
	TextSize(C, text, W, H);
	ClipText(C, (WinWidth - W)/2, Y, text, false);
	Y += H;
}

// =============================================================================
// Notify ~
// =============================================================================
function Notify(UWindowDialogControl C, byte E)  //control notification.
{
	Super.Notify(C, E);

	switch(E)
	{
		case DE_Click:    //buttons
			switch(C)
			{
				case Cancel:
					Canceled();
					break;
			}
			break;
	}
}

defaultproperties
{
	LocUnknownState="Unknown State"
	LocNoCurrentActivity="No current activity"
	LocConnectingToPrefix="Connecting to"
	LocDownloadTransferOf="of"
	LocDownloadTransferComplete="complete"
	LocDownloadTransferETR="Estimated Time Remaining:"
	LocFullSuccessTitle="SUCCESS!"
	LocFullSuccessMessage="UT Demo Manager sucessfully downloaded all necessary files for Demo! :)"
	LocFailureTitle="FAILURE"
	LocFailureMessagePrefix="Sorry, UT Demo Manager was unable to locate (correct version of)"
	LocFailureMessageSuffix=". Demo will be unable to play. :("
	LocDownloadWarningTitle="Download Warning"
	LocDownloadWarningMessagePrefix="Downloaded file"
	LocDownloadWarningMessageSuffix="is an older version than the one the demo uses.  Demo playback may contain errors.\\nUse File anyway?"
	LocDownloadErrorTitle="Download Error"
	LocDownloadErrorMessagePrefix="Downloaded file"
	LocDownloadErrorMessageSuffix="may be corrupted. \\nClick Yes to attempt to redownload it, No to try a new location, or cancel to abort downloading."
	LocDecompressingAndSavingPrefix="Decompressing and Saving"
	LocDecompressingAndSavingReceivedPrefix="Received"
	LocCancel="CANCEL"
	LocCancelHelp="Clicking this button will terminate file downloading sequence."
}
