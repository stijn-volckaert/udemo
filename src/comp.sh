rm DemoInterface.o
rm udnative.o
rm UuDriver.o
rm UZhandler.o
rm ../../System/udemo.so

# compile and output to this folder -> no linking yet!
gcc-7  -c -D__LINUX_X86__ -O2 -fomit-frame-pointer -march=pentium -D_REENTRANT -fPIC \
	   -DDO_RYANS_HACKY_GUARD_BLOCKS=1\
	   -DGPackage=LocalPackageNameudemo -Werror -I../inc -I../../Core/Inc -I../../Engine/Inc \
	   -I../../SDL2/include \
	   -o../../udemo/src/DemoInterface.o DemoInterface.cpp

gcc-7  -c -D__LINUX_X86__ -O2 -fomit-frame-pointer -march=pentium -D_REENTRANT -fPIC \
	   -DDO_RYANS_HACKY_GUARD_BLOCKS=1\
	   -DGPackage=LocalPackageNameudemo -Werror -I../inc -I../../Core/Inc -I../../Engine/Inc \
	   -I../../SDL2/include \
	   -o../../udemo/src/udnative.o udnative.cpp

gcc-7  -c -D__LINUX_X86__ -O2 -fomit-frame-pointer -march=pentium -D_REENTRANT -fPIC \
	   -DDO_RYANS_HACKY_GUARD_BLOCKS=1\
	   -DGPackage=LocalPackageNameudemo -Werror -I../inc -I../../Core/Inc -I../../Engine/Inc \
	   -I../../SDL2/include \
	   -o../../udemo/src/UuDriver.o UuDriver.cpp

gcc-7  -c -D__LINUX_X86__ -O2 -fomit-frame-pointer -march=pentium -D_REENTRANT -fPIC \
	   -DDO_RYANS_HACKY_GUARD_BLOCKS=1\
	   -DGPackage=LocalPackageNameudemo -Werror -I../inc -I../../Core/Inc -I../../Engine/Inc \
	   -I../../SDL2/include \
	   -o../../udemo/src/UZhandler.o UZhandler.cpp

gcc-7  -c -D__LINUX_X86__ -O2 -fomit-frame-pointer -march=pentium -D_REENTRANT -fPIC \
	   -DDO_RYANS_HACKY_GUARD_BLOCKS=1\
	   -DGPackage=LocalPackageNameudemo -Werror -I../inc -I../../Core/Inc -I../../Engine/Inc \
	   -I../../SDL2/include \
	   -o../../udemo/src/UDNotify.o UDNotify.cpp


# link with UT libs
# -Wl,-rpath,. -shared
# -lm -ldl -lnsl -lpthread
# 	   -export-dynamic -Wl,-soname,udemo.so \
gcc-7  -shared -o ../../System/udemo.so -Wl,-rpath,'${ORIGIN}' \
	   -lm -lc -ldl -lpthread ./DemoInterface.o ./udnative.o ./UuDriver.o ./UZhandler.o ./UDNotify.o \
	   ../../System/Core.so ../../System/Engine.so

