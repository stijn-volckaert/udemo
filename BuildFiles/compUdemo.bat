@echo off
ECHO --- Deleting Old Files...
del udemo.u

ECHO --- Switching to hacked engine...
del Engine.u
copy Engine.hacked Engine.u

ECHO --- Setting up ini file...
copy UnrealTournament.ini UnrealTournament.old
del UnrealTournament.ini
copy compUdemo.ini UnrealTournament.ini

ECHO --- Compiling udemo...
ucc make -nobind

ECHO --- Restoring ini...
del UnrealTournament.ini
rename UnrealTournament.old UnrealTournament.ini

ECHO --- Restoring engine...
del Engine.u
copy Engine.clean Engine.u

ECHO --- All done!