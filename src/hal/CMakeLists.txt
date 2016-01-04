if ( WIN32 OR CYGWIN )
  set ( SRCS winnt/hal.c )
else ( )
  set ( SRCS posix/hal.c )
endif ( )

include_directories(.)

add_library ( hal hal_mod.c ${SRCS} )
if (LUA_CXX)
  SET_SOURCE_FILES_PROPERTIES( hal_mod.c ${SRCS} PROPERTIES LANGUAGE CXX )
endif()
