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

simulated event PreBeginPlay();

simulated function PostBeginPlay()
{
  super.PostBeginPlay();
  log ("Voice Pack Intercepter Generated!",'Udemo');
}
//add tick add thing?
simulated event Actor SpawnNotification(Actor A)
{
  //A.bDifficulty3=false; //HACK
  A.SetOwner(Owner);
  return A;
}

defaultproperties {
  RemoteRole=Role_None
  ActorClass=class'VoicePack'
}
