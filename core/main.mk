# Only use ANDROID_BUILD_SHELL to wrap around bash.
# DO NOT use other shells such as zsh.
ifdef ANDROID_BUILD_SHELL
SHELL := $(ANDROID_BUILD_SHELL)
else
# Use bash, not whatever shell somebody has installed as /bin/sh
# This is repeated in config.mk, since envsetup.sh runs that file
# directly.
SHELL := /bin/bash
endif

# this turns off the suffix rules built into make
.SUFFIXES:

# this turns off the RCS / SCCS implicit rules of GNU Make
% : RCS/%,v
% : RCS/%
% : %,v
% : s.%
% : SCCS/s.%

# If a rule fails, delete $@.
.DELETE_ON_ERROR:

# Figure out where we are.
#TOP := $(dir $(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST)))
#TOP := $(patsubst %/,%,$(TOP))

# TOPDIR is the normal variable you should use, because
# if we are executing relative to the current directory
# it can be "", whereas TOP must be "." which causes
# pattern matching probles when make strips off the
# trailing "./" from paths in various places.
#ifeq ($(TOP),.)
#TOPDIR :=
#else
#TOPDIR := $(TOP)/
#endif

# Check for broken versions of make.
# (Allow any version under Cygwin since we don't actually build the platform there.)
ifeq (,$(findstring CYGWIN,$(shell uname -sm)))
ifeq (0,$(shell expr $$(echo $(MAKE_VERSION) | sed "s/[^0-9\.].*//") = 3.81))
ifeq (0,$(shell expr $$(echo $(MAKE_VERSION) | sed "s/[^0-9\.].*//") = 3.82))
$(warning ********************************************************************************)
$(warning *  You are using version $(MAKE_VERSION) of make.)
$(warning *  Android can only be built by versions 3.81 and 3.82.)
$(warning *  see https://source.android.com/source/download.html)
$(warning ********************************************************************************)
$(error stopping)
endif
endif
endif

# Absolute path of the present working direcotry.
# This overrides the shell variable $PWD, which does not necessarily points to
# the top of the source tree, for example when "make -C" is used in m/mm/mmm.
PWD := $(shell pwd)

TOP := .
TOPDIR :=

BUILD_SYSTEM := $(TOPDIR)build/core

# This is the default target.  It must be the first declared target.
.PHONY: droid
DEFAULT_GOAL := droid
$(DEFAULT_GOAL):

# Used to force goals to build.  Only use for conditionally defined goals.
.PHONY: FORCE
FORCE:

# Targets that provide quick help on the build system.
include $(BUILD_SYSTEM)/help.mk

# Set up various standard variables based on configuration
# and host information.
include $(BUILD_SYSTEM)/config.mk

# These are the modifier targets that don't do anything themselves, but
# change the behavior of the build.
# (must be defined before including definitions.make)
INTERNAL_MODIFIER_TARGETS := showcommands all incrementaljavac

.PHONY: incrementaljavac
incrementaljavac: ;

# WARNING:
# ENABLE_INCREMENTALJAVAC should NOT be enabled by default, because change of
# a Java source file won't trigger rebuild of its dependent Java files.
# You can only enable it by adding "incrementaljavac" to your make command line.
# You are responsible for the correctness of the incremental build.
# This may decrease incremental build time dramatically for large Java libraries,
# such as core.jar, framework.jar, etc.
ENABLE_INCREMENTALJAVAC :=
ifneq (,$(filter incrementaljavac, $(MAKECMDGOALS)))
ENABLE_INCREMENTALJAVAC := true
MAKECMDGOALS := $(filter-out incrementaljavac, $(MAKECMDGOALS))
endif

# EMMA_INSTRUMENT_STATIC merges the static emma library to each emma-enabled module.
ifeq (true,$(EMMA_INSTRUMENT_STATIC))
EMMA_INSTRUMENT := true
endif

# Bring in standard build system definitions.
include $(BUILD_SYSTEM)/definitions.mk

ifneq ($(filter user userdebug eng,$(MAKECMDGOALS)),)
$(info ***************************************************************)
$(info ***************************************************************)
$(info Do not pass '$(filter user userdebug eng,$(MAKECMDGOALS))' on \
       the make command line.)
$(info Set TARGET_BUILD_VARIANT in buildspec.mk, or use lunch or)
$(info choosecombo.)
$(info ***************************************************************)
$(info ***************************************************************)
$(error stopping)
endif

ifneq ($(filter-out $(INTERNAL_VALID_VARIANTS),$(TARGET_BUILD_VARIANT)),)
$(info ***************************************************************)
$(info ***************************************************************)
$(info Invalid variant: $(TARGET_BUILD_VARIANT)
$(info Valid values are: $(INTERNAL_VALID_VARIANTS)
$(info ***************************************************************)
$(info ***************************************************************)
$(error stopping)
endif

# -----------------------------------------------------------------
# Variable to check java support level inside PDK build.
# Not necessary if the components is not in PDK.
# not defined : not supported
# "sdk" : sdk API only
# "platform" : platform API supproted
TARGET_BUILD_JAVA_SUPPORT_LEVEL := platform

# -----------------------------------------------------------------
# The pdk (Platform Development Kit) build
include build/core/pdk_config.mk

# -----------------------------------------------------------------
###
### In this section we set up the things that are different
### between the build variants
###

is_sdk_build :=

ifneq ($(filter sdk win_sdk sdk_addon,$(MAKECMDGOALS)),)
is_sdk_build := true
endif

## user/userdebug ##

user_variant := $(filter user userdebug,$(TARGET_BUILD_VARIANT))
enable_target_debugging := true
tags_to_install :=
ifneq (,$(user_variant))
  ifeq ($(user_variant),userdebug)
    # Pick up some extra useful tools
    tags_to_install += debug
  else
    # Disable debugging in plain user builds.
    enable_target_debugging :=
  endif
endif # !user_variant

## eng ##

ifeq ($(TARGET_BUILD_VARIANT),eng)
tags_to_install := debug eng
endif

## sdk ##

ifdef is_sdk_build

# Detect if we want to build a repository for the SDK
sdk_repo_goal := $(strip $(filter sdk_repo,$(MAKECMDGOALS)))
MAKECMDGOALS := $(strip $(filter-out sdk_repo,$(MAKECMDGOALS)))

ifneq ($(words $(filter-out $(INTERNAL_MODIFIER_TARGETS) checkbuild,$(MAKECMDGOALS))),1)
$(error The 'sdk' target may not be specified with any other targets)
endif

# TODO: this should be eng I think.  Since the sdk is built from the eng
# variant.
tags_to_install := debug eng
else # !sdk
endif

BUILD_WITHOUT_PV := true

# ------------------------------------------------------------
# Define a function that, given a list of module tags, returns
# non-empty if that module should be installed in /system.

# For most goals, anything not tagged with the "tests" tag should
# be installed in /system.
define should-install-to-system
$(if $(filter tests,$(1)),,true)
endef

ifdef is_sdk_build
# For the sdk goal, anything with the "samples" tag should be
# installed in /data even if that module also has "eng"/"debug"/"user".
define should-install-to-system
$(if $(filter samples tests,$(1)),,true)
endef
endif


# If they only used the modifier goals (showcommands, etc), we'll actually
# build the default target.
ifeq ($(filter-out $(INTERNAL_MODIFIER_TARGETS),$(MAKECMDGOALS)),)
.PHONY: $(INTERNAL_MODIFIER_TARGETS)
$(INTERNAL_MODIFIER_TARGETS): $(DEFAULT_GOAL)
endif

# Bring in all modules that need to be built.
ifneq ($(dont_bother),true)

ifeq ($(HOST_OS)-$(HOST_ARCH),darwin-ppc)
SDK_ONLY := true
$(info Building the SDK under darwin-ppc is actually obsolete and unsupported.)
$(error stop)
endif

ifeq ($(HOST_OS),windows)
SDK_ONLY := true
endif

ifeq ($(SDK_ONLY),true)
include $(TOPDIR)sdk/build/windows_sdk_whitelist.mk
include $(TOPDIR)development/build/windows_sdk_whitelist.mk

# Exclude tools/acp when cross-compiling windows under linux
ifeq ($(findstring Linux,$(UNAME)),)
subdirs += build/tools/acp
endif

else	# !SDK_ONLY
#
# Typical build; include any Android.mk files we can find.
#
subdirs := $(TOP)

FULL_BUILD := true

endif	# !SDK_ONLY

# Before we go and include all of the module makefiles, stash away
# the PRODUCT_* values so that later we can verify they are not modified.
stash_product_vars:=true
ifeq ($(stash_product_vars),true)
  $(call stash-product-vars, __STASHED)
endif

ifneq ($(ONE_SHOT_MAKEFILE),)
# We've probably been invoked by the "mm" shell function
# with a subdirectory's makefile.
include $(ONE_SHOT_MAKEFILE)
# Change CUSTOM_MODULES to include only modules that were
# defined by this makefile; this will install all of those
# modules as a side-effect.  Do this after including ONE_SHOT_MAKEFILE
# so that the modules will be installed in the same place they
# would have been with a normal make.
CUSTOM_MODULES := $(sort $(call get-tagged-modules,$(ALL_MODULE_TAGS)))
FULL_BUILD :=
# Stub out the notice targets, which probably aren't defined
# when using ONE_SHOT_MAKEFILE.
NOTICE-HOST-%: ;
NOTICE-TARGET-%: ;

else # ONE_SHOT_MAKEFILE

#
# Include all of the makefiles in the system
#

# Can't use first-makefiles-under here because
# --mindepth=2 makes the prunes not work.
subdir_makefiles := \
	$(shell build/tools/findleaves.py --prune=$(OUT_DIR) --prune=.repo --prune=.git $(subdirs) Android.mk)

include $(subdir_makefiles)

endif # ONE_SHOT_MAKEFILE

ifeq ($(stash_product_vars),true)
  $(call assert-product-vars, __STASHED)
endif

# -------------------------------------------------------------------
# All module makefiles have been included at this point.
# -------------------------------------------------------------------

# -------------------------------------------------------------------
# Include any makefiles that must happen after the module makefiles
# have been included.
# TODO: have these files register themselves via a global var rather
# than hard-coding the list here.
ifdef FULL_BUILD
  # Only include this during a full build, otherwise we can't be
  # guaranteed that any policies were included.
  -include frameworks/policies/base/PolicyConfig.mk
endif

# -------------------------------------------------------------------
# Fix up CUSTOM_MODULES to refer to installed files rather than
# just bare module names.  Leave unknown modules alone in case
# they're actually full paths to a particular file.
known_custom_modules := $(filter $(ALL_MODULES),$(CUSTOM_MODULES))
unknown_custom_modules := $(filter-out $(ALL_MODULES),$(CUSTOM_MODULES))
CUSTOM_MODULES := \
	$(call module-installed-files,$(known_custom_modules)) \
	$(unknown_custom_modules)

# -------------------------------------------------------------------
# Define dependencies for modules that require other modules.
# This can only happen now, after we've read in all module makefiles.
#
# TODO: deal with the fact that a bare module name isn't
# unambiguous enough.  Maybe declare short targets like
# APPS:Quake or HOST:SHARED_LIBRARIES:libutils.
# BUG: the system image won't know to depend on modules that are
# brought in as requirements of other modules.
define add-required-deps
$(1): | $(2)
endef
$(foreach m,$(ALL_MODULES), \
  $(eval r := $(ALL_MODULES.$(m).REQUIRED)) \
  $(if $(r), \
    $(eval r := $(call module-installed-files,$(r))) \
    $(eval t_m := $(filter $(TARGET_OUT_ROOT)/%, $(ALL_MODULES.$(m).INSTALLED))) \
    $(eval h_m := $(filter $(HOST_OUT_ROOT)/%, $(ALL_MODULES.$(m).INSTALLED))) \
    $(eval t_r := $(filter $(TARGET_OUT_ROOT)/%, $(r))) \
    $(eval h_r := $(filter $(HOST_OUT_ROOT)/%, $(r))) \
    $(if $(t_m), $(eval $(call add-required-deps, $(t_m),$(t_r)))) \
    $(if $(h_m), $(eval $(call add-required-deps, $(h_m),$(h_r)))) \
   ) \
 )

t_m :=
h_m :=
t_r :=
h_r :=

# Resolve the dependencies on shared libraries.
$(foreach m,$(TARGET_DEPENDENCIES_ON_SHARED_LIBRARIES), \
  $(eval p := $(subst :,$(space),$(m))) \
  $(eval r := $(filter $(TARGET_OUT_ROOT)/%,$(call module-installed-files,\
    $(subst $(comma),$(space),$(lastword $(p)))))) \
  $(eval $(call add-required-deps,$(word 2,$(p)),$(r))))
$(foreach m,$(HOST_DEPENDENCIES_ON_SHARED_LIBRARIES), \
  $(eval p := $(subst :,$(space),$(m))) \
  $(eval r := $(filter $(HOST_OUT_ROOT)/%,$(call module-installed-files,\
    $(subst $(comma),$(space),$(lastword $(p)))))) \
  $(eval $(call add-required-deps,$(word 2,$(p)),$(r))))

m :=
r :=
p :=
add-required-deps :=

# -------------------------------------------------------------------
# Figure out our module sets.
#
# Of the modules defined by the component makefiles,
# determine what we actually want to build.

ifdef FULL_BUILD
  # The base list of modules to build for this product is specified
  # by the appropriate product definition file, which was included
  # by product_config.make.
  product_MODULES := $(PRODUCTS.$(INTERNAL_PRODUCT).PRODUCT_PACKAGES)
  # Filter out the overridden packages before doing expansion
  product_MODULES := $(filter-out $(foreach p, $(product_MODULES), \
      $(PACKAGES.$(p).OVERRIDES)), $(product_MODULES))
  $(call expand-required-modules,product_MODULES,$(product_MODULES))
  product_FILES := $(call module-installed-files, $(product_MODULES))
  ifeq (0,1)
    $(info product_FILES for $(TARGET_DEVICE) ($(INTERNAL_PRODUCT)):)
    $(foreach p,$(product_FILES),$(info :   $(p)))
    $(error done)
  endif
else
  # We're not doing a full build, and are probably only including
  # a subset of the module makefiles.  Don't try to build any modules
  # requested by the product, because we probably won't have rules
  # to build them.
  product_FILES :=
endif

eng_MODULES := $(sort \
        $(call get-tagged-modules,eng) \
        $(call module-installed-files, $(PRODUCTS.$(INTERNAL_PRODUCT).PRODUCT_PACKAGES_ENG)) \
    )
debug_MODULES := $(sort \
        $(call get-tagged-modules,debug) \
        $(call module-installed-files, $(PRODUCTS.$(INTERNAL_PRODUCT).PRODUCT_PACKAGES_DEBUG)) \
    )
tests_MODULES := $(sort \
        $(call get-tagged-modules,tests) \
        $(call module-installed-files, $(PRODUCTS.$(INTERNAL_PRODUCT).PRODUCT_PACKAGES_TESTS)) \
    )

# TODO: Remove the 3 places in the tree that use ALL_DEFAULT_INSTALLED_MODULES
# and get rid of it from this list.
# TODO: The shell is chosen by magic.  Do we still need this?
modules_to_install := $(sort \
    $(ALL_DEFAULT_INSTALLED_MODULES) \
    $(product_FILES) \
    $(foreach tag,$(tags_to_install),$($(tag)_MODULES)) \
    $(call get-tagged-modules, shell_$(TARGET_SHELL)) \
    $(CUSTOM_MODULES) \
  )

# Some packages may override others using LOCAL_OVERRIDES_PACKAGES.
# Filter out (do not install) any overridden packages.
overridden_packages := $(call get-package-overrides,$(modules_to_install))
ifdef overridden_packages
#  old_modules_to_install := $(modules_to_install)
  modules_to_install := \
      $(filter-out $(foreach p,$(overridden_packages),$(p) %/$(p).apk), \
          $(modules_to_install))
endif
#$(error filtered out
#           $(filter-out $(modules_to_install),$(old_modules_to_install)))

# Don't include any GNU targets in the SDK.  It's ok (and necessary)
# to build the host tools, but nothing that's going to be installed
# on the target (including static libraries).
ifdef is_sdk_build
  target_gnu_MODULES := \
              $(filter \
                      $(TARGET_OUT_INTERMEDIATES)/% \
                      $(TARGET_OUT)/% \
                      $(TARGET_OUT_DATA)/%, \
                              $(sort $(call get-tagged-modules,gnu)))
  $(info Removing from sdk:)$(foreach d,$(target_gnu_MODULES),$(info : $(d)))
  modules_to_install := \
              $(filter-out $(target_gnu_MODULES),$(modules_to_install))

  # Ensure every module listed in PRODUCT_PACKAGES* gets something installed
  # TODO: Should we do this for all builds and not just the sdk?
  $(foreach m, $(PRODUCTS.$(INTERNAL_PRODUCT).PRODUCT_PACKAGES), \
    $(if $(strip $(ALL_MODULES.$(m).INSTALLED)),,\
      $(error $(ALL_MODULES.$(m).MAKEFILE): Module '$(m)' in PRODUCT_PACKAGES has nothing to install!)))
  $(foreach m, $(PRODUCTS.$(INTERNAL_PRODUCT).PRODUCT_PACKAGES_DEBUG), \
    $(if $(strip $(ALL_MODULES.$(m).INSTALLED)),,\
      $(warning $(ALL_MODULES.$(m).MAKEFILE): Module '$(m)' in PRODUCT_PACKAGES_DEBUG has nothing to install!)))
  $(foreach m, $(PRODUCTS.$(INTERNAL_PRODUCT).PRODUCT_PACKAGES_ENG), \
    $(if $(strip $(ALL_MODULES.$(m).INSTALLED)),,\
      $(warning $(ALL_MODULES.$(m).MAKEFILE): Module '$(m)' in PRODUCT_PACKAGES_ENG has nothing to install!)))
  $(foreach m, $(PRODUCTS.$(INTERNAL_PRODUCT).PRODUCT_PACKAGES_TESTS), \
    $(if $(strip $(ALL_MODULES.$(m).INSTALLED)),,\
      $(warning $(ALL_MODULES.$(m).MAKEFILE): Module '$(m)' in PRODUCT_PACKAGES_TESTS has nothing to install!)))
endif

# build/core/Makefile contains extra stuff that we don't want to pollute this
# top-level makefile with.  It expects that ALL_DEFAULT_INSTALLED_MODULES
# contains everything that's built during the current make, but it also further
# extends ALL_DEFAULT_INSTALLED_MODULES.
ALL_DEFAULT_INSTALLED_MODULES := $(modules_to_install)
include $(BUILD_SYSTEM)/Makefile
modules_to_install := $(sort $(ALL_DEFAULT_INSTALLED_MODULES))
ALL_DEFAULT_INSTALLED_MODULES :=

endif # dont_bother


# These are additional goals that we build, in order to make sure that there
# is as little code as possible in the tree that doesn't build.
modules_to_check := $(foreach m,$(ALL_MODULES),$(ALL_MODULES.$(m).CHECKED))

# If you would like to build all goals, and not skip any intermediate
# steps, you can pass the "all" modifier goal on the commandline.
ifneq ($(filter all,$(MAKECMDGOALS)),)
modules_to_check += $(foreach m,$(ALL_MODULES),$(ALL_MODULES.$(m).BUILT))
endif

# for easier debugging
modules_to_check := $(sort $(modules_to_check))
#$(error modules_to_check $(modules_to_check))

# -------------------------------------------------------------------
# This is used to to get the ordering right, you can also use these,
# but they're considered undocumented, so don't complain if their
# behavior changes.
.PHONY: prebuilt
prebuilt: $(ALL_PREBUILT)

# An internal target that depends on all copied headers
# (see copy_headers.make).  Other targets that need the
# headers to be copied first can depend on this target.
.PHONY: all_copied_headers
all_copied_headers: ;

$(ALL_C_CPP_ETC_OBJECTS): | all_copied_headers

# All the droid stuff, in directories
.PHONY: files
files: prebuilt \
        $(modules_to_install)

# -------------------------------------------------------------------

.PHONY: checkbuild
checkbuild: $(modules_to_check)
ifeq (true,$(ANDROID_BUILD_EVERYTHING_BY_DEFAULT)$(filter $(MAKECMDGOALS),checkbuild))
droid: checkbuild
else
# ANDROID_BUILD_EVERYTHING_BY_DEFAULT not set, or checkbuild is one of the cmd goals.
checkbuild: droid
endif

.PHONY: systemtarball
systemtarball: $(INSTALLED_SYSTEMTARBALL_TARGET)

# Build files and then package it into the rom formats
.PHONY: droidcore
droidcore: files \
	$(INSTALLED_FILES_FILE)

# dist_files only for putting your library into the dist directory with a full build.
.PHONY: dist_files

ifneq ($(TARGET_BUILD_APPS),)
  # If this build is just for apps, only build apps and not the full system by default.

  unbundled_build_modules :=
  ifneq ($(filter all,$(TARGET_BUILD_APPS)),)
    # If they used the magic goal "all" then build all apps in the source tree.
    unbundled_build_modules := $(foreach m,$(sort $(ALL_MODULES)),$(if $(filter APPS,$(ALL_MODULES.$(m).CLASS)),$(m)))
  else
    unbundled_build_modules := $(TARGET_BUILD_APPS)
  endif

  # Dist the installed files if they exist.
  apps_only_installed_files := $(foreach m,$(unbundled_build_modules),$(ALL_MODULES.$(m).INSTALLED))
  $(call dist-for-goals,apps_only, $(apps_only_installed_files))
  # For uninstallable modules such as static Java library, we have to dist the built file,
  # as <module_name>.<suffix>
  apps_only_dist_built_files := $(foreach m,$(unbundled_build_modules),$(if $(ALL_MODULES.$(m).INSTALLED),,\
      $(ALL_MODULES.$(m).BUILT):$(m)$(suffix $(ALL_MODULES.$(m).BUILT))))
  $(call dist-for-goals,apps_only, $(apps_only_dist_built_files))

  ifeq ($(EMMA_INSTRUMENT),true)
    $(EMMA_META_ZIP) : $(apps_only_installed_files)

    $(call dist-for-goals,apps_only, $(EMMA_META_ZIP))
  endif

.PHONY: apps_only
apps_only: $(unbundled_build_modules)

droid: apps_only

else # TARGET_BUILD_APPS
  $(call dist-for-goals, droidcore, \
    $(INTERNAL_UPDATE_PACKAGE_TARGET) \
    $(SYMBOLS_ZIP) \
    $(INSTALLED_FILES_FILE) \
    $(INSTALLED_BUILD_PROP_TARGET) \
    $(BUILT_TARGET_FILES_PACKAGE) \
   )

  # Put a copy of the radio/bootloader files in the dist dir.
  $(foreach f,$(INSTALLED_RADIOIMAGE_TARGET), \
    $(call dist-for-goals, droidcore, $(f)))

  ifneq ($(TARGET_BUILD_PDK),true)
    $(call dist-for-goals, droidcore, \
      $(APPS_ZIP) \
      $(INTERNAL_EMULATOR_PACKAGE_TARGET) \
      $(PACKAGE_STATS_FILE) \
    )
  endif

  ifeq ($(EMMA_INSTRUMENT),true)
    $(EMMA_META_ZIP) : $(INSTALLED_SYSTEMIMAGE)

    $(call dist-for-goals, dist_files, $(EMMA_META_ZIP))
  endif

# Building a full system-- the default is to build droidcore
droid: droidcore dist_files

endif # TARGET_BUILD_APPS

.PHONY: docs
docs: $(ALL_DOCS)

.PHONY: sdk
ALL_SDK_TARGETS := $(INTERNAL_SDK_TARGET)
sdk: $(ALL_SDK_TARGETS)
$(call dist-for-goals,sdk win_sdk, \
    $(ALL_SDK_TARGETS) \
    $(SYMBOLS_ZIP) \
    $(INSTALLED_BUILD_PROP_TARGET) \
)

# umbrella targets to assit engineers in verifying builds
.PHONY: java native target host java-host java-target native-host native-target \
        java-host-tests java-target-tests native-host-tests native-target-tests \
        java-tests native-tests host-tests target-tests
# some synonyms
.PHONY: host-java target-java host-native target-native \
        target-java-tests target-native-tests
host-java : java-host
target-java : java-target
host-native : native-host
target-native : native-target
target-java-tests : java-target-tests
target-native-tests : native-target-tests


.PHONY: lintall

.PHONY: samplecode
sample_MODULES := $(sort $(call get-tagged-modules,samples))
sample_APKS_DEST_PATH := $(TARGET_COMMON_OUT_ROOT)/samples
sample_APKS_COLLECTION := \
        $(foreach module,$(sample_MODULES),$(sample_APKS_DEST_PATH)/$(notdir $(module)))
$(foreach module,$(sample_MODULES),$(eval $(call \
        copy-one-file,$(module),$(sample_APKS_DEST_PATH)/$(notdir $(module)))))
sample_ADDITIONAL_INSTALLED := \
        $(filter-out $(modules_to_install) $(modules_to_check) $(ALL_PREBUILT),$(sample_MODULES))
samplecode: $(sample_APKS_COLLECTION)
	@echo "Collect sample code apks: $^"
	# remove apks that are not intended to be installed.
	rm -f $(sample_ADDITIONAL_INSTALLED)

.PHONY: findbugs
findbugs: $(INTERNAL_FINDBUGS_HTML_TARGET) $(INTERNAL_FINDBUGS_XML_TARGET)

.PHONY: clobber
clobber: clean

# The rules for dataclean and installclean are defined in cleanbuild.mk.

#xxx scrape this from ALL_MODULE_NAME_TAGS
.PHONY: modules
modules:
	@echo "Available sub-modules:"
	@echo "$(call module-names-for-tag-list,$(ALL_MODULE_TAGS))" | \
	      tr -s ' ' '\n' | sort -u | $(COLUMN)

.PHONY: showcommands
showcommands:
	@echo >/dev/null

.PHONY: nothing
nothing:
	@echo Successfully read the makefiles.
