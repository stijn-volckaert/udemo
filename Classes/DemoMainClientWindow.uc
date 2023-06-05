// =============================================================================
// UT Demo Manager v3.4
// Originally written by UsAaR33
// Project continued by AnthraX after v3.0
// =============================================================================

// ============================================================
// udemo.DemoMainClientWindow: window that sets up entire Udemo interface.
// has FOUR subwindows inside of it. ->splitters=fun ;)
// ============================================================

class DemoMainClientWindow expands UWindowClientWindow;

var UWindowVSplitter VSplitterR, VSplitterL;  //this is what it takes to make 4 sub windows...
var UWindowHSplitter HSplitter;
var float PrevSplitPos;

//quick pointers
var UDemoScreenshotCW ScreenShot;
var PackageBasicInfoCW PBI;
var DemoList Packages;
var UDClientwindow UserWindow;

var bool bInitialized; //on init.

var localized string LocAutoRecord;
var localized string LocPaths;
var localized string LocDownloading;

function Created()
{
  local UMenuPageControl pages;
  Super.Created();

  HSplitter = UWindowHSplitter(CreateWindow(class'UWindowHSplitter', 0, 0, WinWidth+4, WinHeight));

  HSplitter.Splitpos=270;
  HSplitter.MaxSplitPos=270;

  VSplitterL = UWindowVSplitter(HSplitter.CreateWindow(class'UWindowVSplitter', 0, 0, WinWidth, WinHeight));
  VSplitterR = UWindowVSplitter(HSplitter.CreateWindow(class'UWindowVSplitter', 0, 0, WinWidth, WinHeight));

  HSplitter.LeftClientWindow = VSplitterL;
  HSplitter.RightClientWindow = VSplitterR;


  VSplitterL.Splitpos=190;
  VSplitterL.MaxSplitpos=190;

  VSplitterR.Splitpos=winwidth-272;
  VSplitterR.MaxSplitpos=VSplitterR.Splitpos;

  //remove later?
  VSplitterR.bSizable=false;
  VSplitterL.bSizable=false;
  HSplitter.bSizable=false;

  Packages=new (none) class'DemoList'; //generate list.
  Packages.SetupSentinel();

  VSplitterL.BottomClientWindow = VSplitterL.CreateWindow(class'DemoGrid', 0, 0, HSplitter.splitpos, WinHeight);

  VSplitterR.TopClientWindow = VSplitterR.CreateWindow(class'UDemoScreenshotCW', 0, 0, WinWidth, WinHeight);
  ScreenShot = UDemoScreenshotCW(VSplitterR.TopClientWindow);

  VSplitterR.BottomClientWindow = VSplitterR.CreateWindow(class'PackageBasicInfoCW', 0, 0, WinWidth-HSplitter.splitpos-7, WinHeight-VSplitterL.splitpos-7);
  PBI=PackageBasicInfoCW(VSplitterR.BottomClientWindow);

  //page control in 4th
  Pages = UMenuPageControl(VSplitterL.CreateWindow(class'UMenuPageControl', 0, 0, HSplitter.splitpos, VSplitterL.splitpos));
  Pages.SetMultiLine(true); //change?
  VSplitterL.TopClientWindow=Pages;
  UserWindow=UDClientwindow(Pages.AddPage("Start", class'UDClientwindow').Page);
  Pages.AddPage(LocAutoRecord, class'UDFeaturesClient');
  Pages.AddPage(LocPaths, class'UDPathsClient');
  Pages.AddPage(LocDownloading, class'UDNetSettingsClient');
  bInitialized=true;
}
//called when reopened:
function Refresh(){
  UserWindow.Refresh();
}
function Paint(Canvas C, float X, float Y)
{
  Super.Paint(C, X, Y);
  LookAndFeel.DrawClientArea(Self, C);
}

defaultproperties
{
	LocAutoRecord="Auto-Record"
	LocPaths="Paths"
	LocDownloading="Downloading"
}
