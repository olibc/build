include build/core/olibc.mk

# Let `config`, `distclean` and `clean` get fast response!
FASTMAKE := $(filter config distclean clean, $(MAKECMDGOALS))

ifeq ($(FASTMAKE),)
  ifneq (,$(wildcard $(CONFIG)))
    include build/core/main.mk
  else
    all: config
  endif
endif

KCONFIG_DIR=$(PWD)/external/kconfig
MCONF=mconf

clean:
	@echo Cleaning...
	$(shell test -d $(OUT_DIR) && rm -rf $(OUT_DIR))

distclean: clean
	rm -f $(CONFIG)

# FIXME: clean up the following to be more consistent
MCONF_OBJ_PATH = out/host/obj/EXECUTABLES/mconf_intermediates
out/host/bin/$(MCONF):
	mkdir -p $(MCONF_OBJ_PATH) $(MCONF_OBJ_PATH)/lxdialog && \
	make --no-print-directory -C $(KCONFIG_DIR) -f Makefile.olibc mconf \
	  obj=$(shell pwd)/$(MCONF_OBJ_PATH) \
	  CC="gcc" HOSTCC="gcc" LKC_GENPARSER=1 && \
	mkdir -p out/host/bin && \
	cp -f $(MCONF_OBJ_PATH)/$(MCONF) out/host/bin/$(MCONF)

config: out/host/bin/$(MCONF)
	out/host/bin/$(MCONF) bionic/Config.in
