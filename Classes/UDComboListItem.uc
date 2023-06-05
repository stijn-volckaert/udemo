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

var string   MapName;     // map demo uses
var bool     bServerDemo; // server demo?
var float    PlayTime;    // amount of PlayTime in Demo
var int      NumFrames;   // amount of frames in demo
var DemoList Packages;    // points to first real item of packages, NOT ITS SENTINEL!
var string   DateTime;    // Date time of demo
var int      OrderDir;    // Direction for sorting, used default, can be 1 for ascending, and -1 for descending, internal
var string   CapsValue;   // Value for sorting, internal

// =============================================================================
// Compare
// =============================================================================
function int Compare(UWindowList T, UWindowList B)
{
	local UDComboListItem TI, BI;

	TI = UDComboListItem(T);
	BI = UDComboListItem(B);

	if (TI.CapsValue > BI.CapsValue)
		return default.OrderDir;

	if (TI.CapsValue == BI.CapsValue)
		return 0;

	return -default.OrderDir;
}

function UWindowList Middle_(UWindowList Head) {
	local UWindowList Slow, Fast, Ret;
	Slow = Head;
	Fast = Head;
	while (Fast.Next != None && Fast.Next.Next != None) {
		Fast = Fast.Next.Next;
		Slow = Slow.Next;
	}
	Ret = Slow.Next;
	Slow.Next = None;
	return Ret;
}

function UWindowList MergeSort_(UWindowList Head) {
	local UWindowList Second;
	if (Head == None || Head.Next == None)
		return Head;
	Second = Middle_(Head);
	Head = MergeSort_(Head);
	Second = MergeSort_(Second);
	return Merge_(Head, Second);
}

function UWindowList Merge_(UWindowList First, UWindowList Second) {
	local UWindowList Temp;
	if (First == None)
		return Second;
	if (Second == None)
		return First;
	Next = None;
	Temp = self;
	while (true) {
		if (Compare(First, Second) < 0) {
			Temp.Next = First;
			Temp = First;
			First = First.Next;
			if (First == None) {
				Temp.Next = Second;
				break;
			}
		} else {
			Temp.Next = Second;
			Temp = Second;
			Second = Second.Next;
			if (Second == None) {
				Temp.Next = First;
				break;
			}
		}
	}
	return Next;
}

function PreSort() {
	local UWindowList Temp;
	if (CapsValue == string(Class'DemoSettings'.default.OrderByDate))
		return;	
	for (Temp = self.Next; Temp != None; Temp = Temp.Next)
		if (Class'DemoSettings'.default.OrderByDate)
			UDComboListItem(Temp).CapsValue = UDComboListItem(Temp).DateTime $ ":" $ Caps(UDComboListItem(Temp).Value);
		else
			UDComboListItem(Temp).CapsValue = Caps(UDComboListItem(Temp).Value);
	CapsValue = string(Class'DemoSettings'.default.OrderByDate);
	if (Class'DemoSettings'.default.OrderByDate)
		default.OrderDir = -1;
	else
		default.OrderDir = 1;
}

function UWindowList Sort()
{
	local UWindowList Temp;
	PreSort();
	if (bTreeSort)
		return Super.Sort();

	Next = MergeSort_(Next);
	
	for (Temp = self; Temp.Next != None; Temp = Temp.Next)
		Temp.Next.Prev = Temp;
	Last = Temp;

	//Validate();
	return Self;
}

defaultproperties
{
	OrderDir=1
}
