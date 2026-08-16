// =============================================================================
// UT Demo Manager v3.4
// Originally written by UsAaR33
// Project continued by AnthraX after v3.0
// =============================================================================
// udemo.UDPlaybackClient: contents of the floating playback panel. Holds the
// timeline plus the controls for everything one usually needs while watching a
// demo: pausing, seeking, speed, camera and hud.
// =============================================================================
class UDPlaybackClient expands UWindowDialogClientWindow;

var UDSeekBar               SeekBar;
var UWindowSmallButton      BRestart, BBack30, BBack5, BPlay, BFwd5, BFwd30;
var UWindowSmallButton      BSpeed[6];
var UWindowHSliderControl   SpeedSlider, AccelSlider;
var UWindowSmallButton      BFree, BRecorder, BFirst, BNext, BFlags, BStats;
var UWindowCheckbox         CBehind, CScores, CHideHUD;
var UWindowComboControl     ModeCombo;
var UWindowEditControl      GotoEdit;
var UWindowSmallButton      BGoto;

var float SpeedPreset[6];
var float CheckRowY;        // checkboxes are sized to their text, which needs a canvas
var bool  bUpdating;        // set while the controls are refreshed from the driver

var localized string LocRestart, LocRestartHelp;
var localized string LocBack30, LocBack5, LocFwd5, LocFwd30, LocStepHelp;
var localized string LocPlay, LocPause, LocPlayHelp;
var localized string LocSpeedText[6];
var localized string LocSpeed, LocSpeedHelp;
var localized string LocAccel, LocAccelHelp;
var localized string LocFree, LocFreeHelp;
var localized string LocRecorder, LocRecorderHelp;
var localized string LocFirst, LocFirstHelp;
var localized string LocNext, LocNextHelp;
var localized string LocFlags, LocFlagsHelp;
var localized string LocStats, LocStatsHelp;
var localized string LocBehind, LocScores, LocHideHUD;
var localized string LocMode, LocModeHelp;
var localized string LocModeTimeBased, LocModeFrameBased, LocModeNoCap;
var localized string LocGoto, LocGotoHelp, LocGotoButton;

// =============================================================================
// Created ~ Build the controls. Positioning happens in LayoutControls
// =============================================================================
function Created()
{
	local int i;

	Super.Created();

	SeekBar = UDSeekBar(CreateWindow(class'UDSeekBar', 0, 0, 100, 20));
	SeekBar.Panel = Self;

	BRestart = NewButton(LocRestart, LocRestartHelp);
	BBack30  = NewButton(LocBack30, LocStepHelp);
	BBack5   = NewButton(LocBack5, LocStepHelp);
	BPlay    = NewButton(LocPause, LocPlayHelp);
	BFwd5    = NewButton(LocFwd5, LocStepHelp);
	BFwd30   = NewButton(LocFwd30, LocStepHelp);

	SpeedSlider = UWindowHSliderControl(CreateControl(class'UWindowHSliderControl', 0, 0, 100, 1));
	SpeedSlider.SetRange(5, 400, 5);
	SpeedSlider.Align = TA_Left;
	SpeedSlider.SetHelpText(LocSpeedHelp);

	for (i = 0; i < ArrayCount(BSpeed); i++)
		BSpeed[i] = NewButton(LocSpeedText[i], LocSpeedHelp);

	AccelSlider = UWindowHSliderControl(CreateControl(class'UWindowHSliderControl', 0, 0, 100, 1));
	AccelSlider.SetRange(25, 800, 25);
	AccelSlider.Align = TA_Left;
	AccelSlider.SetHelpText(LocAccelHelp);

	BFree     = NewButton(LocFree, LocFreeHelp);
	BRecorder = NewButton(LocRecorder, LocRecorderHelp);
	BFirst    = NewButton(LocFirst, LocFirstHelp);
	BNext     = NewButton(LocNext, LocNextHelp);
	BFlags    = NewButton(LocFlags, LocFlagsHelp);
	BStats    = NewButton(LocStats, LocStatsHelp);

	CBehind  = NewCheckbox(LocBehind);
	CScores  = NewCheckbox(LocScores);
	CHideHUD = NewCheckbox(LocHideHUD);

	ModeCombo = UWindowComboControl(CreateControl(class'UWindowComboControl', 0, 0, 100, 1));
	ModeCombo.SetButtons(True);
	ModeCombo.SetEditable(False);
	ModeCombo.Align = TA_Left;
	ModeCombo.SetText(LocMode);
	ModeCombo.SetHelpText(LocModeHelp);
	ModeCombo.AddItem(LocModeTimeBased);   // matches DemoInterface.PlayBackMode
	ModeCombo.AddItem(LocModeFrameBased);
	ModeCombo.AddItem(LocModeNoCap);

	GotoEdit = UWindowEditControl(CreateControl(class'UWindowEditControl', 0, 0, 100, 1));
	GotoEdit.Align = TA_Left;
	GotoEdit.SetText(LocGoto);
	GotoEdit.SetHelpText(LocGotoHelp);

	BGoto = NewButton(LocGotoButton, LocGotoHelp);

	LayoutControls();
}

function UWindowSmallButton NewButton(string Text, string Tip)
{
	local UWindowSmallButton B;

	B = UWindowSmallButton(CreateControl(class'UWindowSmallButton', 0, 0, 40, 16));
	B.SetText(Text);
	B.SetHelpText(Tip);
	B.ToolTipString = Tip;
	return B;
}

function UWindowCheckbox NewCheckbox(string Text)
{
	local UWindowCheckbox B;

	B = UWindowCheckbox(CreateControl(class'UWindowCheckbox', 0, 0, 100, 16));
	B.SetText(Text);
	B.Align = TA_Right;   // box on the left, label right next to it
	return B;
}

// Place a checkbox at X and return where the next one starts
function float PlaceCheckbox(Canvas C, UWindowCheckbox B, float X, float Y)
{
	local float W, H;

	C.Font = Root.Fonts[B.Font];
	TextSize(C, B.Text, W, H);
	Place(B, X, Y, W + 18, 16);

	return X + W + 32;
}

function Place(UWindowWindow W, float X, float Y, float NewWidth, float NewHeight)
{
	W.WinLeft = X;
	W.WinTop = Y;
	W.SetSize(NewWidth, NewHeight);
}

function Resized()
{
	Super.Resized();
	LayoutControls();
}

// =============================================================================
// LayoutControls ~ Fit everything into the current client size
// =============================================================================
function LayoutControls()
{
	local float M, CW, Y, BW;
	local int i;

	if (SeekBar == None)
		return;

	M = 5;
	CW = WinWidth - 2*M;
	Y = M;

	Place(SeekBar, M, Y, CW, 20);
	Y += 24;

	BW = (CW - 5*4)/6;
	Place(BRestart, M,                Y, BW, 16);
	Place(BBack30,  M + (BW + 4),     Y, BW, 16);
	Place(BBack5,   M + 2*(BW + 4),   Y, BW, 16);
	Place(BPlay,    M + 3*(BW + 4),   Y, BW, 16);
	Place(BFwd5,    M + 4*(BW + 4),   Y, BW, 16);
	Place(BFwd30,   M + 5*(BW + 4),   Y, BW, 16);
	Y += 20;

	Place(SpeedSlider, M, Y, CW, 14);
	SpeedSlider.SliderWidth = CW*0.6;
	Y += 18;

	for (i = 0; i < ArrayCount(BSpeed); i++)
		Place(BSpeed[i], M + i*(BW + 4), Y, BW, 16);
	Y += 20;

	Place(AccelSlider, M, Y, CW, 14);
	AccelSlider.SliderWidth = CW*0.6;
	Y += 18;

	Place(BFree,     M,              Y, BW, 16);
	Place(BRecorder, M + (BW + 4),   Y, BW, 16);
	Place(BFirst,    M + 2*(BW + 4), Y, BW, 16);
	Place(BNext,     M + 3*(BW + 4), Y, BW, 16);
	Place(BFlags,    M + 4*(BW + 4), Y, BW, 16);
	Place(BStats,    M + 5*(BW + 4), Y, BW, 16);
	Y += 20;

	CheckRowY = Y;   // the checkboxes themselves are placed in BeforePaint
	Y += 20;

	BW = (CW - 8)/2;
	Place(ModeCombo, M, Y, BW, 14);
	ModeCombo.EditBoxWidth = BW*0.62;
	Place(GotoEdit, M + BW + 8, Y, BW - 44, 14);
	GotoEdit.EditBoxWidth = (BW - 44)*0.62;
	Place(BGoto, M + CW - 40, Y, 40, 16);
}

// =============================================================================
// Playback helpers. All times are seconds counted from the start of playback,
// which is what DemoPlaybackSpec.SeekToTime expects.
// =============================================================================
function DemoPlaybackSpec GetSpec()
{
	local DemoPlaybackSpec S;

	S = DemoPlaybackSpec(GetPlayerOwner());
	if (S == None || S.Driver == None)
		return None;
	return S;
}

function float PlayLength()
{
	local DemoPlaybackSpec S;

	S = GetSpec();
	if (S == None)
		return 1.0;
	return FMax(1.0, S.Driver.GetTotalTime() - S.Driver.GetStartTime());
}

function float PlayPos()
{
	local DemoPlaybackSpec S;

	S = GetSpec();
	if (S == None)
		return 0.0;
	return FClamp(S.Driver.GetCurrentTime() - S.Driver.GetStartTime(), 0.0, PlayLength());
}

function SeekPos(float T)
{
	local DemoPlaybackSpec S;

	S = GetSpec();
	if (S == None)
		return;

	// GotoFrame ignores anything below the initial timestamp or past the end
	S.SeekToTime(FClamp(T, S.Driver.GetStartTime(), PlayLength() - 1.0));
}

function SeekFraction(float F)
{
	SeekPos(F * PlayLength());
}

function SeekRelative(float Delta)
{
	SeekPos(PlayPos() + Delta);
}

function string SpeedString(float V)
{
	local string S;
	local int P;

	S = string(V);
	P = InStr(S, ".");
	if (P != -1)
		S = Left(S, P + 3);
	return S $ "x";
}

// =============================================================================
// BeforePaint ~ Mirror the driver state into the controls
// =============================================================================
function BeforePaint(Canvas C, float X, float Y)
{
	local DemoPlaybackSpec S;
	local float Len, Pos, CheckX;

	Super.BeforePaint(C, X, Y);

	CheckX = PlaceCheckbox(C, CBehind, 5, CheckRowY);
	CheckX = PlaceCheckbox(C, CScores, CheckX, CheckRowY);
	PlaceCheckbox(C, CHideHUD, CheckX, CheckRowY);

	S = GetSpec();
	if (S == None)
		return;

	Len = PlayLength();
	Pos = PlayPos();

	SeekBar.Progress = Pos/Len;
	SeekBar.TimeText = class'DemoSettings'.static.parseTime(Pos) $ " / " $ class'DemoSettings'.static.parseTime(Len);
	if (SeekBar.Marker >= 0.0)
		SeekBar.TimeText = SeekBar.TimeText @ "->" @ class'DemoSettings'.static.parseTime(SeekBar.Marker*Len);

	bUpdating = True;

	if (S.Driver.IsPaused() == 2)
		BPlay.SetText(LocPlay);
	else
		BPlay.SetText(LocPause);

	SpeedSlider.SetText(LocSpeed @ SpeedString(S.Driver.MySpeed));
	if (!SpeedSlider.bSliding)
		SpeedSlider.SetValue(S.Driver.MySpeed*100, True);

	AccelSlider.SetText(LocAccel @ SpeedString(FMax(S.AccelFactor, 0.01)));
	if (!AccelSlider.bSliding)
		AccelSlider.SetValue(FMax(S.AccelFactor, 0.01)*100, True);

	CBehind.bChecked = S.bBehindView;
	CScores.bChecked = S.bShowScores;
	if (ChallengeHUD(S.myHUD) != None)
		CHideHUD.bChecked = ChallengeHUD(S.myHUD).bHideHUD;

	if (ModeCombo.GetSelectedIndex() != S.Driver.PlayBackMode)
		ModeCombo.SetSelectedIndex(S.Driver.PlayBackMode);

	bUpdating = False;
}

// =============================================================================
// Notify ~ Control notification
// =============================================================================
function Notify(UWindowDialogControl C, byte E)
{
	local DemoPlaybackSpec S;
	local int i;

	Super.Notify(C, E);

	if (bUpdating)
		return;

	S = GetSpec();
	if (S == None)
		return;

	switch (E)
	{
		case DE_Click:
			for (i = 0; i < ArrayCount(BSpeed); i++)
				if (C == BSpeed[i])
				{
					S.SloMo(SpeedPreset[i]);
					return;
				}

			switch (C)
			{
				case BRestart:
					SeekPos(0);
					break;

				case BBack30:
					SeekRelative(-30);
					break;

				case BBack5:
					SeekRelative(-5);
					break;

				case BPlay:
					S.Driver.PauseDemo(S.Driver.IsPaused() != 2);
					break;

				case BFwd5:
					SeekRelative(5);
					break;

				case BFwd30:
					SeekRelative(30);
					break;

				case BFree:
					S.Spectate();
					break;

				case BRecorder:
					S.ViewRecorder();
					break;

				case BFirst:
					S.FirstPerson();
					break;

				case BNext:
					S.ViewPlayerNum(-1);
					break;

				case BFlags:
					S.FindFlags();
					break;

				case BStats:
					S.ToggleStats();
					break;

				case BGoto:
					S.SeekTo(GotoEdit.GetValue());
					break;
			}
			break;

		case DE_Change:
			switch (C)
			{
				case SpeedSlider:
					S.SloMo(SpeedSlider.GetValue()/100.0);
					break;

				case AccelSlider:
					S.SetAccel(AccelSlider.GetValue()/100.0);
					break;

				case CBehind:
					S.BehindView(CBehind.bChecked);
					break;

				case CScores:
					S.bShowScores = CScores.bChecked;
					break;

				case CHideHUD:
					if (ChallengeHUD(S.myHUD) != None)
						ChallengeHUD(S.myHUD).bHideHUD = CHideHUD.bChecked;
					break;

				case ModeCombo:
					S.PlayBack(ModeCombo.GetSelectedIndex());
					break;
			}
			break;

		case DE_EnterPressed:
			if (C == GotoEdit)
				S.SeekTo(GotoEdit.GetValue());
			break;
	}
}

defaultproperties
{
	SpeedPreset(0)=0.100000
	SpeedPreset(1)=0.250000
	SpeedPreset(2)=0.500000
	SpeedPreset(3)=1.000000
	SpeedPreset(4)=2.000000
	SpeedPreset(5)=4.000000
	LocSpeedText(0)="0.1x"
	LocSpeedText(1)="0.25x"
	LocSpeedText(2)="0.5x"
	LocSpeedText(3)="1x"
	LocSpeedText(4)="2x"
	LocSpeedText(5)="4x"
	LocRestart="|<"
	LocRestartHelp="Jump back to the beginning of the demo"
	LocBack30="<<30"
	LocBack5="<5"
	LocFwd5="5>"
	LocFwd30="30>>"
	LocStepHelp="Seek by the given amount of seconds"
	LocPlay="PLAY"
	LocPause="PAUSE"
	LocPlayHelp="Pause or resume playback"
	LocSpeed="Speed"
	LocSpeedHelp="Playback speed. 1x is the speed the demo was recorded at"
	LocAccel="Camera"
	LocAccelHelp="Movement speed of the free camera"
	LocFree="Free"
	LocFreeHelp="Detach the camera and fly around freely"
	LocRecorder="Recorder"
	LocRecorderHelp="View from the player who recorded the demo"
	LocFirst="1st person"
	LocFirstHelp="Lock the camera to the demo recorder's own view"
	LocNext="Next"
	LocNextHelp="View from the next player"
	LocFlags="Flags"
	LocFlagsHelp="View from the flag carrier or the flag"
	LocStats="Stats"
	LocStatsHelp="Toggle the SmartCTF stats screen"
	LocBehind="Behind view"
	LocScores="Scoreboard"
	LocHideHUD="Hide HUD"
	LocMode="Timing"
	LocModeHelp="Playback timing mode"
	LocModeTimeBased="Time based"
	LocModeFrameBased="Frame based"
	LocModeNoCap="Fast as possible"
	LocGoto="Go to"
	LocGotoHelp="Jump to a position, e.g. 90, 1:30, 50% or +15"
	LocGotoButton="GO"
}
