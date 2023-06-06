// =============================================================================
// UT Demo Manager v3.4
// Originally written by UsAaR33
// Project continued by AnthraX after v3.0
// =============================================================================

// ============================================================
// udemo.DemoList: Linked lists of demo requirements.  used by DemoGrid.
// ============================================================
class DemoList expands UWindowList;

//package properties
var string PackageName;
var int PackageSize;
//var bool bInstalled;
var byte bInstalled; //0=not 1=cached  2=in system dir.
var bool bPBIShows; //flag that this can be hidden.
var GUID PackageGUID; //global unique identifier.  I suppose this will be used for net downloads and such...
var int Generation; //generation of the file.  user's file should be >= to this
var bool bIsCSHP; //a Cheat protector package.  (easy access for other windows)
var bool bIsInt; //if file is an int.. (only during downloading)

var DemoList DemoNext; // preserve demo load order
var DemoList DemoLast; // sentinel fast access to last in demo chain order

const NotInstalled = 0;
const Cached = 1;
const Installed = 2;

const Good = 0;
const BadGen = 1;
const BadGuid = 2;
const BadFile = 3;
const NotAllInstalled = 4;

//for the hell of it :)
static final operator(24) bool  < ( bool A, bool B ){
	return (B&&!A);
}
static final operator(24) bool  > ( bool A, bool B ){
	return (!B&&A);
}
// active?
// returns 0 for true, 1 for bad gen, 2 for bad guid, 3 bad file, 4 for not installed!
function byte AllInstalled()
{  
	local byte bRetVal;
	if (bInstalled == NotInstalled)
		return NotAllInstalled;
	bRetVal = IsMisMatch();
	if (DemoNext != None)
		bRetVal = Max(bRetVal, DemoNext.AllInstalled());
	return bRetVal;
}

// used by downloader as well!
function byte IsMisMatch()
{
//	local int n;
	local int ret;
	
	if (IsDefPkg()) //don't check normal pacakges!
		return Good;
	ret = class'udNative'.static.IsMismatch(PackageName, PackageGUID, Generation/*, n*/);
	if (ret == BadGuid && bInstalled == Cached) // ugly hack: assume cached file never make guid mismatch
		ret = Good;
	return ret;
}

//sentinel only!
function DemoList FindPackage(string PkgName)
{
	local DemoList Pkg;
	local string temp;
	
	for (Pkg = DemoList(next); Pkg != None; Pkg = Demolist(Pkg.Next))
	{
		temp = pkg.packagename;
		if (InStr(temp, ".") != -1)
			temp = Left(temp, InStr(temp, "."));
		if (temp ~= PkgName)
			return Pkg;
	}
	Log("FindPackage() error: Package '" $ PkgName $ "' not found!", 'UDemo');
}
//call only on sentinel!
function DisconnectList()
{
	Super.DisconnectList();
	DemoNext = None;
	DemoLast = self;
}

function DemoList AddPackage (string NewName, int NewSize, byte NewInstalled, GUID newGUID, int newGen)
{
	local DemoList NewItem;
	
	NewItem = DemoList(CreateItem(Class));
	NewItem.PackageName = NewName;
	NewItem.PackageSize = NewSize;
	NewItem.bInstalled = newInstalled;
	NewItem.PackageGUID = newGUID;
	NewItem.Generation = newGen;
	MoveItemSorted(NewItem); //in list
	
	DemoLast.DemoNext = NewItem;
	DemoLast = NewItem;
	
	return NewItem;
}

// when refreshing to update menus. call on sentinel.next!
function Refresh(PackageBasicInfoCW PBI)
{
	CheckPBI(PBI);
	Sentinel.InternalCount++;
	if (Next != None)
		DemoList(Next).Refresh(PBI);
	else
		Sentinel.Last = Self;
}

// checks own package name:
function bool IsDefPkg()
{
	local string temp;
	
	temp = PackageName;
	if (InStr(temp, ".") != -1)
		temp = Left(temp, InStr(temp, "."));
	return IsDefaultPackage(temp);
}

// seperated so can have other uses!
function bool IsDefaultPackage (string PkgName)
{
	Switch (PkgName)
	{
		//Begin standard UT Packages:
		Case "BotPack":
		Case "Core":
		Case "Editor":
		Case "Engine":
		Case "Fire":
		Case "IpDrv":
		Case "IpServer":
		Case "UnrealI":
		Case "UnrealShare":
		Case "UBrowser":
		Case "UTBrowser":
		Case "UMenu":
		Case "UWindow":
		Case "UTMenu":
		Case "UTServerAdmin":
		Case "UWeb":
		Case "Belt_fx":
		Case "LadderFonts":
		Case "UWindowFonts":
		Case "LadrArrow":
		Case "LadrStatic":
		Case "Botmca9":
		Case "Botpck10":
		Case "Cannon":
		Case "Colossus":
		Case "Course":
		Case "Credits":
		Case "Ending":
		Case "Enigma":
		Case "firebr":
		Case "Foregone":
		Case "Godown":
		Case "Lock":
		Case "Mech8":
		Case "Mission":
		Case "Nether":
		Case "Organic":
		Case "Phantom":
		Case "Razor-ub":
		Case "Run":
		Case "Savemeg":
		Case "SaveMe":
		Case "Seeker":
		Case "Seeker2":
		Case "Skyward":
		Case "Suprfist":
		Case "UnWorld2":
		Case "utmenu23":
		Case "Uttitle":
		Case "Wheels":
		Case "Activates":
		Case "Addon1":
		Case "AmbCity":
		Case "AmbAncient":
		Case "AmbModern":
		Case "AmbOutside":
		Case "Announcer":
		Case "BossVoice":
		Case "DDay":
		Case "DMatch":
		Case "DoorsAnc":
		Case "DoorsMod":
		Case "Extro":
		Case "Female1Voice":
		Case "Female2Voice":
		Case "FemaleSounds":
		Case "LadderSounds":
		Case "Male1Voice":
		Case "Male2Voice":
		Case "MaleSounds":
		Case "noxxsnd":
		Case "openingwave":
		Case "Pan1":
		Case "rain":
		Case "TutVoiceAS":
		Case "TutVoiceCTF":
		Case "TutVoiceDM":
		Case "TutVoiceDOM":
		Case "VRikers":
		Case "ArenaTex":
		Case "BossSkins":
		Case "castle1":
		Case "city":
		Case "commandoskins":
		Case "Coret_FX":
		Case "Creative":
		Case "credits":
		Case "Crypt2":
		Case "Crypt_FX":
		Case "CTF":
		Case "DacomaFem":
		Case "DacomaSkins":
		Case "DDayFX":
		Case "DecayedS":
		Case "DMeffects":
		Case "Egypt":
		Case "EgyptPan":
		Case "eol":
		Case "Faces":
		Case "FCommandoSkins":
		Case "Female1Skins":
		Case "Female2Skins":
		Case "FlareFX":
		Case "FractalFX":
		Case "GothFem":
		Case "GothSkins":
		Case "Indus1":
		Case "Indus2":
		Case "Indus3":
		Case "Indus4":
		Case "Indus5":
		Case "Indus6":
		Case "Indus7":
		Case "Lian-X":
		Case "Logo":
		Case "Male1Skins":
		Case "Male2Skins":
		Case "Male3Skins":
		Case "Metalmys":
		Case "Mine":
		Case "NivenFX":
		Case "of1":
		Case "Old_FX":
		Case "Palettes":
		Case "PhraelFx":
		Case "RainFX":
		Case "RotatingU":
		Case "Scripted":
		Case "SGirlSkins":
		Case "ShaneChurch":
		Case "SkTrooperSkins":
		Case "SkyBox":
		Case "Slums":
		Case "Soldierskins":
		Case "TrenchesFX":
		Case "UT":
		Case "UTbase1":
		Case "UTtech1":
		Case "UTcrypt":
		Case "UTtech2":
		Case "UTtech3":
		Case "UT_ArtFX":
		Case "XbpFX":
		Case "AlfaFX":
		Case "Ancient":
		Case "ChizraEFX":
		Case "BluffFX":
		Case "Crypt":
		Case "Detail":
		Case "FireEng":
		Case "GenEarth":
		Case "GenFluid":
		Case "GenFX":
		Case "GenIn":
		Case "GenTerra":
		Case "GenWarp":
		Case "GreatFire":
		Case "GreatFire2":
		Case "HubEffects":
		Case "ISVFX":
		Case "JWSky":
		Case "LavaFX":
		Case "Liquids":
		Case "NaliCast":
		Case "NaliFX":
		Case "PlayrShp":
		Case "Queen":
		Case "Render":
		Case "ShaneDay":
		Case "ShaneSky":
		Case "Skaarj":
		Case "SkyCity":
		Case "SpaceFX":
		Case "Starship":
		Case "TCrystal":
		Case "Terranius":
		Case "XFX":
			return true;
	}
	return false;
}
//check through hard-coded list of files that can be hidden (I assume case is insensitive?). set PBI as well.
function CheckPBI(PackageBasicInfoCW PBI)
{
	local string temp;
	temp = PackageName;
	//insert mapname check here!
	if (InStr(temp, ".") != -1)       //I'd rather check with suffix, but old demos + downlaoded files do not give it.
		temp = Left(temp, InStr(temp, "."));
	if (Left(temp,4) ~= "cshp")
	{
//		bPBIshows = true;
		bIsCSHP = True;
		PBI.CSHPVer.SetValue(Caps(temp));
		PBI.CSHPIns = bInstalled > NotInstalled;
		return;
	}
	if (Left(temp, 6) ~= "utpure")
	{
//		bPBIshows = true;
		bIsCSHP = true;
		PBI.CSHPVer.SetValue("UTPure" $ mid(temp, 6));
		PBI.CSHPIns = bInstalled > NotInstalled;
		return;
	}
	if (IsDefaultPackage(temp))
	{
		bPBIShows = true;
		return;
	}
	switch (temp)
	{
		//Bonus Pack 1 ///
		Case "relics":
		Case "multimesh":
		Case "epiccustommodels":
		case "relicsbindings":
		Case "tnalimeshskins":
		Case "tcowmeshskins":
		Case "tskmskins":
		// end bonus pack 1 ////
			PBI.UsesBp1 = true;
			PBI.Bp1INS = bInstalled == Installed;
			bPBISHows=true;
			break;
		// Bonus Pack 4 ///
		Case "SkeletalChars":
		Case "Factory":
		Case "SGTech1":
		//end bonus pack 4///
			PBI.UsesBp4 = true;
			PBI.Bp4INS = bInstalled == Installed;
			bPBISHows = true;
			break;
		// Rocket Arena ///
		Case "RocketArena":
		Case "RocketArenaMedia":
		Case "RocketArenaMultimesh":
		Case "xutfx":
		//end rocket arena///
			PBI.UsesRA = true;
			PBI.RAINS = bInstalled == Installed;
			bPBISHows = true;
			break;
	}
}

function bool ShowThisItem()
{
	return class'DemoSettings'.default.Displaymode == 0 || 
		(class'DemoSettings'.default.DisplayMode == 1 && !bPBIShows) ||
		(class'DemoSettings'.default.DisplayMode == 2 && bInstalled == NotInstalled);
}

function SortByColumn(int Column)
{
	if (class'DemoSettings'.default.SortColumn == Column)
		class'DemoSettings'.default.bDescending = !class'DemoSettings'.default.bDescending;
	else
	{
		class'DemoSettings'.default.SortColumn = Column;
		class'DemoSettings'.default.bDescending = False;
	}

	Sort();
}

function int Compare(UWindowList T, UWindowList B)
{
	local int Result;
	local DemoList PT, PB;

	if (B == None)
		return -1;

	PT = DemoList(T);
	PB = DemoList(B);

	switch(class'DemoSettings'.default.SortColumn)
	{
		case 0:
			if (Caps(PT.PackageName) < Caps(PB.PackageName))
				Result = -1;
			else
				Result = 1;
			break;
		case 1:
			if (PT.PackageSize > PB.PackageSize)
				Result = -1;
			else if (PT.PackageSize < PB.PackageSize)
				Result = 1;
			else if(Caps(PT.PackageName) < Caps(PB.PackageName))
				Result = -1;
			else
				Result = 1;
			break;
		case 2:
			if (PT.bInstalled < PB.bInstalled)
				Result = -1;
			else if (PT.bInstalled > PB.bInstalled)
				Result = 1;
			else if (Caps(PT.PackageName) < Caps(PB.PackageName))
				Result = -1;
			else
				Result = 1;
			break;
	}

	if (class'DemoSettings'.default.bDescending)
		Result = -Result;

	return Result;
}

defaultproperties
{
	bInstalled=1
}
