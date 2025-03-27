@echo off
ECHO --- Deleting Old Files...
del udemo.u

ECHO --- Compiling udemo...
ucc make -nobind -bytehax -packages=udemo

ECHO --- All done!
