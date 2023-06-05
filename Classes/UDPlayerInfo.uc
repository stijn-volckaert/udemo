// =============================================================================
// UT Demo Manager v3.4
// Originally written by UsAaR33
// Project continued by AnthraX after v3.0
// =============================================================================
// udemo.UDPlayerInfo: Just TNSe's DEPlayerInfo!
// used for keeping track of sprees and multikills to restore messages in demos! (esp. server demos!)
// note: is killed when jumping backwards!
// =============================================================================
class UDPlayerInfo extends Info;

var PlayerReplicationInfo PRI;
var int Spree;
var int MultiLevel;
var float LastKillTime;

defaultproperties
{
}
