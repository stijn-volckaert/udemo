// =============================================================================
// UT Demo Manager v3.4
// Originally written by UsAaR33
// Project continued by AnthraX after v3.0
// =============================================================================

// ===============================================================
// udemo.DemoPlaybackSpec: This is a spectator class ALWAYS used for demo playback.
// has hooks to control driver for speed changes, etc.
// ===============================================================
class DemoPlaybackSpec expands CHSpectator;

// (Added by Anth) struct that contains the pawns we can cycle trough (updated during postrender!)
struct PlayerInfo
{
	var Pawn P;
	var PlayerReplicationInfo PRI;
};

var PlayerInfo PInfo[64];

// (Added by Anth)
struct FlagInfo
{
	var PlayerReplicationInfo PRI;
	var CTFFlag HasFlag;
};

var FlagInfo FI[64];

// (Added by Anth) Weaponshow fix
var Weapon oldWeap;

var DemoInterface Driver;       // not the actual driver, but the interface to control it.
var PlayerPawn PlayerLinked;    // player I am linked to for hud, etc. info.... (none in server demos!)
var PlayerPawn OldPlayerLinked; // debug only
var bool bLockOn;               // if is locked on to playerlinked!
var float oldEyeH;
var float lTs;                  // last time seconds!
var rotator LastViewRot;
var bool bInit;                 // when init!
//seeking info:
var int ViewTargetID;           // hax for restarting! foreach stuff to get back!
var int seekTick;               // delay the end of the seek!
var float SeekTime;
var bool bSeeking;              // true when seeking = ignore messages!
var bool bInitGRI;              // (Anth) did we steal GRI ref?
var bool oldPaused;             // restore pause state after seeking has finished!
var Weapon OldWeapon;           // for sound hacking!
var Ammo DummyAmmo;             // hack!
var InterCeptHud h;
var float oldltsoffset;
var Actor OldViewTarget;

// list for bOwnerNoSee actors hidden during render
var Actor HideActors[16384];
var int HideActorsCount;

// (Anth) support for following projectiles such as guided warshells	
var bool bWasFollowingProjectile;
var vector LocationBeforeProjectileLock;

var bool bShowSmartCTFScores;

// (Sp0ngeb0b) Speedup acceleration factor
var float AccelFactor;

//garf interpolation code:
var float timepassed, totaltimeR, predictiontime;
var rotator lastrotation, realtargetrotation;
var int updatetimes, pitchdiff, yawdiff, tmppitch, tmpyaw;
var float pitchrate, yawrate;

var localized string Seeking;
var localized string LocCurrentlyAt;
var localized string LocCurrentlyAtFrame;
var localized string LocDemoIsPrefix;
var localized string LocDemoIsSuffix;
var localized string LocDemoConsistsOfPrefix;
var localized string LocDemoConsistsOfSuffix;
var localized string LocDemoInitialTimestamp;
var localized string LocSmartCTFToggled;
var localized string LocCannotGoToFPSMode;
var localized string LocDemoIsNowPlayingBackPrefix;
var localized string LocDemoIsNowPlayingBackSuffix;
var localized string LocServerDemosHaveNoPlayerRecorders;

// =============================================================================
// EXEC COMMANDS:   (debug, etc.)
// =============================================================================

exec function SloMo( float T ) {
	local CHSpectator CamControl;
	local float OldSpeed;
	OldSpeed = Driver.MySpeed;
	Driver.SetSpeed(T);
	// hack for make rypelcam not dependent from changes speed
	if (class'DemoSettings'.default.bFixRypelCam)
		foreach AllActors(class'CHSpectator', CamControl)
			if (CamControl.isA('CamControl'))
				CamControl.TimerRate *= Driver.MySpeed/OldSpeed;
}

exec function CurTime() {
	clientmessage(LocCurrentlyAt$" "$Driver.GetCurrentTime()$"s");
}

exec function CurFrame() {
	clientmessage(LocCurrentlyAtFrame$" #"$Driver.GetCurrentFrame());
}

exec function TotalTime() {
	clientmessage(LocDemoIsPrefix$" "$Driver.GetTotalTime()$" "$LocDemoIsSuffix);
}

exec function TotalFrames() {
	clientmessage(LocDemoConsistsOfPrefix$" "$Driver.GetTotalFrames()$" "$LocDemoConsistsOfSuffix);
}

exec function StartTime() {
	clientmessage(LocDemoInitialTimestamp$" "$Driver.GetStartTime());
}

exec function SeekTo(string Point) {
	local float T;
	local string sign;
	T = float(Point);
	sign = Mid(Point, 0, 1);
	while (Right(Point, 1) == " ")
		Point = Mid(Point, 0, Len(Point) - 1);
	if (Right(Point, 1) == "%")
		T = Driver.GetTotalTime()*T/100.0;
	if (sign == "+" || sign == "-")
		T = FMax(0.0, Driver.GetCurrentTime() + T);
	SetSeek(T);
}

exec function FollowMyCam(bool Follow)
{
	class'DemoSettings'.default.FollowMyCam = Follow;
	class'DemoSettings'.static.StaticSaveConfig();
}

exec function TeamSay( string Msg ) {
	Say(Msg);
}

exec function Now() {
	clientmessage("Level.TimeSeconds="@Level.TimeSeconds@PlayerLinked.Level.TimeSeconds@Driver.ltsoffset@GameReplicationInfo.ElapsedTime@GameReplicationInfo.RemainingMinute@GameReplicationInfo.RemainingTime);
}

// (Added by Anth) Stats hax
exec function ToggleStats()
{
	local Actor A;
	local ScoreBoard SB;
	local Actor GRI;
	local Actor PRI;
	
	bShowSmartCTFScores = !bShowSmartCTFScores;

	foreach Level.AllActors(class'Actor',A)
	{
		if (InStr(""$A.class, ".Smart") != -1 &&
			InStr(""$A.class, "PlayerReplicationInfo") != -1)
		{
			A.Role = ROLE_Authority;
  		    A.SetPropertyText("bViewingStats", ""$bShowSmartCTFScores);
			if (A.Owner == PlayerLinked.PlayerReplicationInfo)
				PRI = A;
		}
		else if (InStr(""$A.class, ".Smart") != -1 &&
				 InStr(""$A.class, "GameReplicationInfo") != -1)
		{
			if (A.Owner == PlayerLinked || A.Owner == None)
				GRI = A;
		}
	}

	foreach Level.AllActors(class'ScoreBoard',SB)
	{
		if (InStr(""$SB.class, ".Smart") != -1)
		{
			SB.Role = ROLE_Authority;
			// SB.SetOwner(self);
			if (SB.Owner == PlayerLinked)
			{
				SB.SetPropertyText("PlayerOwner", "\""$self$"\"");
				if (GRI != none)
					SB.SetPropertyText("SCTFGame", "\""$GRI$"\"");
				if (PRI != none)
					SB.SetPropertyText("OwnerStats", "\""$PRI$"\"");
				SB.SetPropertyText("pPRI", "\""$PlayerLinked.PlayerReplicationInfo$"\"");
				SB.SetPropertyText("pTGRI", "\""$PlayerLinked.GameReplicationInfo$"\"");

				if (bShowSmartCTFScores)
					PlayerLinked.Scoring = SB;
				else
					PlayerLinked.SetPropertyText("Scoring", SB.GetPropertyText("NormalScoreBoard"));
			}
		}
	}

/*
	if (!ChallengeHUD(myHUD).ServerInfo.IsA('SmartCTFServerInfo'))
	{
		 SI = Level.Spawn(class'SmartCTFServerInfo',spec);
		 SI.PlayerOwner = self;
		 SI.SCTFGame = GRI;
		 SI.MyFonts = FontInfo(spawn(Class<Actor>(DynamicLoadObject(class'ChallengeHUD'.default.FontInfoClass, class'Class'))));
		 ChallengeHUD(myHUD).ServerInfo = SI;
	}
*/

	ClientMessage(LocSmartCTFToggled);
}

// Demo Pausing
function bool SetPause( bool bPause )
{
	if (oldPaused)
		return false;

	//check admin pause!
	Driver.PauseDemo(bPause);
	return true;
}

exec function SetPauseText(coerce string Text) {
	if (Player == None || Player.Console == None) {
		Log("SetPauseText: Active console not found.");
		return;
	}
	if (Text == "") { // restore default
		Text = Player.Console.default.PausedMessage;
	} else if (Text ~= "hide") {
		Text = " ";
	}
	Player.Console.PausedMessage = Text;
}

// Detach cam from playerlinked!
exec function Spectate()
{
	bLockOn=false;
	viewtarget=none;
}

// Attach cam to playerlinked!
exec function FirstPerson()
{
	if (PlayerLinked!=none)
		bLockOn=true;
	else
		clientmessage(LocCannotGoToFPSMode);
}

// switch playback modes (framebased, timebased, noframecap)
exec function PlayBack(byte a)
{
	Driver.SetPlayBackMode(a);
	clientmessage(LocDemoIsNowPlayingBackPrefix$" "$Driver.PlayBackMode$" "$LocDemoIsNowPlayingBackSuffix);
}

// set behindview stuff (duh?)
exec function BehindView( Bool B )
{
	if (bLockOn)
		B = false;
	bBehindView = B;
	bChaseCam = bBehindView;
	if ( ViewTarget == None )
	  bBehindView = false;
	if (PlayerLinked!=none && bLockOn)
	  PlayerLinked.bBehindView = B;
}

// hacks for deal with XConsole 3.5.0rc71 and similar, 
// which use own implementation of spectator keys handling
exec function ViewSelf()
{
	if (bLockOn)
		return;
	Super.ViewSelf();
}

exec function Fire( optional float F )
{
	if (bLockOn)
		return;
	Super.Fire(F);
}

exec function AltFire( optional float F )
{
	if (bLockOn)
		return;
	Super.AltFire(F);
}

exec function Say( string Msg )
{
	if (left(Msg,1) == "#")
	{
		Msg = right(Msg,len(Msg)-1);
		ClearProgressMessages();
		SetProgressTime(6);
		SetProgressMessage(Msg,0);
		return;
	}

	TeamMessage( PlayerReplicationInfo, Msg, 'Say', true );
	return;
}

// Lock cam on the demorecorder
exec function ViewRecorder()
{
	if (PlayerLinked!=none)
		ViewTarget=PlayerLinked;
	else
		clientmessage(LocServerDemosHaveNoPlayerRecorders);
}

// TNSe's code -> Lock cam on the last target we pointed at (with the crosshair...)
exec function FollowPlayer()
{
	local ChallengeHUD CHUD;

	if (bLockOn || ChallengeHUD(myHUD) == None)
		return;

	CHUD=challengehud(myhud);

	if ((CHUD.IdentifyTarget != None ) && (CHUD.IdentifyFadeTime > 2.0 ))
		ViewPlayer(CHUD.IdentifyTarget.PlayerName);
}

// =============================================================================
// (Edited by Anth) FindFlags ~ Switch to the next flag we can find... (Fixed for Pure7G+)
// =============================================================================

exec function FindFlags()
{
	local int i;
	local PlayerReplicationInfo LastFC, PRI, FC;
	local PlayerPawn PP;

	FC = None;
	LastFC = None;

	PP = PlayerPawn(ViewTarget);
	i = FindPlayer(PP);
	if (i != -1 && PInfo[i].PRI.HasFlag != None)
		LastFC = PInfo[i].PRI; // Player we're currently following has the flag!

	ForEach AllActors(Class'PlayerReplicationInfo', PRI)
	{
		if (CTFFlag(PRI.HasFlag) != None)
		{
			FC = PRI; // Other FC!
			if (FC != LastFC) break;
		}
	}

	if (FC == None)
	{
		ViewClass(class'CTFFlag');
	}
	else
	{
		ViewPlayer(FC.PlayerName);
	}
}

// =============================================================================
// (Edited by Anth) ViewPlayer ~ Lock the cam on player S (Fixed for Pure7G+)
// =============================================================================

exec function ViewPlayer( string S )
{
	local pawn P;
	local int i;

	for (i = 0; i < ArrayCount(PInfo); i++)
		if (PInfo[i].PRI != None && PInfo[i].PRI.PlayerName ~= S)
		{
			P = PInfo[i].P;
			break;
		}

	if (P != None)
	{
		ClientMessage(ViewingFrom @ PInfo[i].PRI.PlayerName, 'Event', true);

		if (P == self)
			ViewTarget = None;
		else
			ViewTarget = P;
	}
	else
		ClientMessage(FailedView);

	bBehindView = ViewTarget != None;   //redo this!
	if (bBehindView)
		ViewTarget.BecomeViewTarget();
}

// =============================================================================
// (Added by Anth) ViewPlayerNum ~ Rewrote function to work with Pure7G (and up?)
// =============================================================================

exec function ViewPlayerNum(optional int num)
{
	local Pawn P;
	local int i;
	local bool bTargetSet;
	
	if (bLockOn)
		return;

	bChaseCam = true;
	bBehindView = true;

	if (!PlayerReplicationInfo.bIsSpectator && !Level.Game.bTeamGame)
		return;

	if (num >= 0)
	{
		P = Pawn(ViewTarget);
		i = FindPlayer(P);
		if (P != None && i != -1 && PInfo[i].PRI.TeamID == num)
		{
			ViewTarget = None;
			bBehindView = false;
			return;
		}
		for (P = Level.PawnList; P != None; P = P.NextPawn)
		{
			i = FindPlayer(P);

			if (i != -1 && PInfo[i].PRI != None && PInfo[i].PRI.TeamID == num)
			{
				if (P != self)
				{
					ViewTarget = P;
					bBehindView = true;
				}
				return;
			}
		}
		return;
	}
	if (Role == ROLE_Authority)
	{
		// Only switch if the target's PRI class is available!
		while (!bTargetSet)
		{
			// Cycle trough the list of available pawns
			ViewClass(class'Pawn', true);
			if (ViewTarget != None)
			{
				i = FindPlayer(Pawn(ViewTarget));
				if (i != -1)
					bTargetSet = true;
			}
			else
				bTargetSet=true;
		}

		if (ViewTarget != None)
			ClientMessage(ViewingFrom @ PInfo[i].PRI.PlayerName, 'event', true);
		else
			ClientMessage(ViewingFrom @ OwnCamera, 'Event', true);
	}

	FixFOV();
}

// =============================================================================
// (Added by Sp0ngeb0b) SetAccel ~ Allows to move faster in demoplayback
// =============================================================================
exec function SetAccel(float value) { 
		AirControl   = Default.AirControl * value;
		JumpZ        = Default.JumpZ * value;
		GroundSpeed  = Default.GroundSpeed * value;
		WaterSpeed   = Default.WaterSpeed * value;
		AirSpeed     = Default.AirSpeed * value;
		AccelFactor  = value; 
}

// For some weird reason, the original FixFOV sets it to 90 sometimes, wtf is the purpose of that?
function FixFOV()
{
	FOVAngle = Default.DefaultFOV;
	DesiredFOV = Default.DefaultFOV;
	DefaultFOV = Default.DefaultFOV;
}

// =============================================================================
// (Added by Anth) FindPlayer ~ Find a pawn in the PInfo list
// =============================================================================

function int FindPlayer(Pawn P)
{
	local int i;
	for (i = 0; i < ArrayCount(PInfo); i++)
		if (PInfo[i].P == P)
			return i;
	return -1;
}

// =============================================================================
// (Added by Anth) FixPRIArray ~ Pure7G/EUT PRI/GRI Scrambling fix
// =============================================================================

function FixPRIArray()
{
	local PlayerReplicationInfo zzMyPRI;
	local GameReplicationInfo zzMyGRI;
	local int i, j;

	for (i = 0; i < ArrayCount(PInfo); i++)
	{
		PInfo[i].P = None;
		PInfo[i].PRI = None;
	}
	i = 0;

	// bleh
	if (GameReplicationInfo == None)
		foreach PlayerLinked.AllActors(class'GameReplicationInfo', zzMyGRI)
			GameReplicationInfo = zzMyGRI;

	// Pure fix
	if (GameReplicationInfo != None)
	{
		oldltsoffset = Driver.ltsoffset;
		foreach Level.AllActors(class'PlayerReplicationInfo', zzMyPRI)
		{
			if (zzMyPRI.Owner == Self)
				PlayerReplicationInfo = zzMyPRI;
			else if (zzMYPRI.Owner == PlayerLinked)
				PlayerLinked.PlayerReplicationInfo = zzMyPRI;
			
			if (zzMyPRI.Owner != None &&
				zzMyPRI.Owner.IsA('Pawn') &&
				!zzMyPRI.Owner.IsA('Spectator') &&
				Pawn(zzMyPRI.Owner).Weapon != None)
			{
				PInfo[j].P = Pawn(zzMyPRI.Owner);
				PInfo[j++].PRI = zzMyPRI;
			}

			if (zzMyPRI.Owner == None || !zzMyPRI.Owner.IsA('Spectator'))
				GameReplicationInfo.PRIArray[i++] = zzMyPRI;
		}

		// Set the rest of the array to none!
		for (i = i; i < ArrayCount(GameReplicationInfo.PRIArray); i++)
		{
			GameReplicationInfo.PRIArray[i] = none;
		}
	}
}

// =============================================================================
// (Added by Anth) BuildFlagArray - Store flag info
// =============================================================================

function BuildFlagArray()
{
	local int i, j;

	for (i = 0; i < ArrayCount(FI); i++)
	{
		FI[i].PRI = none;
		FI[i].HasFlag = none;
	}
	j = 0;

	for (i = 0; i < ArrayCount(PInfo); i++)
		if (PInfo[i].PRI != None && PInfo[i].PRI.HasFlag != None)
		{
			FI[j].PRI = PInfo[i].PRI;
			FI[j].HasFlag = CTFFlag(PInfo[i].PRI.HasFlag);
			j++;
		}
}

// =============================================================================
// (Added by Anth) RestoreFlagArray - Restore flag info
// =============================================================================

function RestoreFlagArray()
{
	local int i, j;

	for (i = 0; i < ArrayCount(FI); i++)
	{
		if (FI[i].PRI == none)
			return;

		FI[i].PRI.HasFlag = FI[i].HasFlag;
		for (j = 0; j < ArrayCount(PInfo); j++)
			if (PInfo[j].PRI == FI[i].PRI && FI[i].HasFlag != None)
			{
				FI[i].HasFlag.Holder = PInfo[j].P;
				FI[i].HasFlag.Holder.PlayerReplicationInfo = PInfo[j].PRI;
				break;
			}
	}

	for (i = 0; i < ArrayCount(PInfo); i++)
		PInfo[i].P.PlayerReplicationInfo = PInfo[i].PRI;

}

// =============================================================================
// SEEKING STUFF!
// =============================================================================

// Seek to T seconds!
function SetSeek (float T)
{
	SeekTick=2;
	SeekTime=T;
	oldPaused=(Driver.IsPaused()==2);
	if (OldPaused)
	  Driver.PauseDemo(false);
}

// Ends the seek (one tick after normal playback resumes)
function EndSeek()
{
	local pawn p;
	local ScoreBoard sb; // (Anth)

	CurTime();

	bSeeking=false;
	lts=level.timeseconds;
	SeekTick=0;

	// Restore pause state after the seek
	if (OldPaused)
	  Driver.PauseDemo(true);
	OldPaused=false;

	// Restore viewtarget after the seek!
	if (ViewTargetID!=-1)
		// Probably still relevant!
		foreach AllActors(class'pawn',p)
		{
			if (p.playerreplicationinfo!=none&&p.playerreplicationinfo.PlayerID==ViewTargetID)
			{
				ViewTarget = p;
				break; //careful!
			}
		}

	ViewTargetID=-1; //may wish to preserve!

	foreach AllActors(class'ScoreBoard',sb)
		if (sb.Owner == none)
			sb.Owner = PlayerLinked;
}

// Store playerid of current viewtarget (cam will try to relock on viewtarget after the seek)
function BackUpRefs()
{
	if (Pawn(ViewTarget) != None && Pawn(ViewTarget).PlayerReplicationInfo != None)
		ViewTargetID = Pawn(ViewTarget).PlayerReplicationInfo.PlayerID;
		
	// destroy Scoreboard spawned by us (Info actors ignore on reset demo) for recreate it after seek
	if (Scoring != None && ScoringType != None && Scoring.Role == ROLE_Authority)
	{
		Scoring.Destroy();
		Scoring = None;
	}
}

// Not used... :/
function ClearHUD() {}

function FixGRI(float DTime)
{
	local GameReplicationInfo MyGRI;

	if (GameReplicationInfo == None && PlayerLinked != None)
		foreach PlayerLinked.AllActors(class'GameReplicationInfo', MyGRI)
			GameReplicationInfo = MyGRI;
}

// =============================================================================
// GENERAL PLAYBACK FUNCTIONS!!!
// =============================================================================

state CheatFlying
{
	ignores SeePlayer, HearNoise, Bump, TakeDamage;

	function PlayerTick(float Delta)
	{
		local PlayerReplicationInfo PRI;
		local int i, FragAcc;
		local Actor Cam;
		local vector CamLoc;
		local rotator CamRot;
		
		// handle event PreTick
		if (Delta < 0)
		{
			Delta = -Delta;

			return;
		}

		if (SeekTick == 3)
			EndSeek();
		if (bSeeking)
			return;
			
		if (class'DemoSettings'.default.FollowMyCam) {
			PlayerCalcView(Cam, CamLoc, CamRot);
			if (Cam != Self) {
				SetLocation(CamLoc);
				SetRotation(CamRot);
				ViewRotation = CamRot;
			}
		}

		if (GameReplicationInfo != none)
		{
			// Keep PRIArray up to date
			for (i = 0; i < ArrayCount(GameReplicationInfo.PRIArray); i++)
				GameReplicationInfo.PRIArray[i] = None;
			i = 0;
			foreach AllActors(class'PlayerReplicationInfo', PRI)
				if (i < ArrayCount(GameReplicationInfo.PRIArray))
					GameReplicationInfo.PRIArray[i++] = PRI;

			// Update various information.
			GameReplicationInfo.UpdateTimer = 0;
			for (i = 0; i < ArrayCount(GameReplicationInfo.PRIArray); i++)
				if (GameReplicationInfo.PRIArray[i] != None)
					FragAcc += GameReplicationInfo.PRIArray[i].Score;
			GameReplicationInfo.SumFrags = FragAcc;

			if (Level.Game != None)
				GameReplicationInfo.NumPlayers = Level.Game.NumPlayers;
		}

		Super.PlayerTick(Delta);

		//seeking cr4p:
		if (SeekTick == 1)
		{
			ClearHUD();
			Driver.GotoFrame(SeekTime);
			SeekTick = 3;
			return;
		}

		if (SeekTick > 0)
			SeekTick--;

		// (Anth) Fix for broken HUD in server-side demos
		if (PlayerLinked != None && PlayerLinked.IsA('DemoRecSpectator'))
			PlayerLinked = None;

		// (Anth) Changed this so that it only steals the refs if playerlinked has changed...
		if (PlayerLinked != None && PlayerLinked != OldPlayerLinked)
		{
			OldPlayerLinked = PlayerLinked;
			StealRef();
		}
		// DLO Gameclass to get hud & sb
		else if (PlayerLinked == None && HudType == None)
			GenRef();
	}
	
	// (Sp0ngeb0b)
	function ProcessMove(float DeltaTime, vector NewAccel, eDodgeDir DodgeMove, rotator DeltaRot)	
	{
		local float OldAirSpeed, Speed;
		Acceleration = Normal(NewAccel);
		// use AirSpeed instead of hardcoded 300 and not affect by slomo command
		Speed = AirSpeed * AccelFactor;
		if (Driver.PlayBackMode != 2 && Driver.mySpeed != 0)
			Speed /= Driver.mySpeed;
		Velocity = Normal(NewAccel)*Speed;
		// AirSpeed temp alter for avoid be capped by engine physics code
		OldAirSpeed = AirSpeed;
		if (Driver.PlayBackMode != 2 && Driver.mySpeed != 0 && Driver.mySpeed < 1.0)
			AirSpeed /= Driver.mySpeed;
		AutonomousPhysics(DeltaTime);
		AirSpeed = OldAirSpeed;
	}
	
	// (Sp0ngeb0b)
	function BeginState()
	{
	  AccelFactor = 1.0;
	  super.BeginState();
	}
}

// Get inventory from PlayerLinked & take over weapon etc...
function SetPlayer (actor view, bool bItems)
{
	local Pawn PTarget;
	local inventory inv;

	PTarget = pawn(view);
	if (PTarget !=none)
	{
		//set up inv list.. kinda a hack ;p
		if (bItems)
		{
			PTarget.inventory=none;

			foreach view.ChildActors(class'Inventory',inv)
			{
				inv.inventory = PTarget.inventory;
				PTarget.inventory = inv;
			}

			for (inv=PTarget.inventory;inv!=none;inv=inv.inventory)  //find weapon ammos!
				if (Weapon(inv)!=none&&Weapon(inv).AmmoName!=none&&(Weapon(inv).AmmoType==none||Weapon(inv).AmmoType==DummyAmmo))
					Weapon(inv).AmmoType=Ammo(PTarget.FindInventoryType(Weapon(inv).AmmoName));
		}
		if (PTarget.Weapon != None )
		{
			PTarget.Weapon.role=Role_Authority;
			PTarget.Weapon.setHand(Handedness); //hack
			PTarget.Weapon.role=Role_SimulatedProxy;

			if (PlayerLinked!=none)
				PlayerLinked.TargetWeaponViewOffset = PTarget.Weapon.PlayerViewOffset; //this one is better anyway ;p
			if (PTarget.Weapon!=none&&PTarget.Weapon.AmmoName!=none&&PTarget.Weapon.AmmoType==none)
				PTarget.Weapon.AmmoType=DummyAmmo; //lame hack ;p
		}
	}
}

// Steal HUD & Scoreboard from PlayerLinked...
function StealRef()
{
	PlayerLinked.Role=ROLE_AutonomousProxy;
	if (GameReplicationInfo == none || !bInitGRI)
	{
		bInitGRI = true;
		GameReplicationInfo = PlayerLinked.GameReplicationInfo;
		GameReplicationInfo.SetTimer(0.0,false); // (Anth) Hack to disable GRI's own time updates
	}

	if (HudType==none)
		HudType = PlayerLinked.HudType;
	PlayerLinked.HudType=none; //ensure is null

	if (ScoringType==none)
		ScoringType = PlayerLinked.ScoringType;
	PlayerLinked.ScoringType=none; //set to none: utpure hack!

	if (PlayerLinked.myhud==none || PlayerLinked.myHud.class!=class'InterceptHUD')
	{
		h=spawn(class'InterceptHUD',PlayerLinked);
		h.SetOwner(PlayerLinked);
		h.Real=self;
		PlayerLinked.MyHud=h;
	}
}

// Get HUDType & ScoreBoardType by DLO'ing the gameinfo class...
function GenRef()
{
	local class<GameInfo> G;

	if (GameReplicationInfo==none)
		foreach AllActors(class'GameReplicationInfo',GameReplicationInfo)
			break;

	log("GenRef"@GameReplicationInfo);

	if (GameReplicationInfo!=none && GameReplicationInfo.GameClass!="")
	{
		G=class<GameInfo>(DynamicLoadObject(GameReplicationInfo.GameClass,class'class'));
		HudType = G.default.HudType;
		ScoringType = G.default.ScoreBoardType;
	}
}

// Hides Shieldbelt in first person and fixes weapon sounds for client weapons!
// Called from PreRender!!
function CheckFx()
{
	local Actor ChildActor;

	// Belt stuff!
	if (ViewTarget != None && !bBehindView)
		foreach ViewTarget.ChildActors(class'Actor', ChildActor)
			if (ChildActor.bOwnerNoSee && !ChildActor.bHidden && HideActorsCount < ArrayCount(HideActors))
			{
				ChildActor.bHidden = true;
				HideActors[HideActorsCount++] = ChildActor;
			}

	if (PlayerLinked==none)
		return;

	if (OldWeapon!=none)       //reset!
		OldWeapon.ambientSound=none;
		OldWeapon=none;

	if (PlayerLinked.Weapon!=none)
	{
		if (PlayerLinked.Weapon.IsA('minigun2'))
		{
			if (PlayerLinked.Weapon.AnimSequence=='Shoot1') // main
			{
				PlayerLinked.Weapon.AmbientSound=PlayerLinked.Weapon.FireSound;
				OldWeapon=PlayerLinked.Weapon;
			}
			else if (PlayerLinked.Weapon.AnimSequence=='Shoot2') // alt
			{
				PlayerLinked.Weapon.AmbientSound=PlayerLinked.Weapon.AltFireSound;
				OldWeapon=PlayerLinked.Weapon;
			}
		}
		else if (PlayerLinked.Weapon.IsA('pulsegun'))
		{
			if (PlayerLinked.Weapon.AnimSequence=='shootLOOP') // main
			{
				PlayerLinked.Weapon.AmbientSound=PlayerLinked.Weapon.FireSound;
				OldWeapon=PlayerLinked.Weapon;
			}
			else if (PlayerLinked.Weapon.AnimSequence=='BoltLoop' || (PlayerLinked.Weapon.AnimSequence == 'BoltStart') ) // alt
			{
				PlayerLinked.Weapon.AmbientSound=PlayerLinked.Weapon.AltFireSound;
				OldWeapon=PlayerLinked.Weapon;
			}
		}
		else if (PlayerLinked.Weapon.IsA('ImpactHammer'))
		{
			if (PlayerLinked.Weapon.AnimSequence == 'Shake') // main
			{
				if (!PlayerLinked.Weapon.IsInState('Pickup'))
					PlayerLinked.Weapon.GoToState('Pickup'); // fix for prevent interrupt anim by TournamentWeapon.AnimEnd
				PlayerLinked.Weapon.AmbientSound = ImpactHammer(PlayerLinked.Weapon).TensionSound;
				OldWeapon = PlayerLinked.Weapon;
			}
		}
	}
}

event PreRender( canvas Canvas )
{
	local ENetRole oldrole;
	local HUD HUD;
	
	// try use exists HUD before create new one
	if (myHud == None && HUDType != None)
		foreach AllActors(class'HUD', HUD)
			if (HUD.Class == HUDType)
			{
				myHud = HUD;
				myHud.Role = ROLE_Authority; // like we spawn it, not get from rep
				myHud.setOwner(self);
				break;
			}

	super.PreRender(Canvas);

	CheckFx();
	RestoreFlagArray(); // (Anth) new 3.3 fix

	// Used for the interpolation stuff!
	if (!bLockOn && Pawn(ViewTarget)!=none)
		Pawn(ViewTarget).ViewRotation=LastViewRot;

	// Keep cam on the player and call prerender on playerlinked (hax!)
	if (PlayerLinked!=none)
	{
		if (bLockOn)
			SetLocation(PlayerLinked.Location);
		oldRole=PlayerLinked.Role;
		PlayerLinked.Role = Role_authority;
		PlayerLinked.PreRender(Canvas);
		PlayerLinked.Role = oldRole;

		// (Added by Anth) Weaponshow hax
		// UTPure7G resets several values in bbPlayer.RenderOverlays, this
		// prevents the weapon from rendering correctly
		// => Don't let PlayerLinked.RenderOverlays do the weaponrendering
		if (PlayerPawn(ViewTarget) != None && !bBehindview)
		{
			oldWeap = PlayerPawn(ViewTarget).Weapon;
			PlayerPawn(ViewTarget).Weapon = none;

			// set viewtarget to none so the engine calls RenderOverlays on the
			// demoplaybackspec, rather than the viewtarget...

			OldViewtarget = ViewTarget;
			ViewTarget.bHidden = true;
			ViewTarget = none;	
		}
		else
		{
			OldViewtarget = none;
		}
	}
}

event RenderOverLays(Canvas Canvas)
{
	// (Added by Anth)
	local bool bWasHidden;
	local rotator CamRot;
	local vector CamLoc,newLoc,nLoc;
	local ENetRole oldRole;
	local Actor Dummy;
	local bool bFollowingProjectile;
	local Player OldPlayer;

	if (OldViewTarget != None)
	{
		ViewTarget = OldViewTarget;
		ViewTarget.bHidden = false;
	}

	// (Added by Anth) Weapon Rendering was disabled by the code in PreRender
	// This code will calculate the correct positioning of the weapon and it will
	// render a "new" weapon
	if (PlayerPawn(ViewTarget) != None && !bBehindview)
	{
		// Uber uber hack!!! This will fix the weird
		// weapon bobs that occur at high speed collisions
		PlayerPawn(ViewTarget).bCollideWorld = false;

		// Temporarily set ViewTarget.Role to ROLE_AUTHORITY. This allows us to
		// call functions that only the server can usually call
		oldRole=PlayerPawn(ViewTarget).Role;
		PlayerPawn(ViewTarget).Role=ROLE_AUTHORITY;

		// UTPure hax...
		PlayerPawn(ViewTarget).bIsPlayer=true;

		// Calculate the viewrotation of ViewTarget. UTPure will set this to 0,0,0
		// or something random... Either way, UTPure will fuck this value up...
		PlayerCalcView(Dummy,CamLoc,CamRot);
		PlayerPawn(ViewTarget).ViewRotation = CamRot;

		// Give weapon back. The weapon was set to none during PreRender
		if (PlayerPawn(ViewTarget).Weapon == None &&
			oldWeap != None)
		{
			PlayerPawn(ViewTarget).Weapon = oldWeap;
		}

		// Check if we're following a projectile such as a GuidedWarShell
		if (Projectile(PlayerPawn(ViewTarget).ViewTarget) != none)
		{
			// Follow the projectile
			NewLoc=PlayerPawn(ViewTarget).ViewTarget.Location;
			nLoc=NewLoc;
			bFollowingProjectile=true;

			// (Anth) remember viewrot. This doesn't reset automaticatically
			// when we stop following the projectile			
			if (!bWasFollowingProjectile)
			{
				bWasFollowingProjectile=true;
				LocationBeforeProjectileLock=PlayerPawn(ViewTarget).Location;
			}
		}
		else
		{		
			if (bWasFollowingProjectile)
			{
				bWasFollowingProjectile=false;
				PlayerPawn(ViewTarget).Location = LocationBeforeProjectileLock;
			}
			
			// Calculate starting location for weapon
			NewLoc=PlayerPawn(ViewTarget).Location;
			nLoc=NewLoc;

			// Adjust EyeHeight
			NewLoc+=(OldEyeH-PlayerPawn(ViewTarget).EyeHeight)*vect(0,0,1);			
		}

		// Set the location, Only if not paused!
		// Will cause camera to float away if we do it while paused as well
		if (Level != None && (Level.Pauser == "" || bFollowingProjectile)) {
			if (PlayerPawn(ViewTarget).Weapon != None) // Apply WalkBob
				NewLoc -= PlayerPawn(ViewTarget).WalkBob;
			PlayerPawn(ViewTarget).SetLocation(NewLoc);
		}

		// Reset PlayerLinked.Role
		PlayerPawn(ViewTarget).Role=oldRole;

		// The weapon hand of the player who recorded the demo is stored in the
		// demo... We don't want that. This code will get the weapon hand of the
		// player who plays the demo and apply it to the recorder's weapon
		//
		// 3.3: This seemed to lag a lot of demos... Disabled!
		PlayerPawn(ViewTarget).Handedness = Handedness;
		if (PlayerPawn(ViewTarget).Weapon != None)
		{
			if (Handedness != 2)
			{
				bWasHidden = PlayerPawn(ViewTarget).Weapon.bHideWeapon;
				PlayerPawn(ViewTarget).Weapon.bHideWeapon = false;
			}

			oldRole=PlayerPawn(ViewTarget).Weapon.Role;
			PlayerPawn(ViewTarget).Weapon.Role=ROLE_AUTHORITY;
			PlayerPawn(ViewTarget).Weapon.setHand(Handedness);
			PlayerPawn(ViewTarget).Weapon.ROle=oldRole;
		}

		// No call to ViewTarget.RenderOverLays here!!!
		if (PlayerPawn(ViewTarget).Weapon != None) {
			OldPlayer = PlayerPawn(ViewTarget).Player;
			if (OldPlayer == None)
				PlayerPawn(ViewTarget).Player = Player; // hack: Weapon.Owner.Player must be not None, for prevent clear WalkBob
			PlayerPawn(ViewTarget).Weapon.renderoverlays(canvas);
			if (OldPlayer == None)
				PlayerPawn(ViewTarget).Player = OldPlayer;
		}

		if (PlayerPawn(ViewTarget).myHUD != None)
			PlayerPawn(ViewTarget).myHUD.renderoverlays(canvas);

		// Restore loc...
		if (Level != None && (Level.Pauser == "" || bFollowingProjectile))
			PlayerPawn(ViewTarget).SetLocation(nLoc);

		// Reset bHideWeapon if needed
		if (bWasHidden)
			PlayerPawn(ViewTarget).Weapon.bHideWeapon = true;
	}
}

event PostRender( canvas Canvas )
{
	local int i;
	local float DamageTime, StatScale, X;
	local vector HitLocation, HitNormal, StartTrace, EndTrace;
	local actor Other;
	local CHSpectator CamControl;
	
	// hack for make rypelcam not dependent from changes speed
	if (class'DemoSettings'.default.bFixRypelCam)
		foreach AllActors(class'CHSpectator', CamControl)
			if (CamControl.isA('CamControl') && CamControl.TimerCounter == 0.0)
				CamControl.TimerRate *= Driver.MySpeed;

	FixPRIArray();

	// (Added by Anth) new 3.3 fix
	BuildFlagArray();

	if (HideActorsCount > 0)
	{
		for (i = 0; i < HideActorsCount; i++)
		{
			Other = HideActors[i];
			if (Other != None)
				Other.bHidden = False;
		}
		HideActorsCount = 0;
	}

	// smartctf hack
	if (bShowSmartCTFScores)
	{
		if (PlayerLinked != none && PlayerLinked.Scoring != none)
		{
			PlayerLinked.Scoring.SetPropertyText("PlayerOwner", "\""$self$"\"");
		}
	}

	if (bLockOn)
	{
		// (Added by Anth)
		if (Scoring == None && ScoringType != None)
		{
			Scoring = Spawn(ScoringType,PlayerLinked);
		if (Scoring != None)
				Scoring.OwnerHUD = myHUD;
		}

		PlayerLinked.bShowScores=bShowScores;
		PlayerLinked.ScoringType=ScoringType;
		PlayerLinked.Scoring=Scoring;
		PlayerLinked.GameReplicationInfo=GameReplicationInfo; // hax!

		if (PlayerLinked != none &&
			WarheadLauncher(PlayerLinked.Weapon) != none &&
			GuidedWarShell(PlayerLinked.ViewTarget) != none)
		{		
			WarheadLauncher(PlayerLinked.Weapon).GuidedShell = GuidedWarShell(PlayerLinked.ViewTarget);
		}

		if (myhud!=none)
			myhud.setowner(PlayerLinked);
	}
	if (PlayerLinked != None)
	{
		PlayerLinked.Player = Player;   //UNCONSTED.. CANNOT COMPILE THIS CODE WITHOUT BYTEHACKING ENGINE.U!!!
		if (ChallengeHUD(PlayerLinked.myHud) != None && PlayerLinked.myHud.PlayerOwner == None)
			ChallengeHUD(PlayerLinked.myHud).HUDSetup(Canvas);
	}

	if (!bLockOn && Pawn(ViewTarget)!=none)
		Pawn(ViewTarget).ViewRotation = TargetViewRotation;
	if (PlayerReplicationInfo != None && (bLockOn || ViewTarget!=none))
		PlayerReplicationInfo.bIsSpectator=false;

	// (Anth) Fix here
	if ( myHUD != none && ChallengeHUD(myHUD).bShowInfo && ChallengeHUD(myHUD).ServerInfo != none)
		ChallengeHUD(myHUD).ServerInfo.RenderInfo(Canvas);
	else
	{
		if (ChallengeHUD(myHUD) != none)
		{
			ChallengeHUD(myHUD).PawnOwner = PlayerLinked;
			ChallengeHUD(myHUD).PlayerOwner = PlayerLinked;
		}
		Super.PostRender(Canvas); // Call postrender on hud or create hud
	}

	//super-ugly hack!  (ADD OPTIONS???????)
	if (!bLockOn && PlayerLinked!=none && PlayerLinked==ViewTarget
	&& !PlayerLinked.PlayerReplicationInfo.bIsSpectator && ChallengeHUD(myHud)!=none
	&& !ChallengeHUD(myHud).bHideHUD && !ChallengeHUD(myHud).bHideStatus && Canvas.ClipX > 400
	&& Level.bHighDetailMode && !Level.bDropDetail)
	{
		Canvas.Style = ERenderStyle.STY_Translucent;
		StatScale = ChallengeHUD(myHud).Scale * ChallengeHUD(myHud).StatusScale;
		X = Canvas.ClipX - 128 * StatScale;

		for (i = 0; i < ArrayCount(ChallengeHUD(myHud).HitTime); i++)
		{
			DamageTime = Level.TimeSeconds - ChallengeHUD(myHud).HitTime[i];
			if ( DamageTime < 1 )
			{
				Canvas.SetPos(X + ChallengeHUD(myHud).HitPos[i].X * StatScale, ChallengeHUD(myHud).HitPos[i].Y * StatScale);
				if ( (ChallengeHUD(myHud).HUDColor.G > 100) || (ChallengeHUD(myHud).HUDColor.B > 100) )
					Canvas.DrawColor = ChallengeHUD(myHud).RedColor;
				else
					Canvas.DrawColor = (ChallengeHUD(myHud).WhiteColor - ChallengeHUD(myHud).HudColor) * FMin(1, 2 * DamageTime);
				Canvas.DrawColor.R = 255 * FMin(1, 2 * DamageTime);
				Canvas.DrawTile(Texture'BotPack.HudElements1', StatScale * ChallengeHUD(myHud).HitDamage[i] * 25, StatScale * ChallengeHUD(myHud).HitDamage[i] * 64, 0, 64, 25.0, 64.0);
			}
		}
	}

	// (Anth) Pure fix
	if (PlayerLinked != None)
	{
		if (PlayerLinked.IsInState('InvalidState'))
			PlayerLinked.GotoState('');
		StartTrace = PlayerLinked.Location;
		StartTrace.Z += PlayerLinked.BaseEyeHeight;
		EndTrace = StartTrace + vector(PlayerLinked.ViewRotation)*10000.0;
		Other = Trace(HitLocation, HitNormal, EndTrace, StartTrace, true);

		if (Pawn(Other) != None && !Other.bHidden )
			for (i = 0; i < ArrayCount(PInfo); i++)
				if (PInfo[i].P == Pawn(Other) && (ChallengeHUD(myHUD).IdentifyTarget == none || ChallengeHUD(myHUD).IdentifyFadeTime < 3.0))
				{
					ChallengeHUD(myHUD).IdentifyTarget = PInfo[i].PRI;
					ChallengeHUD(myHUD).IdentifyFadeTime = 3.0;
					break;
				}
	}

	if (SeekTick > 0 && Player != None && Player.Console != None)
	{
		Canvas.Style = ERenderStyle.STY_Normal; // no translucency!
		Player.Console.PrintActionMessage(Canvas, Seeking);
	}

	if (PlayerReplicationInfo != None)
		PlayerReplicationInfo.bIsSpectator=true;

	if (bLockOn)
	{
		ViewTarget=PlayerLinked; //heh.. hack
		if (myhud!=none)
			myhud.setowner(self);
		PlayerLinked.Scoring=none;
		PlayerLinked.ScoringType=none;
	}
	if (PlayerLinked != None)
		PlayerLinked.Player = None;   //UNCONSTED.. CANNOT COMPILE THIS CODE WITHOUT BYTEHACKING ENGINE.U!!!
}

// native call, maintain correct Z-offset
event UpdateEyeHeight(float DeltaTime)
{
	local vector x, y, z;
	local PlayerPawn PP;
	local bool bKeepZoom;
	local ENetRole OldRole;

	Super.UpdateEyeHeight(DeltaTime);

	PP = PlayerPawn(ViewTarget);
	if (PP == None && ViewTarget != None)
		PP = PlayerPawn(ViewTarget.Owner);
	if (PP != None) {
		if (Level.Pauser == "") {
			PP.EyeHeight = oldEyeH;
			PP.ViewShake(DeltaTime);
			//PP.UpdateEyeHeight(DeltaTime);
			if (PP == ViewTarget && PP.Base != None && (PP.Mesh == None || PP.GetAnimGroup(PP.AnimSequence) != 'Dodge')) {
				GetAxes(PP.Rotation,X,Y,Z);
				OldRole = PP.Role;
				PP.Role = ROLE_Authority; // hack for apply bob when spectate another players, not demo recorder
				PP.CheckBob(DeltaTime, sqrt(PP.Velocity.X * PP.Velocity.X + PP.Velocity.Y * PP.Velocity.Y), Y);
				PP.Role = OldRole;
			} else {
				PP.BobTime = 0;
				PP.WalkBob = PP.WalkBob * (1 - FMin(1, 8 * DeltaTime));
			}
			WalkBob = PP.WalkBob;
			oldEyeH = PP.EyeHeight;
		}

		if (!bBehindView)
		{
			bZooming = PP.bZooming;
			if (bZooming || PP.DesiredFOV != PP.DefaultFOV)
			{
				DesiredFOV = PP.DesiredFOV;
				bKeepZoom = true;
			}
		}
	}
	if (!bKeepZoom && DesiredFOV != DefaultFOV)
		FixFOV();
}

//use viewtarget (for water and such)
function ViewFlash(float DeltaTime)
{
	local vector goalFog;
	local float goalscale, delta;
	local actor ref;

	//blocked check?
	ref = ViewTarget;
	if (ref==none)
		ref=self;

	if ( bNoFlash )
	{
		InstantFlash = 0;
		InstantFog = vect(0,0,0);
	}

	delta = FMin(0.1, DeltaTime);

	if (ref.bIsPawn)
	{
		goalScale = 1 + DesiredFlashScale + ConstantGlowScale + Pawn(ref).HeadRegion.Zone.ViewFlash.X;
		goalFog = DesiredFlashFog + ConstantGlowFog + Pawn(ref).HeadRegion.Zone.ViewFog;
	}
	else
	{
		goalScale = 1 + DesiredFlashScale + ConstantGlowScale + ref.Region.Zone.ViewFlash.X;
		goalFog = DesiredFlashFog + ConstantGlowFog + ref.Region.Zone.ViewFog;
	}

	DesiredFlashScale -= DesiredFlashScale * 2 * delta;
	DesiredFlashFog -= DesiredFlashFog * 2 * delta;
	FlashScale.X += (goalScale - FlashScale.X + InstantFlash) * 10 * delta;
	FlashFog += (goalFog - FlashFog + InstantFog) * 10 * delta;
	InstantFlash = 0;
	InstantFog = vect(0,0,0);

	if ( FlashScale.X > 0.981 )
		FlashScale.X = 1;
	FlashScale = FlashScale.X * vect(1,1,1);

	if ( FlashFog.X < 0.019 )
		FlashFog.X = 0;
	if ( FlashFog.Y < 0.019 )
		FlashFog.Y = 0;
	if ( FlashFog.Z < 0.019 )
		FlashFog.Z = 0;
}

// Lame hax ;p
function InitPlayerReplicationInfo()
{
	Super.InitPlayerReplicationInfo();
	PlayerReplicationInfo.PlayerName=GetDefaultURL("Name");
	DummyAmmo=spawn(class'NullAmmo',self);
	DummyAmmo.AmmoAmount=0;
	DummyAmmo.BecomeItem();
	DummyAmmo.GotoState('');
	// pretend be replicated client item
	DummyAmmo.Role = DummyAmmo.RemoteRole;
	DummyAmmo.RemoteRole = ROLE_Authority;
}

//accessed none's suck:
function Typing( bool bTyping )
{
	bIsTyping = bTyping;
	if (bTyping)
		PlayChatting();
}

event PlayerCalcView(out actor ViewActor, out vector CameraLocation, out rotator CameraRotation )
{
	local Pawn PTarget;
	local float Delta;

	delta=(level.timeseconds-lts)*Driver.myspeed/level.timedilation; //ignore timedilation but keep speed (needed for changes!)

	if (delta>0)
		lts=level.timeseconds;

	// Lock on the demorecorder?
	if (bLockOn)
	{
		ViewTarget=PlayerLinked;
		bBehindView = PlayerLinked.bBehindView; //someone might k33l me for this :p

		// Is the demorecorder watching an other pawn? (F5 etc...)
		if (PlayerLinked.viewTarget!=none)
			SetPlayer(PlayerLinked.viewTarget,true);
	}

	// Got the view target. Calculate location, viewrotation etc etc
	if ( ViewTarget != None )
	{
		ViewActor = ViewTarget;
		CameraLocation = ViewTarget.Location;
		CameraRotation = ViewTarget.Rotation;
		PTarget = Pawn(ViewTarget);

		// Get target's inventory
		if (PTarget!=none && !bLockOn)
		   SetPlayer(PTarget,(PlayerLinked!=none && PlayerLinked.ViewTarget==PTarget));

		// Are we the demorecorder ineyes ?
		if (PTarget==PlayerLinked && PTarget != self
		&& ( (PlayerLinked.viewtarget==none && !bBehindView && !PlayerLinked.IsInState('dying') && !PlayerLinked.IsInState('GameEnded')) ||bLockOn)
		)
		{
			if (!bLockOn)
				PlayerLinked.bBehindView = bBehindView;

			PlayerLinked.EyeHeight = oldEyeH; //double hack
			PlayerPawn(PTarget).PlayerCalcView(ViewActor,CameraLocation,CameraRotation); //utpure hack!
			CameraLocation = PTarget.Location;
			CameraLocation.z+=oldEyeH; //?
			LastViewRot=CameraRotation;
			return;
		}
		if ( PTarget != None )
		{
			if ( PTarget.bIsPlayer && PTarget != self &&
			   PlayerPawn(PTarget) != none)
			{
				// (Changed by Anth) Also calculate if viewtarget != demorecorder!!!
				PlayerLinked.EyeHeight = oldEyeH; //double hack
				PlayerPawn(PTarget).PlayerCalcView(ViewActor,CameraLocation,CameraRotation); //utpure hack!

				// hack for fix RypelCam rotation
				if (class'DemoSettings'.default.bFixRypelCam && CHSpectator(ViewTarget) != None && ViewTarget.Role == Role_Authority && 
					(ViewTarget.isA('CamControl') || ViewTarget.isA('Viewer')))
				{
					CameraRotation = ViewTarget.Rotation;
					delta = 0; // turn off interpolation
				}

				// Roll might not be 0 for non-recording viewtargets :o
				if (PTarget != PlayerLinked)
				{
					PlayerPawn(PTarget).ViewRotation.Roll = 0;
					CameraRotation.Roll = 0;
				}

				TargetViewRotation=CameraRotation;
				CameraLocation = PTarget.Location;
				TargetEyeHeight=oldEyeH;
				ViewActor=ViewTarget;
			}
			else
			{
				CameraRotation = PTarget.ViewRotation;
			}

			if (CameraRotation==rot(0,0,0)) //viewing in client demo.. uh.. just make it the normal rotation!
				CameraRotation = PTarget.Rotation;

			LastViewRot=CameraRotation;
			TargetViewRotation = PTarget.ViewRotation;

			if ( !bBehindView )
				CameraLocation.Z += TargetEyeHeight; //originally just .eyeheight!
		}
		if ( bBehindView )
			CalcBehindView(CameraLocation, CameraRotation, 180);
		else if (class'DemoSettings'.default.InterpolateView&&delta>0)
			InterpolateRot(delta,CameraRotation);

		return;
	}

	ViewActor = Self;
	CameraLocation = Location;

	if( bBehindView ) //up and behind
	{
		CalcBehindView(CameraLocation, CameraRotation, 150);
	}
	else
	{
		// First-person view.
		CameraRotation = ViewRotation;
		CameraLocation.Z += EyeHeight;
		CameraLocation += WalkBob;
	}
}

// =============================================================================
// HUD FUNCTIONS!!!
// =============================================================================

//prevent seeking messages:
function ClientMessage( coerce string S, optional name Type, optional bool bBeep )
{
	if (!bSeeking)
		Super.ClientMessage(S,Type,bBeep);
}

function TeamMessage( PlayerReplicationInfo PRI, coerce string S, name Type, optional bool bBeep )
{
	if (!bSeeking)
		Super.TeamMessage(PRI,S,Type,bBeep);
}

function ClientVoiceMessage(PlayerReplicationInfo Sender, PlayerReplicationInfo Recipient, name messagetype, byte messageID)
{
	if (!bSeeking)
		Super.ClientVoiceMessage(Sender,Recipient,messagetype,messageID);
}

//JOLT MESSAGE FILTERING (BASED ON TNSe's CODE!!!)
//entry point of localized messages!
function ReceiveLocalizedMessage( class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject )
{
	CheckMessage(Message,Switch,RelatedPRI_1,RelatedPRI_2,OptionalObject);
	if (!bSeeking)
		Super.ReceiveLocalizedMessage(Message,Switch,RelatedPRI_1,RelatedPRI_2,OptionalObject);
}

//message handler: boolean is only used for "local player" type messages
function bool CheckMessage(class<LocalMessage> Message, int Swi, PlayerReplicationInfo RelatedPRI_1, PlayerReplicationInfo RelatedPRI_2, Object OptionalObject)
{
	Switch(Message)
	{
		//hud does this anyway! - (Anth) Pure hud doesn't
		case class'CTFMessage2':
			return true;
		//messages that only show when viewing from linked player!
		case class'VictimMessage':
		case class'DecapitationMessage':
		case class'ItemMessagePlus':
		case class'PickupMessagePlus':
		case class'KillerMessagePlus':
			return (bLockOn||ViewTarget==PlayerLinked);
		case class'MultiKillMessage':
			if (bLockOn||ViewTarget==PlayerLinked)
				return true;
			ClientMessage(RelatedPRI_1.PlayerName@"did a"@Class'MultiKillMessage'.static.GetString(Swi,RelatedPRI_1)); //lame msg thing!
			return false;
		case class'DeathMessagePlus':
		case class'EradicatedDeathMessage':
			switch(Swi)
			{
				case 0: // Normal kill
				case 8: // Telefrag
					KillTime(RelatedPRI_1,RelatedPRI_2);
					break;
				Default: // Some kind of suicide dumb guy :P
					Suicidal(RelatedPRI_1);
					break;
			}
			return true;
		case Class'CTFMessage':
			if (Swi == 0)
				FlagCap(RelatedPRI_1); // Fix missing cap sound in demos
			else if (Swi == 2)
				FlagDrop(RelatedPRI_1);
			else if (Swi == 4 || Swi == 6)
				FlagPickup(RelatedPRI_1,OptionalObject);
			else if (Swi == 3 || Swi == 5 || Swi == 1)
				FlagReturn(OptionalObject);
			return true;
	}
	return true; //default is allow
}

//ripped straight from jolt demo enhancer 2.0 by TNSe
function FlagCap(PlayerReplicationInfo PRI)
{
	local int num;

	FlagDrop(PRI);

	if (PRI!=none)
		num=PRI.Team;
	else
		num=0;
	if (!bSeeking)
		ClientPlaySound(class'CTFGame'.default.CaptureSound[PRI.Team], ,True);
}

function FlagDrop(PlayerReplicationInfo PRI)
{
	local int i;

	for (i = 0; i < ArrayCount(FI); i++)
		if (FI[i].PRI == PRI)
		{
			FI[i].HasFlag = none;
			return;
		}
}

function FlagPickup(PlayerReplicationInfo PRI, Object OptionalObject)
{
	// Shouldn't be needed...
}

function FlagReturn(Object OptionalObject)
{
	local int i, FlagTeam;
	
	if (CTFFlag(OptionalObject) != None)
		FlagTeam = CTFFlag(OptionalObject).Team;
	else if (TeamInfo(OptionalObject) != None)
		FlagTeam = TeamInfo(OptionalObject).TeamIndex;
	else
		return; // passed unknown object or None - ignore

	for (i = 0; i < ArrayCount(FI); i++)
		if (FI[i].HasFlag != None && FI[i].HasFlag.Team == FlagTeam)
		{
			FI[i].HasFlag = None;
			return;
		}
}

function UDPlayerInfo GetDEPI(PlayerReplicationInfo PRI)
{
	local UDPlayerInfo Result;

	// Try to find
	ForEach AllActors(Class'UDPlayerInfo',Result)
		if (Result.PRI == PRI)
			return Result;

	Result = Spawn(Class'UDPlayerInfo');
	Result.PRI = PRI;
	return Result;
}

function Suicidal(PlayerReplicationInfo DumbGuy)
{
	local UDPlayerInfo P;

	if (DumbGuy == None)
		return;
	else
		P = GetDEPI(DumbGuy);

	if (P == None)
	{
		Log("DemoPlaybackSpec.Suicidal(): Failed to get DEPI!",'udemo');
		return;
	}

	// Killed his own dumb self
	if (P.Spree > 4)
		ReceiveLocalizedMessage( class'KillingSpreeMessage', 0, None, DumbGuy );
	P.Spree = 0;
	P.MultiLevel = 0;
	P.LastKillTime = 0.0;
}

function KillTime(PlayerReplicationInfo PRI, PlayerReplicationInfo PRI2)
{
	local int x;
	local UDPlayerInfo P,P2;

	if (PRI == None || PRI2 == None)
		return;

	P = GetDEPI(PRI);
	P2 = GetDEPI(PRI2);

	if (P == None || P2 == None)
	{
		Log("DemoPlaybackSpec.KillTime(): Failed to get DEPI!",'udemo');
		return;
	}

	//check for you killed/killed by.. whatever
	if (!bSeeking&&Pawn(ViewTarget)!=none && !bLockOn && PlayerLinked!=ViewTarget &&
		Pawn(ViewTarget).PlayerReplicationInfo!=none)
	{
		if (Pawn(ViewTarget).PlayerReplicationInfo==PRI2)
			myHUD.LocalizedMessage( class'VictimMessage', 0, PRI, PRI2 );
		else if (Pawn(ViewTarget).PlayerReplicationInfo==PRI&&myhud!=none)
			myHUD.LocalizedMessage( Class'KillerMessagePlus', 0, PRI, PRI2);
	}

	// Did you just end someones spree?
	if (P2.Spree > 4 && PlayerLinked==none)
		ReceiveLocalizedMessage( class'KillingSpreeMessage', 0, PRI2, PRI );

	P2.Spree = 0;
	P2.MultiLevel = 0;
	P2.LastKillTime = 0.0;

	// MultiKillCheck
	if (!bseeking && (Level.TimeSeconds - P.LastKillTime) < 3.0)
	{
		if (PlayerLinked==none||PlayerLinked.PlayerReplicationInfo!=PRI)
		{
			if (!bLockOn&&pawn(ViewTarget)!=none&&Pawn(ViewTarget).PlayerREplicationInfo==PRI)
				Class'MultiKillMessage'.Static.ClientReceive(self,++P.MultiLevel,PRI);
			else
				ClientMessage(PRI.PlayerName@"did a"@Class'MultiKillMessage'.static.GetString(++P.MultiLevel,PRI)); //lame msg thing!
		}
	}
	else
	{
		P.MultiLevel = 0; // More than 3 seconds since last kill, reset.
	}

	P.LastKillTime = Level.TimeSeconds;

	// KillingSpreeCheck
	x = 0;
	switch(++P.Spree)
	{
		case 25:x++;
		case 20:x++;
		case 15:x++;
		case 10:x++;
		case 5 :x++;
		break;
	}

	if (x > 0 && PlayerLinked==none)
	{
		// Spree time
		ReceiveLocalizedMessage( class'KillingSpreeMessage', x-1, PRI, none );
		ClientPlaySound(Class'KillingSpreeMessage'.Default.SpreeSound[x-1], ,True);
	}
}

// =============================================================================
// INTERPOLATION STUFF!!!
// =============================================================================

//InterpolateView: TRACK IF PLAYER IS NEW?
function gotupdated(out rotator camrot)
{
	totaltimeR += timepassed;
	updatetimes++;
	predictiontime = totaltimeR/updatetimes;
	realtargetrotation = camrot;
	camrot = lastrotation;
	lastrotation = realtargetrotation;
	//log("udt"@timepassed);
	//log("upd"@realtargetrotation);
	pitchdiff = (realtargetrotation.pitch - camrot.pitch);
	yawdiff =  (realtargetrotation.yaw - camrot.yaw);
	normdiff(pitchdiff);
	normdiff(yawdiff);
	pitchrate = pitchdiff/(predictiontime);
	yawrate = yawdiff/(predictiontime);
	//log("unr"@pitchrate@", "@yawrate);
	timepassed = 0;
}

function normdiff(out int diff)
{
	//log("nnorm"@diff);
	if (diff > 32767) {diff -= 65536;};
	if (diff < -32767) {diff += 65536;};
	//log("normed"@diff);
}

function renorm(out int a)
{
	a = a & 65535;
}

function setnewrate(float deltatime, out rotator camrot)
{
	pitchdiff = (realtargetrotation.pitch - camrot.pitch);
	yawdiff =  (realtargetrotation.yaw - camrot.yaw);
	normdiff(pitchdiff);
	normdiff(yawdiff);
	pitchrate = 2*pitchdiff/(predictiontime+deltatime);
	yawrate = 2*yawdiff/(predictiontime+deltatime);
}


function setrot(float deltatime, out rotator camrot)
{
	camrot.pitch += deltatime * pitchrate;
	camrot.yaw += deltatime * yawrate;
	renorm(camrot.pitch);
	renorm(camrot.yaw);
}

//thx goes to garfield for this!
function InterpolateRot(float deltatime, out rotator camrot)
{
	timepassed += deltatime;
	if ( (lastrotation.pitch != camrot.pitch) || (lastrotation.yaw != camrot.yaw) )
		gotupdated(camrot);
	setrot(deltatime, camrot);
	setnewrate(deltatime, camrot);
	lastrotation = camrot;
}

defaultproperties
{
	oldEyeH=27.000000
	ViewTargetID=-1
	Seeking="SEEKING"
	LocCurrentlyAt="Currently at"
	LocCurrentlyAtFrame="Currently at frame"
	LocDemoIsPrefix="Demo is"
	LocDemoIsSuffix="seconds long"
	LocDemoConsistsOfPrefix="Demo consists of"
	LocDemoConsistsOfSuffix="frames"
	LocDemoInitialTimestamp="Demo's initial timestamp is"
	LocSmartCTFToggled="SmartCTF stats toggled"
	LocCannotGoToFPSMode="Cannot go to first person mode in server demos!"
	LocDemoIsNowPlayingBackPrefix="Demo is now playing back with type"
	LocServerDemosHaveNoPlayerRecorders="Server demos have no player recorders!"
	HUDType=None
	bAdmin=True
	bAlwaysTick=True
}
