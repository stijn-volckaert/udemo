===============================================================================
                           ______   _______  _______  _______ 
                 |\     /|(  __  \ (  ____ \(       )(  ___  )              
                 | )   ( || (  \  )| (    \/| () () || (   ) |
                 | |   | || |   ) || (__    | || || || |   | |
                 | |   | || |   | ||  __)   | |(_)| || |   | |
                 | |   | || |   ) || (      | |   | || |   | |
                 | (___) || (__/  )| (____/\| )   ( || (___) |
                 (_______)(______/ (_______/|/     \|(_______)
                                             

                      Unreal Tournament Demo Manager 3.6    
                by UsAaR33 (until v3.0) and AnthraX (after v3.0)
		
===============================================================================

1) Description
--------------

UsAaR33's UT demo manager adds a lot of functionality to the Unreal Tournament
demo recording and playback system. Some of the key features are:
* A convenient demo browser that lists demos + packages required to play them
* A uz downloader that can download and install packages required for playback
* Commands to record, stop, rename, and delete demos
* 3rd person demo playback
* Demo speed control, seeking, pausing, ...
* ... and many many more (see OriginalReadme.txt for an overview)

Demo Manager 3.6 is an updated version of the original UT demo manager. While
the interface and functionality hasn't changed much, demo manager 3.6 does
include a lot of fixes for rendering glitches, crashes, etc. It also restores a
lot of functionality that broke because of anti-cheat tools such as UTPure,
UTDC, AnthChecker, ACE, etc.

Demo Manager is an open source mod. The code is available at:
https://github.com/stijn-volckaert/udemo

I am accepting pull requests!

2) Installation
---------------

1) Extract every file to the system directory of Unreal Tournament. (e.g.,
c:\unrealtournament\system)

2) Run UnrealTournament
3) Open Demo manager via game mod menu
4) Change demo driver to "udemo" and restart game

or do the same by manual edit ini files:

2) Open Unrealtournament.ini (in the system directory)
3) Find the line that says DemoRecordingDevice=Engine.DemoRecDriver
4) Change it to: DemoRecordingDevice=udemo.uDemoDriver

Failure to perform steps 2-4 will prevent usage of the speed control, pausing,
seeking, or any other nice feature of the new demo driver!

3) Change log
-------------

v3.6.0:
* [FIXED] Lost weapon in some cases
* [FIXED] Missed leading zeroes for date placeholders
* [FIXED] Crash with endless recursion in DemoPlaybackSpec.PlayerCalcView
* [FIXED] Code format and indent on it
* [FIXED] Show demo manager window out-of-screen
* [FIXED] Many flood in the log
* [FIXED] Start demo play from demo manager
* [FIXED] Download missed files for demos
* [FIXED] Prevent play demo in some cases (wrong order of load packages)
* [FIXED] Start autorecord demo on reconnect to same map
* [FIXED] Crash on load UT with too many demo files
* [FIXED] Speed up sort demo list and reduce delay for first load UT menu
* [FIXED] Camera affected by change speed of demo play (slomo command)
* [FIXED] Cropped text in demo manager in some cases
* [FIXED] Play demo recorded from spectator
* [FIXED] Use too small playback speed
* [FIXED] Autorecord demo if UT started with server address (partially - on first load menu via press escape)
* [FIXED] Wrong demoplay (jitter) when used slomo together with rewind back
* [FIXED] Sniper rifle not zooming
* [FIXED] Walkbob not work
* [FIXED] ImpactHammer charging state
* [FIXED] HUD in spectator mode
* [FIXED] Double HUD spawn
* [FIXED] Show custom shield effects on first-person view
* [FIXED] Show scoreboard in some mods like SmartSB
* [FIXED] Show endgame cameras
* [FIXED] Work some mods in some cases
* [FIXED] Voice messages not play
* [FIXED] Mods windows not show (like map vote or nexgen console)
* [FIXED] XConsole break demo play if user click mouse during it
* [FIXED] Accuracy for SeekTo
* [FIXED] Play sounds during SeekTo
* [FIXED] Additional unwanted steps sounds
* [FIXED] Some weird effects if udemo loaded twice (by another mod for example, like rypelcam)
* [FIXED] Camera look during crouch and feign death in first-person view
* [FIXED] Game time broke after SeekTo
* [FIXED] Not precise demo play in frame-based mode on high FPS
* [FIXED] Show own nickname in HUD in some cases, like walk on stairs or slopes
* [ADDED] "Cancel" button in the dialog for files mismatch and allow anyway try play demo
* [ADDED] Camera can be moved during pause, however, for use mouse look you must use fullscreen mode
* [ADDED] SeekTo command now accept relative values (use "+" or "-" before number) and/or percentage values (use "%" after number)
* [ADDED] Command "SetPauseText", which allow alter or hide pause message:
	SetPauseText hide - hide pause message
	SetPauseText Some text - make pause message as "Some text"
	SetPauseText - restore default text.
* [ADDED] Ability change demo driver from Demo manager GUI
* [ADDED] Ability sort demos by date in Demo manager GUI
* [ADDED] Ini option FollowMyCam, which force Camera follow spectate target, so when you detach cam it not jump to old position, but continue from last spectated target position (seamless transition)
* [ADDED] Command "FollowMyCam", which allow change FollowMyCam ini option
* [ADDED] Support for rypelcam properly work
* [ADDED] Command "SloMo2", which accept relative values (use "+" or "-" before number) and/or percentage values (use "%" after number)
* [CHANGED] Minor adjustments to the GUI to work better with v469's GUI scaling

v3.5.1:
* [FIXED] Demo manager no longer hangs while trying to play back truncated demos
* [FIXED] The camera now correctly follows guided warshells
* [CHANGED] Minor adjustments to the GUI to work better with v469's GUI scaling

v3.5:
* [ADDED] Compatibility with Unreal Tournament v469
* [FIXED] You can now, once again, save downloaded files in the cache folder
* [FIXED] Sniper rifle not zooming in
* [FIXED] Weapon rendering glitches
* [FIXED] Crashes after seeking back in a demo
* [CHANGED] Removed outdated redirect servers from the default config

v3.4 - Open source release:
* [CHANGED] Lots and lots of portability fixes. Demo Manager now works on
  Linux... sort of

v3.3 beta - build 2009/07/10:

* [ADDED] You can now disable autorecording while spectating trough a checkbox
  in the auto-record tab
* [FIXED] Extreme lag during demo playback (test this please)
* [FIXED] Level Time going out of sync after seeking (experimental! please test!)
* [FIXED] Missing hudmessages
* [FIXED] Small bugs in invisible flag fix	
	
v3.3 beta - build 2009/06/24:
* [FIXED] Invisible flags in CTF based games
* [FIXED] Downloader for missing packages either crashing or not working
* [FIXED] UT crashing while seeking (using the seekto command). While fixing
  this bug I've also been able to speed up the seeking.
* [FIXED] UT crashing when trying to view a second demo after finishing the
  first
* [FIXED] Error while closing down UT after viewing a demo
* [FIXED] Windows x64 crashes in the illegal actor cleanup routine	
* [CHANGED] Rewrote a lot of C++ routines for better stability and portability
	
v3.2 beta - build 2009/05/20:
* [FIXED] ServerInfo (F2) not showing
* [ADDED] You can now type "togglestats" in console to show the smartctf
  scoreboard (only works for 4D)
	
v3.2 beta - build 2007/01/27:
* [FIXED] The camera would sometimes start shaking for no reason (eg: while
  ducking)

v3.2 beta - build 2007/01/05:
* [FIXED] Weaponshow in demos recorded on UTPure7G servers
* [FIXED] Some issues with the viewrotation calculation. As a result of this
  fix, the screen will no longer "roll" while watching someone ineyes in a 3rd
  person demo (someone other than the demorecorder ofcourse...)
* [ADDED] Some minor tweaks to the demoplaybackspec code
	
v3.2 beta:
* [CHANGED] Moved the illegal actor destroying routine to the native side (dll)
* [FIXED] UTDC crashes in serverside demos

v3.1:
* [ADDED] Option to destroy illegal actors (such as the UTDC native check that
  crashes demos)
* [FIXED] Fixed Scoreboard and HUD problems in 3rd person demos (caused by Pure7G)
* [FIXED] Fixed Camera cycling problems in 3rd person demos (caused by Pure7G)
* [CHANGED] Cleaned up big parts of the code

v3.0 and below:
* See OriginalReadme.txt

4) Known issues
---------------
	
* Some messages are displayed twice in the console (broadcasted messages etc)

5) Credits
----------

* UsAaR33: Created and maintained demo manager until v3.0
* Cerr, DarkByte, Mongo, Yoda, TNSe, Pavel, Garfield, Jack Porter: for their
  substantial contributions to the original demo manager
* AnthraX: Started maintaining udemo after v3.0

6) Bugs and feedback
--------------------

Please use the issue tracker at https://github.com/stijn-volckaert/udemo to
report bugs.

7) Additional demo play commands
--------------------

Playback {0/1/2} - Switch to specified demo playback mode: 0 = timebased, 1 = framebased, 2 = noframecap.
SloMo speed - Change demo playback speed. Accept only absolute decimal value, like 0.1 0.5 1.0 2.0 and so on. 1.0 is normal speed.
SloMo2 [+/-]speed[%] - Change demo playback speed. Accept absolute decimal value, relative decimal value (use "+" or "-" before number) and/or percentage values (use "%" after number).
CurTime - Show current time position in the demo.
CurFrame - Show current frame position in the demo
TotalTime - Snow total time in the demo
TotalFrames - Snow total frames in the demo
StartTime - Show initial time-stamp for the demo. Time when player join to the game.
Now - Show bunch of different timers in the game. Mostly used for debug.
SeekTo [+/-]seconds[%] - Rewind demo to specified position in seconds. Accept absolute decimal value, relative decimal value (use "+" or "-" before number) and/or percentage values (use "%" after number).
Pause - Toggle pause mode for the demo
SetPauseText [hide/some text] - Set/hide/restore pause message. Without parameter restore default  pause message.
Spectate - Go to spectator mode (like 3rdperson parameter for demo play).
FirstPerson -  Go to first-person view mode (like without 3rdperson parameter for demo play). Not work for demos recorded on dedicated server.
ViewRecorder - View from the player who recoded the demo. Not work for demos recorded on dedicated server.
FollowMyCam {1/0} - Change ini option FollowMyCam, for seamless transition to free camera after end view some player.
FollowPlayer - View from the player on which you looking at (point crosshair).
ViewPlayer name - View from the player with specified name.
ViewPlayerNum [team] - View from the next player of specified team. If team negative - cycle view over all pawns.
Fire - Switch view to next pawn in spectator mode. Same as "ViewPlayerNum -1".
ViewSelf - return view to free camera.
AltFire - Switch view to free camera in spectator mode. Same as ViewSelf.
BehindView {1/0} - Set behind view mode on or off.
FindFlags - View from the flags in a CTF game.
SetAccel scale - Set scale for speed of camera movement. 1.0 is normal speed. 2.0 is faster in 2 times and so on.
Say some text - Display some text like it be send in game chat.
TeamSay some text - same as Say
ToggleStats - Toggle show SmartCTF stats.
StopDemo - Stop demo play.
Jump - Cycle over special spectator cameras points (SpectatorCam), if such placed on the map.
NextWeapon - View from the next pawn with ability return to previous view target via PrevWeapon.
PrevWeapon - View from previously view target if there any or switch view to the next pawn.
ViewClass Class [1] - Try view from next actor of specified class. If second parameter is 1, then not show message in the console/HUD.
CheatView Class  - Try view from next actor of specified class. Allow view some actors which not able view via ViewClass.

===============================================================================
