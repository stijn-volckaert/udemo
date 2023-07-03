// =============================================================================
// UT Demo Manager v3.4
// Originally written by UsAaR33
// Project continued by AnthraX after v3.0
// =============================================================================

// ===============================================================
// udemo.DemoNotify: A simple hack in playback to set everything after player is spawned!
// Um.. this is used for voice packs ;p
// ===============================================================
class DemoNotify expands SpawnNotify;

var string Substr;

simulated event PreBeginPlay();

simulated function Init(class<Actor> InActorClass, optional string InSubstr)
{
	ActorClass = InActorClass;
	Substr = Caps(InSubstr);
	Log(ActorClass.Name @ InSubstr @ "Intercepter Installed!", 'Udemo');
}

//add tick add thing?
simulated event Actor SpawnNotification(Actor A)
{
	//A.bDifficulty3 = false; //HACK
	if (Substr == "" || InStr(Caps(string(A.Class.Name)), Substr) != -1)
	{
		//Log("SetOwner for" @ A @ "to" @ Owner, 'Udemo');
		A.SetOwner(Owner);
	}
	return A;
}

defaultproperties
{
	ActorClass=Class'Engine.VoicePack'
	RemoteRole=ROLE_None
}
