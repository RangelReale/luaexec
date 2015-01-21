
BASEDIR ?= ..
include $(BASEDIR)/config

###############################################################################

LUACLASSES = \
	class/cgi.lua class/fifo.lua class/httpd.lua class/httprequest.lua \
	class/markup.lua class/server.lua class/wtf.lua

install:
	$(INSTALL_D) $(LUA_SHARE)/tek/class
	$(INSTALL_F) class.lua $(LUA_SHARE)/tek
	$(INSTALL_F) $(LUACLASSES) $(LUA_SHARE)/tek/class
