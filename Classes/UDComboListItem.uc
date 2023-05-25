// =============================================================================
// UT Demo Manager v3.4
// Originally written by UsAaR33
// Project continued by AnthraX after v3.0
// =============================================================================
// udemo.UDComboListItem: list to also hold demo info (value 2 doesn't work for pointers ;p)
// allows analyzing to occur once per demo file.
// note sort weight is file size.  Value2 is directory I am in.
// =============================================================================
class UDComboListItem expands UWindowComboListItem;

// =============================================================================
// Variables
// =============================================================================
var string   MapName;     // map demo uses
var bool     Validated;   // in refresh only.
var bool     bServerDemo; // server demo?
var float    PlayTime;    // amount of PlayTime in Demo
var int      NumFrames;   // amount of frames in demo
var DemoList Packages;    // points to first real item of packages, NOT ITS SENTINEL!
var string   CapsValue;

// =============================================================================
// Compare
// =============================================================================
function int Compare(UWindowList T, UWindowList B)
{
	local UDComboListItem TI, BI;

	TI = UDComboListItem(T);
	BI = UDComboListItem(B);

	if (TI.CapsValue > BI.CapsValue)
		return 1;

	if (TI.CapsValue == BI.CapsValue)
		return 0;

	return -1;
}

// =============================================================================
// defaultproperties
// =============================================================================
defaultproperties
{
}
