if ( WIN32 OR CYGWIN )
  set ( SRC_MAIN winnt/main.c )
  set ( SRC_HOST winnt/host.c )
else ( )
  set ( SRC_MAIN posix/main.c )
  set ( SRC_HOST posix/host.c )
endif ( )

add_library ( tekdebug debug.c )
if (LUA_CXX)
  SET_SOURCE_FILES_PROPERTIES( debug.c PROPERTIES LANGUAGE CXX )
endif()

add_library ( tekcmain init.c teklib.c ${SRC_HOST} ${SRC_MAIN} )
if (LUA_CXX)
  SET_SOURCE_FILES_PROPERTIES( init.c teklib.c ${SRC_HOST} ${SRC_MAIN} PROPERTIES LANGUAGE CXX )
endif()

add_library ( tekc init.c teklib.c ${SRC_HOST} )
if (LUA_CXX)
  SET_SOURCE_FILES_PROPERTIES( init.c teklib.c ${SRC_HOST} PROPERTIES LANGUAGE CXX )
endif()

add_library ( tek teklib.c )
if (LUA_CXX)
  SET_SOURCE_FILES_PROPERTIES( teklib.c PROPERTIES LANGUAGE CXX )
endif()

add_library ( tekstring string.c )
if (LUA_CXX)
  SET_SOURCE_FILES_PROPERTIES( string.c PROPERTIES LANGUAGE CXX )
endif()

