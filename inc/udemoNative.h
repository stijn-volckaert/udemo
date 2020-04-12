/*=============================================================================
	udemoNative.h: Native function lookup table for static libraries.
	Copyright 2020 OldUnreal. All Rights Reserved.

	Revision history:
		* Created by Stijn Volckaert
=============================================================================*/

#ifndef UDEMONATIVE_H
#define UDEMONATIVE_H

DECLARE_NATIVE_TYPE(udemo, UUZHandler);
DECLARE_NATIVE_TYPE(udemo, Uudnative);
DECLARE_NATIVE_TYPE(udemo, UDemoInterface);

#if __STATIC_LINK
#define AUTO_INITIALIZE_REGISTRANTS_UDEMO \
	UUZHandler::StaticClass();\
	Uudnative::StaticClass();\
	UDemoInterface::StaticClass();\
	UDReader::StaticClass();\
	UuDemoDriver::StaticClass();\
	UuDemoPackageMap::StaticClass();\
	UuDemoConnection::StaticClass();
#endif


#endif
