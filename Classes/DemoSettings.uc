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
config (UDemo);

//play menu:
var config string LastDemo; //what has the last demo selected?
var config byte Timing; //saved timing mode
var config bool SpecDemo; //3rd person

//paths:
var config string DemoPaths[5]; //1 of these is setup to be base directory on first load.
var config int RecordingDir; //DemoPaths[recordingdir] is where to record.

//Sorting/PBI saved info
var config byte        SortColumn;
var config bool      bDescending;
var config byte      DisplayMode; //0=show all, 1=hide ones PBI shows, 2=hide all installed.

//stuff for level recorder:
var config byte LevelRecord; //0=never, 1=both, 2=singleplayer only, 3=multiplayer only.
//var config bool bGenerateInfo; //should info be written?    //FIXME: Add support :)
var config string Format; //format of info. %L=level, %D=day, %Y=year %M=month, %H=hour, %O=minute, %S=second, %v=server name, %%=%, %N=number increment
var config bool bRecordWhenSpectating; // (Anth) Auto record when spectating?

//downloading:
var config byte DownloadType; //0=cache it, 1=goto paths, 2=try to download INT file
var config String RedirectServers[24]; //list of redirect servers where files may be downloaded from

//advanced demo driver settings:
var config float CacheSeconds; //amount of seconds to cache for when jumping (i.e. run x updates this amount of time)
var config float TickSize; //how big the update tick should be during cache... (i.e. tick by this deltatime.. lower=more accurate)
var config bool InterpolateView; //if garfield's interpolation rotator thing should be used in 1st person view

//functions for easy reading:
static function int ReDirectIndex (String ServerURL){
  local int i;
  for (i=0;i<5;i++)
    if (ServerURL == default.RedirectServers[i])
        return i;
  return -1; //error.
}
static function string GetRecordingDir(){
  return default.DemoPaths[default.RecordingDir];
}
static function string Path(int i, string base){ //returns "" if base:
  if (default.DemoPaths[i]==base)
    return "";
  else
    return default.DemoPaths[i];
}
static function bool ShouldRecord(LevelInfo level){ //compare stuff to see if record good:
  return (default.LevelRecord==1||(default.LevelRecord==2&&level.NetMode==NM_Standalone)
   ||(default.LevelRecord==3&&level.NetMode>NM_DedicatedServer));
}
//parses format to give result.
static function string GetDemoName(playerpawn p, UWindowComboListItem List){
  local string Msg, OutMsg, cmd; //names are ripped, yes :)
  local int pos,i, x;
  local levelinfo level;
  level=p.level;
  Msg=default.format;
  pos = InStr(Msg,"%");
  if (pos>-1)
  {
    While (true)
    {
      if (pos>0)
      {
        OutMsg = OutMsg$Left(Msg,pos);
        Msg = Mid(Msg,pos);
        pos = 0;
      }

      x = len(Msg);
      cmd = mid(Msg,pos,2);
      if (x-2 > 0)
        Msg = right(msg,x-2);
      else
        Msg = "";

      if (cmd~="%L")
      {
        cmd=level.GetURLMap();
        if (Right(cmd,4)~=".unr")
          cmd=Left(level.GetURLMap(),len(level.GetURLMap())-4);
        OutMsg = OutMsg$cmd;
      }
      else if (cmd~="%D")
      {
        OutMsg = OutMsg$level.Day;
      }
      else if (cmd~="%M")
      {
        OutMsg = OutMsg$level.Month;
      }
      else if (cmd~="%Y")
      {
        OutMsg = OutMsg$level.Year;
      }
      else if (cmd~="%H")
      {
        OutMsg = OutMsg$level.Hour;
      }
      else if (cmd~="%O")
      {
        cmd=string(level.Minute);
        if (len(cmd)==1)
          cmd="0"$cmd;
        OutMsg = OutMsg$cmd;
      }
      else if (cmd~="%S")
      {
        cmd=string(level.Second);
        if (len(cmd)==1)
          cmd="0"$cmd;
        OutMsg = OutMsg$cmd;
      }
      else if (cmd~="%V")
      {
        if (P.GameReplicationInfo!=none)
          OutMsg = OutMsg$P.GameReplicationInfo.ServerName;
      }
      else if (cmd=="%%")
        OutMsg = OutMsg$"%";
      else
      {
        OutMsg = OutMsg$cmd;
      }

      pos = InStr(Msg,"%");

      if (Pos==-1)
        break;

    }
    if (len(msg)>0)
      OutMsg = OutMsg$Msg;

  }
  else
    OutMsg = Msg;
  Msg=OutMsg;  //reverse for simplicity.
  OutMsg="";
//illegal char parsing:
  X=Len(Msg);
  for (pos = 0; pos<X; pos++){
      //USE reads bad!
        if (InStr("\\/*?<:>\"|", Mid(Msg, pos, 1)) != -1)
          continue;
        else if (InStr(" ", Mid(Msg, pos, 1)) != -1)
          outMsg = outMsg $ "_";
        else
          outMsg = outMsg $ Mid(Msg, pos, 1);
      }
  Msg=outMsg;
  OutMsg="";
  x=2;
  Cmd=Msg; //store one with %N
  //filter out N for next test...
  pos=instru(Msg,"%n");
  while (pos!=-1){
    outMsg=outMsg$left(Msg,pos);
    Msg=mid(Msg,pos+2);
    pos=instru(Msg,"%n");
  }
  Msg=outMsg$Msg;
  While (Matching(List,Msg)){   //verify if something is similar me.   If so, keep trying until all fine.
    //code based on codeconsole from onp
    OutMsg="";
    Msg=Cmd;   //reset each loop.
    pos=instru(Msg,"%n");
    while (pos!=-1){
      outMsg=outMsg$left(Msg,pos)$x;
      Msg=mid(Msg,pos+2);
      pos=instru(Msg,"%n");
    }
    Msg=outMsg$Msg;
    if (outMsg=="") //no change: do something!
      Msg=Msg$"-"$x;
    x++;
  }
  return Msg;
}
//used in above function:
static function bool Matching(UWindowComboListItem List, string test){
  for (List=UWindowComboListItem(List.Next);List!=none;List=UWindowComboListItem(List.Next))
    if (List.Value~=test)
      return true;
}
//case insensitive: (give lowe though for t!)
static function int InStru  ( coerce string S, coerce string t ){
  local int temp;
  temp=InStr(S,t);
  if (temp!=-1)
    return temp;
  return InStr(S,Caps(t));
}

//nothing to do with settings, but I couldn't find a better place to put it :/
static function string parseTime( float time )
{
    local int hour, min, sec;
    local string hourstr, minStr, secStr;

    hour = int (time / 3600);
    min = int(time / 60)%60;
    sec = int(time) % 60;

    if (hour>0)
      hourstr = string(hour)$":";
    minStr = string(min);

    if(min >= 10||hour==0) minStr = string(min); // If sec is one digit, add a zero
    else minstr = "0"$string(min);

    if(sec >= 10) secStr = string(sec); // If sec is one digit, add a zero
    else secStr = "0"$string(sec);

    return hourstr$minStr$":"$secStr;
}
static function string FloatString (float A){  //converts to 2 dig float
  local string tmp;
  local int pos;
  tmp=string(A);
  pos=instr(A,".");
  return left(tmp,pos)$mid(tmp,pos,2);
}
defaultproperties {
  Timing=1
  DemoPaths(0)="Empty"
  DemoPaths(1)="Empty"
  DemoPaths(2)="Empty"
  DemoPaths(3)="Empty"
  DemoPaths(4)="Empty"
  DisplayMode=1
  //GenerateInfo=true
  Format="%L_%M-%D_%H-%O-%S"
  bRecordWhenSpectating=true
  CacheSeconds=7.0
  TickSize=0.4
  DownloadType=2
  InterpolateView=true
  RedirectServers(0)="ucc.sobservers.com"
  RedirectServers(1)="66.28.180.9"
  RedirectServers(2)="unrealmafia.com/redirects/um"
  RedirectServers(3)="208.254.35.1/maps"
  RedirectServers(4)="uz.clanzenkai.net/uz"
  RedirectServers(5)="utdownloads.online.no/redirect"
  RedirectServers(6)="arago5.tn.utwente.nl/unreal/Compressed"
  RedirectServers(7)="unreal.divinia.com/redirect"
  RedirectServers(8)="www.icequake.net/ut/redirect"
  RedirectServers(9)="www.cpti.org/uz"
  RedirectServers(10)="fragged.yerbox.org/UTfiles"
  RedirectServers(11)="www.belgames.com/servers/utpackages"
  RedirectServers(12)="www.i4games.net/download/ut/redirect"
  RedirectServers(13)="www.organized-evolution.com/ucc"
  RedirectServers(14)="www.utctf.jolt.co.uk/downloads/redirect"
  RedirectServers(15)="dma.no-ip.org/ut"
  RedirectServers(16)="www.basaku.com/unreal/"
  RedirectServers(17)="mspencer.dynu.com/tacopsredirect/"
  RedirectServers(18)="(Empty)"
  RedirectServers(19)="(Empty)"
  RedirectServers(20)="(Empty)"
  RedirectServers(21)="(Empty)"
  RedirectServers(22)="(Empty)"
  RedirectServers(23)="(Empty)"

}
