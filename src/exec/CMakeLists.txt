add_library ( execlib exec_all.c )
if (LUA_CXX)
   SET_SOURCE_FILES_PROPERTIES( exec_all.c PROPERTIES LANGUAGE CXX )
endif()
