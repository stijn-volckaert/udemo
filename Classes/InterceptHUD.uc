// =============================================================================
// UT Demo Manager v3.4
// Originally written by UsAaR33
// Project continued by AnthraX after v3.0
// =============================================================================
// udemo.InterceptHUD: this hud is given to the linked player in order to
// intercept messages, localizedmessages, as well as the damage thing!
// =============================================================================
class InterceptHUD expands ChallengeHUD;

// =============================================================================
// Variables
// =============================================================================
var DemoPlayBackSpec Real; // Associated demoviewer
var string PrevMessageStr; // (Anth) Previous message
var float PrevMessageTime; // (Anth) when was the previous message received

// =============================================================================
// SetDamage ~
// =============================================================================
function SetDamage(vector HitLoc, float damage)
{
    if (!Real.bSeeking && (Real.bLockOn || owner == Real.ViewTarget)
        && challengeHUD(Real.MyHud) != none)
    {
        challengeHUD(Real.MyHud).PlayerOwner=Playerpawn(Owner);
        Real.myhud.SetOwner(owner);
        Real.myhud.setCollisionSize(owner.collisionradius,owner.collisionheight); //stupid epic bug ;p
        challengeHUD(Real.MyHud).SetDamage(HitLoc,damage);
        challengeHUD(Real.MyHud).PlayerOwner=real;
        Real.myhud.SetOwner(real);
    }
}

// =============================================================================
// Message ~
// =============================================================================
simulated function Message( PlayerReplicationInfo PRI, coerce string Msg, name MsgType )
{
    local bool bIgnoreMessage;

    if (Real.myhud==none||Real.bSeeking)
        return;
    if (MsgType=='pickup'&&!Real.bLockOn&&Real.ViewTarget!=owner)
        return;
    if (MsgType=='TeamSay'&&!Real.bLockOn&&(Pawn(Real.ViewTarget)==none||
        Pawn(Real.ViewTarget).PlayerReplicationInfo==none||
        Pawn(Real.ViewTarget).PlayerReplicationInfo.Team!=Pawn(Owner).PlayerReplicationInfo.Team))
        return;

    // (Anth) Double message thing
    if (Real != none && Real.PlayerLinked != none && Real.PlayerLinked.PlayerReplicationInfo == PRI)
    {
        if (Real.Level.TimeSeconds - PrevMessageTime <= 1.0 && Msg == PrevMessageStr)
            bIgnoreMessage=true;

        // Update PrevMessage
        PrevMessageStr = Msg;
        PrevMessageTime = Real.Level.TimeSeconds;
    }

    if (!bIgnoreMessage)
        Real.myhud.Message(PRI,Msg,MsgType); //just send!
    else
        Log("UDEMO: HudMessage Ignored:"@PRI@PRI.PlayerName@Msg@MsgType);
}

// =============================================================================
// LocalizedMessage ~
// =============================================================================
simulated function LocalizedMessage
(
    class<LocalMessage> Message,
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1,
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject,
    optional String CriticalString
)
{
    //let master filter decide validity!
    if (real.myHud != none
        && Real.CheckMessage(Message,Switch,RelatedPRI_1,RelatedPRI_2,OptionalObject)
        && !Real.bSeeking)
        Real.myHud.LocalizedMessage(Message,Switch,RelatedPRI_1,RelatedPRI_2,OptionalObject,CriticalString);
}

// =============================================================================
// defaultproperties
// =============================================================================
defaultproperties
{
}
