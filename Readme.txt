===============================================================================
                           ______   _______  _______  _______ 
                 |\     /|(  __  \ (  ____ \(       )(  ___  )              
                 | )   ( || (  \  )| (    \/| () () || (   ) |
                 | |   | || |   ) || (__    | || || || |   | |
                 | |   | || |   | ||  __)   | |(_)| || |   | |
                 | |   | || |   ) || (      | |   | || |   | |
                 | (___) || (__/  )| (____/\| )   ( || (___) |
                 (_______)(______/ (_______/|/     \|(_______)
                                             

                      Unreal Tournament Demo Manager 3.5    
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

Demo Manager 3.5 is an updated version of the original UT demo manager. While
the interface and functionality hasn't changed much, demo manager 3.5 does
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
2) Open Unrealtournament.ini (in the system directory)
3) Find the line that says DemoRecordingDevice=Engine.DemoRecDriver
4) Change it to: DemoRecordingDevice=udemo.uDemoDriver

Failure to perform steps 2-4 will prevent usage of the speed control, pausing,
seeking, or any other nice feature of the new demo driver!

3) Change log
-------------

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

===============================================================================
