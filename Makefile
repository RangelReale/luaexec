
include config

.PHONY: all libs modules install clean help distclean docs release

all: libs modules
	@echo
	@echo "all built - you can invoke 'make run' now,"
	@echo "to start a webserver on localhost:8080 that"
	@echo "serves this program's own documentation."
	@echo "Required for this are lfs and luasocket."

libs:
	cd src && $(MAKE) $@

modules: libs
	cd src && $(MAKE) $@
	cd tek/lib && $(MAKE) $@

install:
	cd tek && $(MAKE) $@
	cd tek/lib && $(MAKE) $@

clean:
	cd src && $(MAKE) $@
	cd tek/lib && $(MAKE) $@

help: default-help
	@echo "Extra build targets for this Makefile:"
	@echo "-------------------------------------------------------------------------------"
	@echo "distclean ............... remove all temporary files and directories"
	@echo "docs .................... (re-)generate documentation"
	@echo "kdiff ................... diffview of recent changes (using kdiff3)"
	@echo "run ..................... run test(s)"
	@echo "==============================================================================="

distclean: clean
	-$(RMDIR) lib bin/mod
	-find src tek -type d -name build | xargs $(RMDIR)
	-find -name "*$(DLLEXT)" -type f | xargs $(RM)

docs:
	bin/gendoc.lua README -r manual.html --header VERSION -i 32 -n "LuaExec" > doc/index.html
	bin/gendoc.lua COPYRIGHT -i 32 -n "LuaExec Copyright" > doc/copyright.html
	bin/gendoc.lua CHANGES -i 32 -r manual.html -n "LuaExec Changelog" > doc/changes.html
	bin/gendoc.lua tek/ --header VERSION --adddate -n "Reference Manual" > doc/manual.html

kdiff:
	-(a=$$(mktemp -du) && hg clone $$PWD $$a && kdiff3 $$a $$PWD; rm -rf $$a)
