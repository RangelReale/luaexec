
BASEDIR ?= ../..
include $(BASEDIR)/config

EXTRADEFS += $(LUA_DEFS)

###############################################################################

MODS = exec$(DLLEXT)

# for the webserver example:
EXTRA_MODULES = luahtml$(DLLEXT)


EXECLIBS = $(LIBDIR)/libhal.a $(LIBDIR)/libexec.a $(LIBDIR)/libtekc.a $(LIBDIR)/libtekdebug.a

exec$(DLLEXT): $(OBJDIR)/exec_lua.lo $(EXECLIBS)
	$(CC) $(MODCFLAGS) -o $@ $(OBJDIR)/exec_lua.lo -L$(LIBDIR) -lhal -lexec -ltekc -ltekdebug $(PLATFORM_LIBS) $(LUA_LIBS)
$(OBJDIR)/exec_lua.lo: exec_lua.c
	$(CC) $(LIBCFLAGS) -o $@ -c exec_lua.c

luahtml$(DLLEXT): $(OBJDIR)/luahtml.lo $(OBJDIR)/luahtml_parser.lo
	$(CC) $(MODCFLAGS) -o $@ $(OBJDIR)/luahtml.lo $(OBJDIR)/luahtml_parser.lo $(LUA_LIBS)
$(OBJDIR)/luahtml.lo: luahtml.c
	$(CC) $(LIBCFLAGS) -o $@ -c luahtml.c
$(OBJDIR)/luahtml_parser.lo: luahtml_parser.c
	$(CC) $(LIBCFLAGS) -o $@ -c luahtml_parser.c

###############################################################################

modules: $(OBJDIR) $(MODS) $(EXTRA_MODULES)

install:
	$(INSTALL_D) $(LUA_LIB)/tek/lib
	$(INSTALL_S) $(MODS) $(LUA_LIB)/tek/lib
# 	$(INSTALL_D) $(LUA_SHARE)/tek/lib
# 	$(INSTALL_F) debug.lua args.lua $(LUA_SHARE)/tek/lib

clean: FORCE
	-$(RM) $(MODS) $(LIBS)
	-$(RMDIR) $(OBJDIR)
