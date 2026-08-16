// =============================================================================
// UT Demo Manager v3.4
// Originally written by UsAaR33
// Project continued by AnthraX after v3.0
// =============================================================================
// udemo.UDPlaybackClient: contents of the floating playback panel. Holds the
// timeline plus the controls for everything one usually needs while watching a
// demo: pausing, seeking, speed, camera and hud.
//
// The panel is laid out as a form: one label column on the left, the controls
// of a row start right behind their label, and groups are split by a rule.
// Everything whose width depends on text is placed in LayoutText, which runs
// from BeforePaint because measuring text needs a canvas.
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
var bool  bUpdating;         // set while the controls are refreshed from the driver

// row positions, filled in by LayoutControls
var float TransportRowY, SpeedRowY, ViewRowY, CheckRowY, BottomRowY;
var float SepY[3];

var string SpeedValue, AccelValue;   // drawn behind the sliders
var color  LabelColor;

const Margin       = 6;
const ButtonHeight = 18;
const ButtonPad    = 14;   // text width + this = button width
const ButtonGap    = 5;
const ValueColumn  = 46;   // room for "10.00x" behind a slider

var localized string LocRestart, LocRestartHelp;
var localized string LocBack30, LocBack5, LocFwd5, LocFwd30, LocStepHelp;
var localized string LocPlay, LocPause, LocPlayHelp;
var localized string LocSpeedText[6];
var localized string LocSpeed, LocSpeedHelp;
var localized string LocAccel, LocAccelHelp;
var localized string LocView;
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
// Created ~ Build the controls
// =============================================================================
function Created()
{
	local int i;

	Super.Created();

	SeekBar = UDSeekBar(CreateWindow(class'UDSeekBar', 0, 0, 100, 22));
	SeekBar.Panel = Self;

	BRestart = NewButton(LocRestart, LocRestartHelp);
	BBack30  = NewButton(LocBack30, LocStepHelp);
	BBack5   = NewButton(LocBack5, LocStepHelp);
	BPlay    = NewButton(LocPause, LocPlayHelp);
	BFwd5    = NewButton(LocFwd5, LocStepHelp);
	BFwd30   = NewButton(LocFwd30, LocStepHelp);

	SpeedSlider = NewSlider(LocSpeed, LocSpeedHelp, 5, 400, 5);
	for (i = 0; i < ArrayCount(BSpeed); i++)
		BSpeed[i] = NewButton(LocSpeedText[i], LocSpeedHelp);
	AccelSlider = NewSlider(LocAccel, LocAccelHelp, 25, 800, 25);

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
	ModeCombo.AddItem(LocModeTimeBased);   // index matches DemoInterface.PlayBackMode
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

	B = UWindowSmallButton(CreateControl(class'UWindowSmallButton', 0, 0, 40, ButtonHeight));
	B.SetText(Text);
	B.SetFont(F_Bold);
	B.SetHelpText(Tip);
	B.ToolTipString = Tip;
	return B;
}

function UWindowCheckbox NewCheckbox(string Text)
{
	local UWindowCheckbox B;

	B = UWindowCheckbox(CreateControl(class'UWindowCheckbox', 0, 0, 100, 16));
	B.SetText(Text);
	B.SetFont(F_Bold);
	B.Align = TA_Right;   // box first, label right behind it
	return B;
}

function UWindowHSliderControl NewSlider(string Text, string Tip, float MinV, float MaxV, int StepV)
{
	local UWindowHSliderControl S;

	S = UWindowHSliderControl(CreateControl(class'UWindowHSliderControl', 0, 0, 100, 1));
	S.SetRange(MinV, MaxV, StepV);
	S.Align = TA_Left;
	S.SetFont(F_Bold);
	S.SetText(Text);
	S.SetHelpText(Tip);
	return S;
}

// =============================================================================
// Layout
// =============================================================================
function Place(UWindowWindow W, float X, float Y, float NewWidth, float NewHeight)
{
	W.WinLeft = X;
	W.WinTop = Y;
	W.SetSize(NewWidth, NewHeight);
}

function float TextWidth(Canvas C, int Fnt, string S)
{
	local float W, H;

	C.Font = Root.Fonts[Fnt];
	TextSize(C, S, W, H);
	return W;
}

// Place a button sized to its own label, return where the next one starts
function float PlaceButton(Canvas C, UWindowSmallButton B, float X, float Y)
{
	Place(B, X, Y, TextWidth(C, B.Font, B.Text) + ButtonPad, ButtonHeight);
	return X + B.WinWidth + ButtonGap;
}

function float PlaceCheckbox(Canvas C, UWindowCheckbox B, float X, float Y)
{
	local float W;

	W = TextWidth(C, B.Font, B.Text);
	Place(B, X, Y, W + 18, 16);

	return X + W + 34;
}

function Resized()
{
	Super.Resized();
	LayoutControls();
}

// Vertical layout - the rows themselves are filled in by LayoutText
function LayoutControls()
{
	local float CW, Y;

	if (SeekBar == None)
		return;

	CW = WinWidth - 2*Margin;
	Y = Margin;

	Place(SeekBar, Margin, Y, CW, 22);
	Y += 22 + Margin;

	TransportRowY = Y;
	Y += ButtonHeight + Margin;

	SepY[0] = Y;
	Y += 8;

	Place(SpeedSlider, Margin, Y, CW - ValueColumn, 14);
	Y += 20;

	SpeedRowY = Y;
	Y += ButtonHeight + 4;

	Place(AccelSlider, Margin, Y, CW - ValueColumn, 14);
	Y += 20 + 2;

	SepY[1] = Y;
	Y += 8;

	ViewRowY = Y;
	Y += ButtonHeight + 4;

	CheckRowY = Y;
	Y += 16 + Margin;

	SepY[2] = Y;
	Y += 8;

	BottomRowY = Y;
}

// Horizontal layout of everything that has to be measured first
function LayoutText(Canvas C)
{
	local float CW, LabelW, X, HalfW, GoW, PlayW;
	local int i;

	CW = WinWidth - 2*Margin;

	// one shared label column keeps the rows lined up
	LabelW = TextWidth(C, F_Bold, SpeedSlider.Text);
	LabelW = FMax(LabelW, TextWidth(C, F_Bold, AccelSlider.Text));
	LabelW = FMax(LabelW, TextWidth(C, F_Bold, LocView));
	LabelW = FMax(LabelW, TextWidth(C, ModeCombo.Font, ModeCombo.Text));
	LabelW += 8;

	SpeedSlider.SliderWidth = CW - ValueColumn - LabelW;
	AccelSlider.SliderWidth = CW - ValueColumn - LabelW;

	// transport row, centred over the timeline
	PlayW = FMax(TextWidth(C, BPlay.Font, LocPlay), TextWidth(C, BPlay.Font, LocPause)) + ButtonPad;
	X = TextWidth(C, BRestart.Font, BRestart.Text) + TextWidth(C, BBack30.Font, BBack30.Text)
	  + TextWidth(C, BBack5.Font, BBack5.Text) + TextWidth(C, BFwd5.Font, BFwd5.Text)
	  + TextWidth(C, BFwd30.Font, BFwd30.Text) + 5*ButtonPad + PlayW + 5*ButtonGap;
	X = Margin + FMax(0, (CW - X)/2);

	X = PlaceButton(C, BRestart, X, TransportRowY);
	X = PlaceButton(C, BBack30, X, TransportRowY);
	X = PlaceButton(C, BBack5, X, TransportRowY);
	Place(BPlay, X, TransportRowY, PlayW, ButtonHeight);   // fixed, so the row doesn't jump on PLAY/PAUSE
	X += PlayW + ButtonGap;
	X = PlaceButton(C, BFwd5, X, TransportRowY);
	PlaceButton(C, BFwd30, X, TransportRowY);

	X = Margin + LabelW;
	for (i = 0; i < ArrayCount(BSpeed); i++)
		X = PlaceButton(C, BSpeed[i], X, SpeedRowY);

	X = Margin + LabelW;
	X = PlaceButton(C, BFree, X, ViewRowY);
	X = PlaceButton(C, BRecorder, X, ViewRowY);
	X = PlaceButton(C, BFirst, X, ViewRowY);
	X = PlaceButton(C, BNext, X, ViewRowY);
	X = PlaceButton(C, BFlags, X, ViewRowY);
	PlaceButton(C, BStats, X, ViewRowY);

	X = Margin + LabelW;
	X = PlaceCheckbox(C, CBehind, X, CheckRowY);
	X = PlaceCheckbox(C, CScores, X, CheckRowY);
	PlaceCheckbox(C, CHideHUD, X, CheckRowY);

	// bottom row: timing on the left, jump-to on the right
	HalfW = (CW - 10)/2;
	GoW = TextWidth(C, BGoto.Font, BGoto.Text) + ButtonPad;

	Place(ModeCombo, Margin, BottomRowY + 1, HalfW, 14);
	ModeCombo.EditBoxWidth = HalfW - LabelW;

	Place(BGoto, Margin + CW - GoW, BottomRowY, GoW, ButtonHeight);
	Place(GotoEdit, Margin + HalfW + 10, BottomRowY + 1, CW - HalfW - 10 - GoW - ButtonGap, 14);
	GotoEdit.EditBoxWidth = GotoEdit.WinWidth - TextWidth(C, GotoEdit.Font, GotoEdit.Text) - 8;
}

// =============================================================================
// Paint ~ Group rules, the row label of the view buttons and the slider values
// =============================================================================
function Paint(Canvas C, float X, float Y)
{
	local int i;
	local Region R;

	Super.Paint(C, X, Y);

	C.DrawColor.R = 255;
	C.DrawColor.G = 255;
	C.DrawColor.B = 255;
	R = LookAndFeel.HLine;
	for (i = 0; i < ArrayCount(SepY); i++)
		DrawStretchedTextureSegment(C, Margin, SepY[i], WinWidth - 2*Margin, R.H, R.X, R.Y, R.W, R.H, GetLookAndFeelTexture());

	C.Font = Root.Fonts[F_Bold];
	C.DrawColor = LabelColor;
	ClipText(C, SpeedSlider.WinLeft + SpeedSlider.WinWidth + ButtonGap, SpeedSlider.WinTop, SpeedValue);
	ClipText(C, AccelSlider.WinLeft + AccelSlider.WinWidth + ButtonGap, AccelSlider.WinTop, AccelValue);

	ClipText(C, Margin, ViewRowY + 3, LocView);

	C.DrawColor.R = 255;
	C.DrawColor.G = 255;
	C.DrawColor.B = 255;
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
	local float Len, Pos;

	Super.BeforePaint(C, X, Y);

	LayoutText(C);

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

	SpeedValue = SpeedString(S.Driver.MySpeed);
	if (!SpeedSlider.bSliding)
		SpeedSlider.SetValue(S.Driver.MySpeed*100, True);

	AccelValue = SpeedString(FMax(S.AccelFactor, 0.01));
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
	LabelColor=(R=0,G=0,B=0)
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
	LocRestart="|< Start"
	LocRestartHelp="Jump back to the beginning of the demo"
	LocBack30="-30s"
	LocBack5="-5s"
	LocFwd5="+5s"
	LocFwd30="+30s"
	LocStepHelp="Seek by the given amount of seconds"
	LocPlay="PLAY"
	LocPause="PAUSE"
	LocPlayHelp="Pause or resume playback"
	LocSpeed="Speed"
	LocSpeedHelp="Playback speed. 1x is the speed the demo was recorded at"
	LocAccel="Camera"
	LocAccelHelp="Movement speed of the free camera"
	LocView="View"
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
