/*=============================================================================
	udemoNative.cpp: Native function lookup table for static libraries.
	Copyright 2020 OldUnreal. All Rights Reserved.

	Revision history:
		* Created by Stijn Volckaert
=============================================================================*/

#include "udemoprivate.h"

#if __STATIC_LINK

#define NAMES_ONLY
#define NATIVES_ONLY
#define AUTOGENERATE_NAME(a)
#define AUTOGENERATE_FUNCTION(a,b,c)
#include "udemoClasses.h"

#endif
