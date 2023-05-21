/*=============================================================================
	udemoNative.cpp: Native function lookup table for static libraries.
	Copyright 2020 OldUnreal. All Rights Reserved.

	Revision history:
		* Created by Stijn Volckaert
=============================================================================*/

#include "udemoprivate.h"

#if __STATIC_LINK
#include "udemoNative.h"

UUZHandlerNativeInfo GudemoUUZHandlerNatives[] =
{
	MAP_NATIVE(UUZHandler, execForceSave)
	MAP_NATIVE(UUZHandler, execSaveFile)
	MAP_NATIVE(UUZHandler, execAppend)
	{NULL, NULL}
};
IMPLEMENT_NATIVE_HANDLER(udemo, UUZHandler);

UudnativeNativeInfo GudemoUudnativeNatives[] =
{
	MAP_NATIVE(Uudnative, execDispatchTick)
	MAP_NATIVE(Uudnative, execDemoRead)
	MAP_NATIVE(Uudnative, execIsMisMatch)
	MAP_NATIVE(Uudnative, execGUIDString)
	MAP_NATIVE(Uudnative, execDemoActive)
	MAP_NATIVE(Uudnative, execFindViewPort)
	MAP_NATIVE(Uudnative, execGetArray)
	MAP_NATIVE(Uudnative, execWriteDemoInfo)
	MAP_NATIVE(Uudnative, execBasePath)
	MAP_NATIVE(Uudnative, execRename)
	MAP_NATIVE(Uudnative, execkill)
	MAP_NATIVE(Uudnative, execgetdemo)
	MAP_NATIVE(Uudnative, execSetDemoDriverClass)
	{NULL, NULL}
};
IMPLEMENT_NATIVE_HANDLER(udemo, Uudnative);

UDemoInterfaceNativeInfo GudemoUDemoInterfaceNatives[] =
{
	MAP_NATIVE(UDemoInterface, execGetStartTime)
	MAP_NATIVE(UDemoInterface, execSetPlayBackMode)
	MAP_NATIVE(UDemoInterface, execIsPaused)
	MAP_NATIVE(UDemoInterface, execPauseDemo)
	MAP_NATIVE(UDemoInterface, execGetTotalFrames)
	MAP_NATIVE(UDemoInterface, execGetCurrentFrame)
	MAP_NATIVE(UDemoInterface, execGetTotalTime)
	MAP_NATIVE(UDemoInterface, execGetCurrentTime)
	MAP_NATIVE(UDemoInterface, execReadCache)
	MAP_NATIVE(UDemoInterface, execReadTo)
	MAP_NATIVE(UDemoInterface, execJumpBack)
	MAP_NATIVE(UDemoInterface, execSetSpeed)
	{NULL, NULL}
};
IMPLEMENT_NATIVE_HANDLER(udemo, UDemoInterface);

void InitUdemo()
{
	// stijn: gets called by the launcher when it's safe to register names
#define NAMES_ONLY
#define AUTOGENERATE_NAME(name) UDEMO_##name=FName(TEXT(#name),FNAME_Intrinsic);
#define AUTOGENERATE_FUNCTION(cls,idx,name)
#include "udemoClasses.h"
#undef AUTOGENERATE_FUNCTION
#undef AUTOGENERATE_NAME
#undef NAMES_ONLY

}

#endif
