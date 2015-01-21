
BASEDIR ?= ..
include $(BASEDIR)/config

all: libs modules

clean libs modules:
	cd teklib && $(MAKE) $@
	cd hal && $(MAKE) $@
	cd exec && $(MAKE) $@
