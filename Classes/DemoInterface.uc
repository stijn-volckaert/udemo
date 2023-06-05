// =============================================================================
// UT Demo Manager v3.4
// Originally written by UsAaR33
// Project continued by AnthraX after v3.0
// =============================================================================

// ===============================================================
// udemo.DemoInterface: NATIVE CLASS used to control the demo playback driver!
// This provides for a cleaner method for control rather than standard console commands.
// note: driver is reponsible for checks including server changing of timedilation and pauser!
// ===============================================================

class DemoInterface expands Object
	native config(udemo);

var const PlayerPawn DemoSpec;  //the spectator subclass
var const uDemoDriver DemoDriver; //the demo driver. only valid in cpp
//useful in vars to read in script:
var const float mySpeed; //current speed of demo
var const byte PlayBackMode; //current playback mode
var const bool bDoingMessagePlay; //if true, no rendering is taking place.  This is only for message grabbing!
var const float ltsoffset;   // (Anth) Sync time thingie

// (Anth) Destroying illegal actors is native now (because of serverside demos)
var config string IllegalActors[20];

// (Anth) Testing only!
var config bool bDebug;
var config bool bAnthDebug;

//native functions:
native final function SetSpeed (float newSpeed); //playback speed control
native final function JumpBack (); //jumps all the way back to beginning (at starttime). deletes most actors!
native final function ReadTo (float time); //read ahead until have reached time.
native final function ReadCache (float ToTime,float inc); //read until reached toTime + tick non-pawn actors by inc
native final function float GetCurrentTime(); //This is the current time (-start) demo is on
native final function float GetTotalTime(); //time demo lasts (1.0 speed) (start-end)
native final function int GetCurrentFrame(); //return current frame number (-start frame)
native final function int GetTotalFrames(); //return the number of frames in the demo that is playing
native final function PauseDemo(bool bPause); //safely controls demo pausing.
native final function byte IsPaused(); //0=no, 1=paused in demo (ex. admin hit pause), 2=user requested
native final function SetPlayBackMode(byte a); //playback modes: 0=timebased, 1=framebased, 2=nocap
native final function float GetStartTime(); //returns the time demo was at when starting play (After player spawned)

//non-native functions:
function GotoFrame (float Time)
{
    local float cur;

    if (Time > GetTotalTime() || Time < GetStartTime())  //invalid
        return;

    cur=GetCurrentTime();

    if (abs(Time-cur) < 0.5) //too small interval.. don't jump!
        return;

    DemoPlaybackSpec(DemoSpec).bSeeking=true;

    if (Time > cur && Time < cur + fmax(2*class'DemoSettings'.default.CacheSeconds,5.0))
        ReadCache (Time+GetStartTime(),class'demosettings'.default.TickSize); //more reliable to keep reading w/ cache
    else
    { //must do complex jumping method...
        Time+=GetStartTime();

        if (Time<cur)
        {
            DemoPlaybackSpec(DemoSpec).BackUpRefs(); //back up pointers (playerid! channel# does change!)
            JumpBack(); //go backwards in demo
        }

        if (time-class'DemoSettings'.default.CacheSeconds>GetCurrentTime())
            ReadTo(time-class'DemoSettings'.default.CacheSeconds); //read forwards

        DemoPlaybackSpec(DemoSpec).FixGRI(time-cur); //fix gri times
        ReadCache(Time,class'DemoSettings'.default.TickSize); //now do caching
   }
   
	SetSpeed(mySpeed);
   DemoPlaybackSpec(DemoSpec).bSeeking=false;
}


//events:

//in clientdemos, this is the playerpawn the spectator should "link to" for information (HUD, etc.) none in serverdemo!
//LockOn is true if 3rdperson not in url (and not server demo). can be toggled during playback!

/*
    (Anth) Changed in v3.2. DemoSpawnNotify moved to native...
*/
event LinkToPlayer (PlayerPawn p, bool LockOn)
{
    DemoPlaybackSpec(DemoSpec).Driver = self;  //give pointer to self

    // No lockon! We don't want to render stuff
    if (bDoingMessagePlay)
        LockOn=false;

    if (bDebug)
        Log("UDEMO: Trying to link to player :"@p);

    if (!DemoPlaybackSpec(DemoSpec).bInit)
    {
        log (DemoSpec@"(viewport: '"$DemoSpec.Player$"') linked to"@p,'Udemo');

        DemoPlaybackSpec(DemoSpec).bLockOn = LockOn;

        if (p!=none&&!bDoingMessagePlay)
            DemoSpec.spawn(class'DemoNotify'); //used for voice pack interception!
    }

    DemoPlaybackSpec(DemoSpec).PlayerLinked = p;
    DemoPlaybackSpec(DemoSpec).bInit=true; //me is too lazy to re-do headers ;p
    
     if (Spectator(p) != None)
    {
    	Log("Linked player is Spectator - switched to 3rdperson play.", 'Udemo');
    	DemoPlaybackSpec(DemoSpec).Spectate();
    }
}

event NetPacketReceived(); //called each packet if message grabbing

defaultproperties
{
}
