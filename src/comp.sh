rm DemoInterface.o
rm udnative.o
rm UuDriver.o
rm UZhandler.o
rm ../../System/udemo.so

# compile and output to this folder -> no linking yet!
gcc-2.95  -c -D__LINUX_X86__ -fno-for-scope -O2 -fomit-frame-pointer -march=pentium -D_REENTRANT -fPIC \
-DGPackage=udemo -Werror -I../inc -I../../Core/Inc -I../../Engine/Inc \
-o../../udemo/src/DemoInterface.o DemoInterface.cpp

gcc-2.95  -c -D__LINUX_X86__ -fno-for-scope -O2 -fomit-frame-pointer -march=pentium -D_REENTRANT -fPIC \
-DGPackage=udemo -Werror -I../inc -I../../Core/Inc -I../../Engine/Inc \
-o../../udemo/src/udnative.o udnative.cpp

gcc-2.95  -c -D__LINUX_X86__ -fno-for-scope -O2 -fomit-frame-pointer -march=pentium -D_REENTRANT -fPIC \
-DGPackage=udemo -Werror -I../inc -I../../Core/Inc -I../../Engine/Inc \
-o../../udemo/src/UuDriver.o UuDriver.cpp

gcc-2.95  -c -D__LINUX_X86__ -fno-for-scope -O2 -fomit-frame-pointer -march=pentium -D_REENTRANT -fPIC \
-DGPackage=udemo -Werror -I../inc -I../../Core/Inc -I../../Engine/Inc \
-o../../udemo/src/UZhandler.o UZhandler.cpp

gcc-2.95  -c -D__LINUX_X86__ -fno-for-scope -O2 -fomit-frame-pointer -march=pentium -D_REENTRANT -fPIC \
-DGPackage=udemo -Werror -I../inc -I../../Core/Inc -I../../Engine/Inc \
-o../../udemo/src/UDNotify.o UDNotify.cpp


# link with UT libs
# -Wl,-rpath,. -shared
# -lm -ldl -lnsl -lpthread
gcc-2.95  -shared -o ../../System/udemo.so -Wl,-rpath,. \
-export-dynamic -Wl,-soname,udemo.so \
-lm -lc -ldl -lnsl -lpthread ./DemoInterface.o ./udnative.o ./UuDriver.o ./UZhandler.o ./UDNotify.o \
../../System/Core.so ../../System/Engine.so

