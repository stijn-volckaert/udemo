// =============================================================================
// UT Demo Manager v3.4
// Originally written by UsAaR33
// Project continued by AnthraX after v3.0
// =============================================================================
// udemo.OldSkoolHack: actor spawned into the entrylevel. Tracks levelchanges
// and notifies the autorecorder accordingly
// =============================================================================
class OldSkoolHack expands Actor;

// =============================================================================
// Variables
// =============================================================================
var string OldLevel;
var AutoRecorder Rec;

// =============================================================================
// Tick ~
// =============================================================================
event Tick( float Delta )
{
    // Track levelchanges...
    // NOTE: LEVACT_None means that the level hasn't been fully loaded yet!!
    if (string(Rec.GetLevel()) != OldLevel && Rec.GetLevel().LevelAction==LEVACT_None)
    {
        if (Rec.Hack==self)
            Rec.NotifyLevelChange();

        // Keep the class active if a demo is playing/recording in this level
        if (Rec.GetLevel() != Level && class'udnative'.static.DemoActive(Rec.GetPlayerOwner().XLevel) == 0)
            Destroy();
        else
            OldLevel = string(Rec.GetLevel());
    }
}

// =============================================================================
// Destroyed ~ Must clean up references or the gc will be angry!
// =============================================================================
event Destroyed()
{
    if (Rec.Hack==self)
        Rec.Hack=None;
}
