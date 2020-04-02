# CMP0091 enables MSVC_RUNTIME_LIBRARY support
if(COMMAND CMAKE_POLICY)
  if(POLICY CMP0091)
    cmake_policy(SET CMP0091 NEW)
  endif(POLICY CMP0091)
endif(COMMAND CMAKE_POLICY)

project(udemo)
cmake_minimum_required(VERSION 2.8.5)
set(CMAKE_MACOSX_RPATH 0)
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include(CheckCCompilerFlag)

if(WIN32 AND NOT WINDOWS)
  set(WINDOWS TRUE)
    # use multi-threaded version of C runtime lib and link it statically
  set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
endif()
if(APPLE AND NOT MACOSX)
  set(MACOSX TRUE)
endif()
if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
  set(LINUX TRUE)
endif()

if (NOT MACOSX)
  find_package(Threads REQUIRED)
endif()

if(NOT CMAKE_BUILD_TYPE)
  set(UT99_DEBUG_BUILD ON)
endif()
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
  set(UT99_DEBUG_BUILD ON)
endif()

if(NOT UT99_DEBUG_BUILD)
  add_definitions(-D_RELEASE)
  add_definitions(-DNDEBUG)
  add_definitions(-DRELEASE)
else()
  add_definitions(-D_DEBUG)
endif()

add_definitions(-DUTGLR_UT_BUILD)

OPTION(UT99_STATIC_LINK "True to statically link everything, False to build DLLs." FALSE)
if (NOT WINDOWS)
  OPTION(USE_ASAN "True to enable address sanitizer" FALSE)
endif()

# See what CPU we appear to be targeting...
#  It would be nice if CMake handled this for us.
macro(check_cpu _CDEFS _NAME _VALUE)
  check_c_source_compiles("
        #if ( ${_CDEFS} )
        int main(int argc, char **argv) { int yup = 1; return 0; }
        #else
        #error Not targeting this CPU architecture.
        #endif
        " ${_VALUE}
    )

  if(${_VALUE})
    if(UT99_CHOSE_CPU)
      MESSAGE(STATUS "We appear to see two different CPU architectures!")
      MESSAGE(STATUS "We saw '${UT99_CPU}' and '${_NAME}'.")
      MESSAGE(FATAL_ERROR "Please fix this before continuing.")
    endif()
    set(UT99_CHOSE_CPU TRUE)
    set(UT99_CPU ${_NAME})
  endif()
endmacro(check_cpu)

check_cpu(
  "defined(__i386__) || defined(__i686__) || defined(_M_IX86) || defined(i386)"
  "x86" UT99_X86
)

check_cpu(
  "defined(__x86_64__) || defined(_M_X64)"
  "amd64" UT99_AMD64
)

check_cpu(
  "defined(__EMSCRIPTEN__)"
  "emscripten" UT99_EMSCRIPTEN
  )

check_cpu(
  "defined(__arm__)"
  "arm" UT99_ARM
)

if (UT99_AMD64)
  set(STATIC_LIB_DIR "Lib64")
  set(SYSTEM_DIR "System64")
  set(CONF_DIR "build64")
elseif(UT99_ARM)
  set(STATIC_LIB_DIR "LibARM")
  set(SYSTEM_DIR "SystemARM")
  set(CONF_DIR "buildarm")  
else()
  set(STATIC_LIB_DIR "Lib")
  set(SYSTEM_DIR "System")
  set(CONF_DIR "build64")
endif()

if(NOT UT99_CHOSE_CPU)
  MESSAGE(STATUS "We don't appear to be targeting a CPU that we support.")
  MESSAGE(FATAL_ERROR "Please fix this before continuing.")
endif()

if(MACOSX)  # CMake reports CMAKE_SYSTEM_NAME as "Darwin" here...
  set(UT99_OS "macosx")
else()
  STRING(TOLOWER "${CMAKE_SYSTEM_NAME}" UT99_OS)
endif()

add_definitions(-DMOD_BUILD=1)
if(LINUX)
  check_c_compiler_flag("-fno-stack-protector" UT99_GCC_HAS_STACKPROT)
  if(UT99_GCC_HAS_STACKPROT)
    add_definitions(-fno-stack-protector)
  endif()

  # Don't use -rpath (at least, not the silly one CMake forces).
  set(CMAKE_SKIP_RPATH ON CACHE BOOL "Skip RPATH" FORCE )
  add_definitions(-DUNICODE=1)
  add_definitions(-D_UNICODE=1)  
  add_definitions(-D_REENTRANT=1)
  add_definitions(-DHAVE_PRAGMA_PACK=1)

  if (UT99_ARM)
	add_definitions(-D__LINUX_ARM__=1)
	add_definitions(-DSDL_DISABLE_MM3DNOW_H=1)
	add_definitions(-DSDL_DISABLE_IMMINTRIN_H=1)
	add_definitions(-DSDL_DISABLE_MMINTRIN_H=1)
	add_definitions(-DSDL_DISABLE_XMMINTRIN_H=1)
	add_definitions(-DSDL_DISABLE_EMMINTRIN_H=1)
	add_definitions(-DSDL_DISABLE_PMMINTRIN_H=1)
  else()	
	add_definitions(-D__LINUX_X86__=1)
	add_definitions(-msse)
	add_definitions(-msse2)
  endif()

  set(LIBRARY_SUFFIX ".so")
elseif(MACOSX)
  add_definitions(-DMACOSX=1)
  add_definitions(-DUNICODE=1)
  add_definitions(-D_UNICODE=1)  
  add_definitions(-D_REENTRANT=1)
  add_definitions(-DHAVE_PRAGMA_PACK=1)
  set(LIBRARY_SUFFIX ".dylib")
else()
  add_definitions(-D_CRT_SECURE_NO_WARNINGS=1)
  add_definitions(-D_CRT_NO_VA_START_VALIDATION)
  add_definitions(-DUNICODE=1)
  add_definitions(-D_UNICODE=1)
  add_definitions(-DWIN32=1)
  if (UT99_AMD64)
	add_definitions(-DWIN64=1)
  else()
	# do not treat wchar_t as a built-in type. Doing so would break binary compat
	# with almost all native mods for earlier UT versions
	add_definitions(/Zc:wchar_t-)  
	# assume we have at least a Pentium 4
	add_definitions(/arch:SSE2)
	# we can handle more than 2Gb of RAM even in 32bit builds
	add_definitions(/LARGEADDRESSAWARE)
  endif()
  # we need C++ exception handling with SEH exceptions, otherwise the crash handling code will break
  add_definitions(/EHa)
  # enable parallel builds
  add_definitions(/MP)
  # the recursive garbage collector needs a lot of stack space
  # set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} /STACK:64000000,1000000 /LTCG")
  set(LIBRARY_SUFFIX ".dll")
endif()

if(CMAKE_COMPILER_IS_GNUCC OR (CMAKE_CXX_COMPILER_ID MATCHES "Clang"))
  add_definitions(-pipe -fsigned-char -fno-strict-aliasing -fmessage-length=0 -Wno-inline-new-delete)
endif()

include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../Core/Inc)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../Engine/Inc)

if (UT99_STATIC_LINK)
  add_definitions(-D__STATIC_LINK=1)
  set(UT99_PACKAGE_LINKAGE STATIC)
else()
  set(UT99_PACKAGE_LINKAGE SHARED)
endif()

if (USE_ASAN)
  add_compile_options("-fsanitize=address")
  link_libraries("-fsanitize=address")
endif()

macro(ut99_set_package_properties _PACKAGE)
  string(TOUPPER "${_PACKAGE}" _UPACKAGE)
  if (WINDOWS AND NOT UT99_STATIC_LINK)
    # stijn: the GPackage symbol has local (intra-module) visibility on Windows
    # platforms so there's no need to give it a unique name here
    set_target_properties(${_PACKAGE} PROPERTIES COMPILE_DEFINITIONS "${_UPACKAGE}_API=__declspec(dllexport)" PREFIX "")
  elseif(WINDOWS AND UT99_STATIC_LINK)
    set_target_properties(${_PACKAGE} PROPERTIES COMPILE_DEFINITIONS "GPackage=LocalPackageName${_PACKAGE}" PREFIX "" )	
  else()
    # stijn: for WIN32 static and for NIX, we need to make sure that the various
    # GPackage symbols don't clash so we rename them using a preprocessor
    # definition
    set_target_properties(${_PACKAGE} PROPERTIES COMPILE_DEFINITIONS "GPackage=LocalPackageName${_PACKAGE}" PREFIX "" LINK_FLAGS "-Wl,-rpath,$ORIGIN")
  endif()

  # No need to depend on other packages when static linking, so we can build all in parallel.
  if (NOT UT99_STATIC_LINK)
    if(NOT ${_PACKAGE} STREQUAL "Core")
      target_link_libraries(${_PACKAGE} Core)
	  if(NOT ${_PACKAGE} STREQUAL "Engine")
        target_link_libraries(${_PACKAGE} Engine)
      endif()
	endif()
  endif()
endmacro()

macro(ut99_link_core_library _LIBRARY)
	add_library(${_LIBRARY} SHARED IMPORTED)
	set_target_properties(${_LIBRARY} PROPERTIES
		IMPORTED_LOCATION_DEBUG   ${CMAKE_CURRENT_SOURCE_DIR}/../${SYSTEM_DIR}/${_LIBRARY}${LIBRARY_SUFFIX}
		IMPORTED_LOCATION_RELEASE ${CMAKE_CURRENT_SOURCE_DIR}/../${SYSTEM_DIR}/${_LIBRARY}${LIBRARY_SUFFIX}
		IMPORTED_IMPLIB_DEBUG     ${CMAKE_CURRENT_SOURCE_DIR}/../${_LIBRARY}/${STATIC_LIB_DIR}/${_LIBRARY}.lib
		IMPORTED_IMPLIB_RELEASE   ${CMAKE_CURRENT_SOURCE_DIR}/../${_LIBRARY}/${STATIC_LIB_DIR}/${_LIBRARY}.lib
	)
endmacro()

ut99_link_core_library(Core)
ut99_link_core_library(Engine)

# set header include directories
include_directories(
  inc/
)

file(GLOB SOURCES
  src/*.cpp
)

add_library(${PROJECT_NAME} SHARED
  ${SOURCES}
)
ut99_set_package_properties(${PROJECT_NAME})

install(TARGETS ${PROJECT_NAME} DESTINATION ./)


# end of CMakeLists.txt ...
