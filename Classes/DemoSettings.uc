// =============================================================================
// UT Demo Manager v3.4
// Originally written by UsAaR33
// Project continued by AnthraX after v3.0
// =============================================================================

// ============================================================
// udemo.DemoSettings: an abstract class that simply stores a bunch of settings :)
// This stores EVERY SETTING FOR UDEMO!
// ============================================================

class DemoSettings expands Object
	config (udemo);

var config bool      bOneTimeUpgrade;

var config bool FollowMyCam; // Follow camera position and rotation for DemoPlaybackSpectator?

//play menu:
var config string LastDemo; //what has the last demo selected?
var config byte Timing; //saved timing mode
var config bool SpecDemo; //3rd person
var config bool OrderByDate; // order demo list by date

//paths:
var localized config string DemoPaths[5]; //1 of these is setup to be base directory on first load.
var config int RecordingDir; //DemoPaths[recordingdir] is where to record.

//Sorting/PBI saved info
var config byte		SortColumn;
var config bool		bDescending;
var config byte		DisplayMode; //0=show all, 1=hide ones PBI shows, 2=hide all installed.

//stuff for level recorder:
var config byte LevelRecord; //0=never, 1=both, 2=singleplayer only, 3=multiplayer only.
//var config bool bGenerateInfo; //should info be written?    //FIXME: Add support :)
var config string Format; //format of info. %L=level, %D=day, %Y=year %M=month, %H=hour, %O=minute, %S=second, %v=server name, %%=%, %N=number increment
var config bool bRecordWhenSpectating; // (Anth) Auto record when spectating?

//downloading:
var config byte DownloadType; //0=cache it, 1=goto paths
var config String RedirectServers[24]; //list of redirect servers where files may be downloaded from

//advanced demo driver settings:
var config float CacheSeconds; //amount of seconds to cache for when jumping (i.e. run x updates this amount of time)
var config float TickSize; //how big the update tick should be during cache... (i.e. tick by this deltatime.. lower=more accurate)
var config bool InterpolateView; //if garfield's interpolation rotator thing should be used in 1st person view

var config DemoInterface.ESmoothRecorderMovement SmoothRecorderMovement; //apply smooth for recorder movement via physics prediction, make playback smooth on low speed, but make it less precise and can introduce some glitches

var config bool bFixRypelCam; // enable hacks for RyphelCam (rotation and independent playback speed)

//functions for easy reading:
static function int ReDirectIndex(String ServerURL)
{
	local int i;
	for (i = 0; i < ArrayCount(default.RedirectServers); i++)
		if (ServerURL == default.RedirectServers[i])
			return i;
	return -1; //error.
}
static function string GetRecordingDir()
{
	return default.DemoPaths[default.RecordingDir];
}
// returns "" if base:
static function string Path(int i, string base)
{ 
	if (default.DemoPaths[i] == base)
		return "";
	else
		return default.DemoPaths[i];
}
// compare stuff to see if record good:
static function bool ShouldRecord(LevelInfo level)
{
	return default.LevelRecord == 1 || 
		(default.LevelRecord == 2 && Level.NetMode == NM_Standalone) || 
		(default.LevelRecord == 3 && Level.NetMode > NM_DedicatedServer);
}
//parses format to give result.
static function string GetDemoName(playerpawn p, UWindowComboListItem List)
{
	local string Msg, OutMsg, cmd; //names are ripped, yes :)
	local int pos, x;
	local levelinfo level;
	
	Level = p.Level;
	Msg = default.format;
	pos = InStr(Msg, "%");
	if (pos > -1)
	{
		While (true)
		{
			if (pos > 0)
			{
				OutMsg = OutMsg $ Left(Msg, pos);
				Msg = Mid(Msg, pos);
				pos = 0;
			}
	
			x = Len(Msg);
			cmd = Mid(Msg, pos, 2);
			if (x - 2 > 0)
				Msg = Right(msg, x - 2);
			else
				Msg = "";
	
			if (cmd ~= "%L")
			{
				cmd = level.GetURLMap();
				if (Right(cmd, 4) ~= ".unr")
					cmd = Left(Level.GetURLMap(), Len(Level.GetURLMap()) - 4);
				OutMsg = OutMsg $ cmd;
			}
			else if (cmd ~= "%D")
			{
				cmd = string(Level.Day);
				if (Len(cmd) == 1)
					cmd = "0" $ cmd;
				OutMsg = OutMsg $ cmd;
			}
			else if (cmd ~= "%M")
			{
				cmd = string(Level.Month);
				if (Len(cmd) == 1)
					cmd = "0" $ cmd;
				OutMsg = OutMsg $ cmd;
			}
			else if (cmd ~= "%Y")
				OutMsg = OutMsg $ level.Year;
			else if (cmd ~= "%H")
			{
				cmd = string(Level.Hour);
				if (Len(cmd) == 1)
					cmd = "0" $ cmd;
				OutMsg = OutMsg $ cmd;
			}
			else if (cmd ~= "%O")
			{
				cmd = string(Level.Minute);
				if (Len(cmd) == 1)
					cmd = "0" $ cmd;
				OutMsg = OutMsg $ cmd;
			}
			else if (cmd ~= "%S")
			{
				cmd = string(Level.Second);
				if (Len(cmd) == 1)
					cmd = "0" $ cmd;
				OutMsg = OutMsg $ cmd;
			}
			else if (cmd ~= "%V")
			{
				if (P.GameReplicationInfo != None)
					OutMsg = OutMsg $ P.GameReplicationInfo.ServerName;
			}
			else if (cmd == "%%")
				OutMsg = OutMsg $ "%";
			else
				OutMsg = OutMsg $ cmd;
	
			pos = InStr(Msg, "%");
	
			if (Pos == -1)
				break;
		}
		if (Len(msg) > 0)
			OutMsg = OutMsg $ Msg;
	}
	else
		OutMsg = Msg;
	Msg = OutMsg;  //reverse for simplicity.
	OutMsg = "";
//illegal char parsing:
	X = Len(Msg);
	for (pos = 0; pos < X; pos++)
	{
		//USE reads bad!
		if (InStr("\\/*?<:>\"|", Mid(Msg, pos, 1)) != -1)
			continue;
		else if (InStr(" ", Mid(Msg, pos, 1)) != -1)
			outMsg = outMsg $ "_";
		else
			outMsg = outMsg $ Mid(Msg, pos, 1);
	}
	Msg = outMsg;
	OutMsg = "";
	x = 2;
	Cmd = Msg; //store one with %N
	//filter out N for next test...
	pos = InStru(Msg, "%n");
	while (pos != -1)
	{
		outMsg = outMsg $ left(Msg, pos);
		Msg = Mid(Msg, pos + 2);
		pos = InStru(Msg, "%n");
	}
	Msg = outMsg $ Msg;
	// verify if something is similar me.   If so, keep trying until all fine.
	While (Matching(List,Msg))
	{
		// code based on codeconsole from onp
		OutMsg = "";
		Msg = Cmd;   //reset each loop.
		pos = InStru(Msg, "%n");
		while (pos != -1)
		{
			outMsg = outMsg $ left(Msg, pos) $ x;
			Msg = Mid(Msg, pos + 2);
			pos = InStru(Msg, "%n");
		}
		Msg = outMsg $ Msg;
		if (outMsg == "") //no change: do something!
			Msg = Msg $ "-" $ x;
		x++;
	}
	return Msg;
}
//used in above function:
static function bool Matching(UWindowComboListItem List, string test)
{
	for (List = UWindowComboListItem(List.Next); List != None; List = UWindowComboListItem(List.Next))
		if (List.Value ~= test)
			return true;
	return false;
}
//case insensitive: (give lowe though for t!)
static function int InStru(coerce string S, coerce string t)
{
	local int temp;
	
	temp = InStr(S, t);
	if (temp != -1)
		return temp;
	return InStr(S, Caps(t));
}

//nothing to do with settings, but I couldn't find a better place to put it :/
static function string parseTime(float time)
{
	local int hour, min, sec;
	local string hourstr, minStr, secStr;

	hour = int(time/3600);
	min = int(time/60)%60;
	sec = int(time)%60;

	if (hour > 0)
		hourstr = string(hour) $ ":";
	minStr = string(min);

	// If sec is one digit, add a zero
	if (min >= 10 || hour == 0)
		minStr = string(min);
	else
		minstr = "0" $ string(min);

	// If sec is one digit, add a zero
	if (sec >= 10)
		secStr = string(sec);
	else
		secStr = "0" $ string(sec);

	return hourstr $ minStr $ ":" $ secStr;
}
//converts to 2 dig float
static function string FloatString(float A)
{
	local string tmp;
	local int pos;
	
	tmp = string(A);
	pos = InStr(A, ".");
	return Left(tmp, pos) $ Mid(tmp, pos, 2);
}

defaultproperties
{
	FollowMyCam=True
	timing=1
	OrderByDate=True
	DemoPaths(0)="Empty"
	DemoPaths(1)="Empty"
	DemoPaths(2)="Empty"
	DemoPaths(3)="Empty"
	DemoPaths(4)="Empty"
	DisplayMode=1
	Format="%L_%M-%D_%H-%O-%S"
	bRecordWhenSpectating=True
	DownloadType=1
	RedirectServers(0)="uz.ut-files.com"
	CacheSeconds=7.000000
	TickSize=0.400000
	InterpolateView=True
	SmoothRecorderMovement=Smooth_3rdperson
	bFixRypelCam=True
}
