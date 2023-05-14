// =============================================================================
// UT Demo Manager v3.4
// Originally written by UsAaR33
// Project continued by AnthraX after v3.0
// =============================================================================
// udemo.AutoRecorder: This class is present to
// 1) Always keep UDemo in memory.
// 2) (even more important) Do the auto-recording stuff.
// =============================================================================
class AutoRecorder expands UWindowWindow;

// =============================================================================
// Variables
// =============================================================================
var UDClientWindow Udemo;      //
var OldSkoolHack   Hack;       //
var bool           bIsPlaying; // tells if it is actually a demo playing :p

// =============================================================================
// NotifyBeforeLevelChange ~ Called before the actual levelchange (duh?)
// =============================================================================
function NotifyBeforeLevelChange()
{
    Super.NotifyBeforeLevelChange();

    // Hack == none
    // --> hack hasn't been spawned before!
    // --> spawn the hack into the entrylevel.
    if (Hack==none)
        Hack=GetEntryLevel().Spawn(class'OldSkoolHack');
    Hack.Rec=self;
    Hack.OldLevel=string(GetLevel());

    // We don't want to record a levelchange o_O
    GetPlayerOwner().ConsoleCommand("stopdemo");

    Udemo.Refresh();
}

// =============================================================================
// NotifyLevelChange ~ Called by OldSkoolHack after the level has changed and
// it's fully loaded!
// =============================================================================
function NotifyLevelChange()
{
    local string DemoCmd;

    // Level has changed and DemoActive is bigger than 0 so we're either recording OR playing a demo!
    // Can't be recording cause the only thing that can start the demorec so quickly is this function!
    bIsPlaying = (Udemo.DemReader.DemoActive(GetPlayerOwner().XLevel) > 0);

    // Where else would you get the playername eh?
    GetPlayerOwner().PlayerReplicationInfo.PlayerName = GetPlayerOwner().GetDefaultURL("name");

    // Check if we have to start the demorec!
    // (Anth) Added option to prevent recording when spectating
    if (bIsPlaying || GetLevel() == GetEntryLevel() || (GetPlayerOwner().GetDefaultURL("OverrideClass") ~= "Botpack.CHSpectator" && !class'DemoSettings'.default.bRecordWhenSpectating))
    {
        Log("UDEMO: Level changed but udemo won't auto-record");
        return;
    }
    if (class'DemoSettings'.static.ShouldRecord(GetLevel()))
    {
        DemoCmd = "demorec \""$class'DemoSettings'.static.GetRecordingDir()$class'DemoSettings'.static.GetDemoName(GetPlayerOwner(),UWindowComboListItem(Udemo.Demos.List.Items))$"\"";
        Log("UDEMO: Level changed. Auto-Recording started:"@DemoCmd);
        getplayerowner().consolecommand(DemoCmd);
    }
}

// =============================================================================
// defaultproperties
// =============================================================================
defaultproperties
{
    bTransient=true
}
