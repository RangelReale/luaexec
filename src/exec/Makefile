
BASEDIR ?= ../..
include $(BASEDIR)/config

###############################################################################

LIBS = $(LIBDIR)/libexec.a

$(OBJDIR)/exec_mod.lo: \
	exec_all.c exec_mod.h $(INCDIR)/tek/mod/exec.h exec_mod.c exec_api.c exec_doexec.c exec_memory.c exec_time.c
	$(CC) $(LIBCFLAGS) -o $@ -c exec_all.c

$(LIBDIR)/libexec.a: \
	$(OBJDIR)/exec_mod.lo
	$(AR) $@ $?

$(MODDIR)/exec.so: $(OBJDIR)/exec_mod.lo
	$(CC) $(MODCFLAGS) -o $@ $(OBJDIR)/exec_mod.lo -L$(LIBDIR) -ltekc -ltekdebug $(PLATFORM_LIBS)

###############################################################################

libs: $(LIBDIR) $(OBJDIR) $(LIBS)

modules: $(OBJDIR) $(MODDIR) $(MODS)

clean: FORCE
	-$(RM) $(MODS) $(TOOLS) $(LIBS)
	-$(RMDIR) $(OBJDIR)
