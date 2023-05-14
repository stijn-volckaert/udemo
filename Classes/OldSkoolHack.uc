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
var bool bLevelChanged;

// =============================================================================
// Tick ~
// =============================================================================
event Tick( float Delta )
{
    // Track levelchanges...
    // NOTE: LEVACT_None means that the level hasn't been fully loaded yet!!
    if (string(Rec.GetLevel()) != OldLevel)
    {
    	OldLevel = string(Rec.GetLevel());
    	bLevelChanged = true;
    }
    if (bLevelChanged && Rec.GetLevel().LevelAction==LEVACT_None)
    {
    	bLevelChanged = false;
        if (Rec.Hack==self)
            Rec.NotifyLevelChange();

        // Keep the class active if a demo is playing/recording in this level
        if (Rec.GetLevel() != Level && class'udnative'.static.DemoActive(Rec.GetPlayerOwner().XLevel) == 0)
            Destroy();
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
