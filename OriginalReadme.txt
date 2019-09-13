================================================================
Title                   : UNREAL TOURNAMENT DEMO MANAGER
Version			: 2.01
Filenames               : udemo.u, udemo.dll, udemo.int
Coding:			: UsAaR33 + the people below
Email Address           : udemo@usaar33.com
Web Page                : http://www.usaar33.com
Special Thanks		: Cerr (miscellaneous help)
			  DarkByte (Help with the wonderful FSTRINGS)
			  Mongo: The l33t one! Immense ammounts of help. Basically, making udemo possible!
			  Yoda Help with C++ based detection of active demo recordings/playings)
			  Cerr (miscellaneous help)
			  TNSe: Fixing the demo driver, code (message restoration) ideas, inspiration, etc.
			  Pavel: Making (and coding) the interface look MUCH BETTER!
			  Garfield: Spectator Interpolation code
			  Jack Porter: Making Demos possible :)
			  
================================================================
--- What's new in version 3.0 BETA? ---
WARNING: THIS IS A BETA VERSION! THAT MEANS THERE ARE BUGS.  MAYBE LITTLE, MAYBE MANY. DON'T SAY I DIDN'T WARN YOU :P

-Entire new demo driver!
	Features:
	-Pausing demo
	-controlling demo speed
	-seeking to any point in the demo
	-Transitioning between playmodes and 3rd/1st person modes during playback
	-Recording: Unloads demo file when done recording/playing.  Thus, you can safely delete a demo file 
after playing or recording.
	-Smoother playback in noframecap mode.
-UZ REDIRECT SERVER DOWNLOADING!
	15 redirect servers have been hard-coded by default. In case a demo lacks a file, udemo will ask you if you would like to download the missing files.  Hopefully, it'll be able to find it on these servers (80% of the time it will).  If not, you are SOL.
-GUI changed around. Thx to Pavel for coding it!
-Pre-demo playing file requirements mismatch checking! And if there is a version mismatch, you can use the download the correct version!
-screenshot window now tells length, frames, and average FPS of demo
-demo summary now shows file size of custom files (seemed people wanted)
-hack-fixes to add minigun, pulsegun, and impact hammer sound effects back in.
-3RD person in client demos works near flawlessly now
-in playback, in first person, your weapon hand settings are used for the player you are viewing (so you control where the weapon is seen on all players)
-LIMITED ability to rotate view of players during pausing.  I'll really need help from epic though to pull this off correctly though :p
-jolt demo enhancer 2 code for multikill/killing spree message restoration!
-smoother first person rotation changes in spectator demos and when viewing other players in client demos
-no longer need to open manager to start auto-record!
-solved the auto-record not always working and other bugs in 2.01

-Please note that version 2.01 merely fixes a bug where rename would crash.

--- What's new in version 2.0? ---

Unreal Tournament Demo Manager (Udemo) Version 2.0 makes 1.0 look like nothing!
Here is a full list of new features!

-Demo Analyzer:  This baby tells you EVERY file that you need to play the demo.  There is no more worrying about demos crashing because you lacked some necessary file!  On top of that, it tells the mapname and the type of demo (client or recorded server-side on a dedicated server).
-Summary Generator:  This button will write an information txt file about the demo that can be easily distributed with demos.  You will know exactly what files you need to include with the demo and others downloading it will know what packages they need. (see below for more info)
-Multiple Path support: UDEMO now supports demos in other directories besides the ut system directory!
-Auto-Recording:  Ever wanted to record a demo of every game you play?  This new feature allows you to do this with ease!  UDEMO will detect level changes and automatically record a demo, using the format that YOU specify.
-All options you select are saved when UT closes!
-Window stays in memory.  Closing does not destory the window, but merely hides it!
-Some interface changes.
-Many other improvements and bug fixes.

===============================================================

================================================================
--- Description ---

Unreal Tournament has a truly remarkable and complex demo recording and playback system.  There was only one major problem.
WHERE IS THE BROWSER????
This utility/mod fixes that issue.  It brings about the following enhancements:
-An easy to-use, quickly loading, in-game browser of demos.  You can choose to play any demo found in the configurable demo directories.
-Additional Options to record, stop, rename, and delete demos.
-All 3 demo options (3rdperson, noframecap, timebased) are easily selectable.  And yes, the loop option is intentionally not there.
-Fixes the annoying player name being reset bug. (note that for this to work, you must play demos from the manager itself)
-All that new stuff in the above paragraph :)
===============================================================

--- Using the new demo playback system---
Because the beta lacks new menu systems to control playback, I'll just list anything that isn't straightforward here:
Stuff in udemo.ini that isn't configurable in menus (ini created after UT initially run):
RedirectServers[n]: Currently the menu only allows configuration of 6.. I kinda need to recode it.  Anyhow, feel free to set up to #23. Be sure to email udemoservers@usaar33.com if you find new redirect servers with a sizable ammount of files!
CacheSeconds: For seeking. Make higher for more "accuracy" in world after seek.
TickSize: For seeking. LOWER (but MUST be >0) for more "accuracy" in world after seek.
(Note: more accuracy of course means seeking takes more time :p)
InterpolateView: Set to false to disable the GARFIELD rotational smoothing code in first person.

During playback:
PAUSE KEY: This will pause the demo...
FIRE KEY (in 3rd person): View next player
Console commands during playback: (x denotes a number!)
-StopDemo: Stops playback
-slomo x: Controls speed of playback.  (e.g. slomo 0.5 sets speed to 50% of normal, slomo 2.0 sets to 200% of normal, slomo 1.0 is normal).  NOTE: I recommend using values >0.2 and <4.0
-CurTime: Tells how long demo has been playing in DEMO TIME. (i.e. how many seconds in game since start of demo)
-CurFrame: Tells what frame # the demo is currently reading from
-TotalTime: The total ammount of time the demo lasts (NOT REMAINING TIME) at speed 1.0 in seconds
-TotalFrames: The total ammount of frames the demo contains
-Spectate: Go into spectator mode (as though 3rd person was checked)
-Behindview 1/0: toggle behindview! (I recommend you bind a key to this)
-FirstPerson: Go into first person mode (as though 3rd person was not checked). Does not work in server demos!
-PlayBack x: Toggle playback mode mid-demo.  0=timebased, 1=framebased, 2=noframecap
-SeekTo x: The ULTIMATE COMMAND.  Seek to the demo at time x. (i.e. seekto 130 goes to the 2 minute, 10 second mark).
-Viewself: View from the spectator in 3rd person mode
-ViewRecorder: view from the player who recorded the demo. (only client demos!)
-FollowPlayer: View from the player you are currently looking at.
-FindFlags: View from the flags in a CTF game.


===============================================================

--- Requirements---

Because this mod makes use of Dynamic Linked Libraries (DLL's), it requires a Win32 based system (Windows 9x, NT, 2000, ME) and UT version 432 or higher.  If you are interested in porting the mod to other OS's please e-mail me for more information.

===============================================================

--- CSHP/UTPure Issues ---

Just because I do not wish to be spammed with e-mails over this question, I will say this once and once only:
UDEMO will not be falsely detected as a cheat under any past, present, or future CSHP/UTPure version.  It is completely safe to use the mod during multiplayer games.

===============================================================

--- BETA ISSUES---
It's a beta.. its going to have problems.  Report them to udemo@usaar33.com
-Seeking backward, in rare cases, may crash UT or screw up the demo. Please report any foul-ups and send the demo and logs!
-Seeking forward works quite well, though you may hear wierd sounds for half a second after the seek.
-Seeking does take awhile.. be patient :p (ok.. if it takes more than 3 minutes, your computer is locked up and that would be a bug).
-Downloader takes awhile to detect if a server is not responding.. be patient.
-behindview doesn't work right in 1st person playback mode.  Just use 3rd person.  (this will be fixed in 3.5)
-NOT A DEMO PLAYBACK ISSUE, BUT MANY PEOPLE WILL BE BUGGING ME ABOUT THIS: In client demos, other players WILL disappear (after they loose their weapon, etc.) if you try to view from them.  This is because of UT's netcode.  Basically, the server, at recording time, stopped sending updates about them, thus the client did not know about them anymore = playback does not either.
-Speed control does not work in noframecap mode (wouldn't make sense).  And please don't play at 20% in frame based.  This causes your frame rate to be reduced by 1/5 as well.. (in fact.. timebased is easily the best playback mode).

================================================================

================================================================

--- Installation--

See the installation.txt file.  I make installation less user friendly for betas :)

================================================================

--- Usage--

Please see the UdemoInterface.JPG file for a visual explaination of the menus.
I recommend enabling status help when learning the interface.
Special features:

-Requirements Table:
Please note that custom packages are defined as being non-default, not found in Bonus Pack 1, not found in Bonus Pack 4, and not the demo's map itself.
-Auto-Recording: To make this work, you must open the demo manager every time UT starts up.  I would have loved to make it automatic, but because of Version 432, this is not possible.  Also note that auto-recording occurs after the next level change, not in the current level.  Furthermore, auto-recording is "smart" in that it will never overwrite another demo (it will simply substitute the %n with a number increment or add -(number increment) at the end.  Oh, and if you want a summary made, you will need to select the demo (after recording is finished) and generate one yourself.
-Formatting for Auto-Record: I have chosen to take the most flexible path toward custom formatting.  Any legal character for file names or "flags" may be entered.  Valid flags are desribed on that menu page.  Flags are substituted with other information (server name, time, etc.)
-Stop and Record Buttons: You cannot stop a demo if one is not being played or recorded.  You cannot record a demo if one is already being played or recorded.  Consequently, both buttons are never hidden or shown together.
-Analyzing: Analyzing has a small glitch where it cannot tell if a demo file is invalid.  If the screenshot window continues to say it is reading information, but no activity can be seen in the table window, that demo is probably faulty and should be deleted.
-Summary Button:  Clicking on the summary button will save a (demoname)Info.txt file in the directory where that demo is located.  For instance, a demo named "cool.dem" in the system directory would save a file called CoolInfo.txt in the system directory.
A summary looks as follows (from the file newbieownageInfo.txt):
------------------------------------------------------
Demo summary auto-generated by Unreal Tournament Demo Manager 3.0 BETA
Available at http://www.usaar33.com

DM-Deck16][+10-27`1-2.dem Information:
Map name: DM-Deck16][.unr
Demo Type: Client-Side
42306 frames
PlayTime: 10:46 (min:seconds)
Avg. FPS: 65.448257
Cheat Protection: UTPureRC53.U (cached as '2B6371C011D6AC101000C2A34E0C0BA7.uxx')

File Requirements:
-Bonus Pack 4
BP4Handler53.u (cached as '2A3E79C011D6AC101000C2A34E0C0BA7.uxx') -size: 6247 bytes
UTPureRC53.u (cached as '2B6371C011D6AC101000C2A34E0C0BA7.uxx') -size: 131731 bytes
-------------------------------------------------------
Note that the Package name as well as the cache name (that is the file name that package has when downloaded from a server into the cache folder) are given for all custom packages.

================================================================
--- Future Possibilities ---
Udemo 1.0 was all about a simple browser of demos.
Udemo 2.0 took the interface further with its analyzer, as well as adding a demo auto-record function and a summary generator.  It is all about information.
Udemo 3.0 BETA  was all about about fixes and actual demo enhancements. 
Udemo 3.5 (non beta 3.0 :p) will add a bunch of voice menus, other menus, etc. menus to use the enhancements :p
Also:
-server package editor, auto-setter for standalone demo recording
-Possible, but not likely: Demo udemo generator that includes demo, info TXT and all needed files.
-Any other ideas? Send 'em to udemoIdeas@usaar33.com

================================================================
Copyrights/Permissions
----------------------
Unreal Tournament (c) 1999 and UNREAL (c)1998 Epic Megagames, Inc.  All Rights Reserved.  
Distributed by GT Interactive Software, Inc. under license.  UNREAL and the UNREAL logo 
are registered trademarks of Epic Megagames, Inc. All other trademarks and trade
names are properties of their respective owners.