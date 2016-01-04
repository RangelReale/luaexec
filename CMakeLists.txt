# Copyright (C) 2007-2011 LuaDist.
# Created by David Manura
# Redistribution and use of this file is allowed according to the terms of the MIT license.
# For details see the COPYRIGHT file distributed with LuaDist.
# Please note that the package source code is licensed under its own license.

project ( luaexec C CXX )
cmake_minimum_required ( VERSION 2.6 )


IF(CMAKE_BUILD_TOOL MATCHES "(msdev|devenv|nmake)")
  IF(CMAKE_COMPILER_2005)
    ADD_DEFINITIONS(-D_CRT_SECURE_NO_DEPRECATE -D_CRT_NONSTDC_NO_DEPRECATE -D_CRT_SECURE_NO_WARNINGS)
  ENDIF(CMAKE_COMPILER_2005)
ENDIF()


find_package ( Lua )
include_directories(${LUA_INCLUDE_DIR})

option ( LUA_CXX "Compile as CXX instead of C." OFF )

# LIBVERSION 0:1:0
set ( SOVERSION 0 )
set ( VERSION 0.84.0 )

include_directories ( include )

add_subdirectory(src)
add_subdirectory(tek)
