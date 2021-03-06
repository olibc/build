# Put some miscellaneous rules here

# HACK: clear LOCAL_PATH from including last build target before calling
# intermedites-dir-for
LOCAL_PATH := $(BUILD_SYSTEM)

# Pick a reasonable string to use to identify files.
ifneq "" "$(filter eng.%,$(BUILD_NUMBER))"
  # BUILD_NUMBER has a timestamp in it, which means that
  # it will change every time.  Pick a stable value.
  FILE_NAME_TAG := eng.$(USER)
else
  FILE_NAME_TAG := $(BUILD_NUMBER)
endif

# -----------------------------------------------------------------
# Define rules to copy PRODUCT_COPY_FILES defined by the product.
# PRODUCT_COPY_FILES contains words like <source file>:<dest file>[:<owner>].
# <dest file> is relative to $(PRODUCT_OUT), so it should look like,
# e.g., "system/etc/file.xml".
# The filter part means "only eval the copy-one-file rule if this
# src:dest pair is the first one to match the same dest"
#$(1): the src:dest pair
define check-product-copy-files
$(if $(filter %.apk, $(1)),$(error \
    Prebuilt apk found in PRODUCT_COPY_FILES: $(1), use BUILD_PREBUILT instead!))
endef
# filter out the duplicate <source file>:<dest file> pairs.
unique_product_copy_files_pairs :=
$(foreach cf,$(PRODUCT_COPY_FILES), \
    $(if $(filter $(unique_product_copy_files_pairs),$(cf)),,\
        $(eval unique_product_copy_files_pairs += $(cf))))
unique_product_copy_files_destinations :=
$(foreach cf,$(unique_product_copy_files_pairs), \
    $(eval _src := $(call word-colon,1,$(cf))) \
    $(eval _dest := $(call word-colon,2,$(cf))) \
    $(call check-product-copy-files,$(cf)) \
    $(if $(filter $(unique_product_copy_files_destinations),$(_dest)), \
        $(info PRODUCT_COPY_FILES $(cf) ignored.), \
        $(eval _fulldest := $(call append-path,$(PRODUCT_OUT),$(_dest))) \
        $(if $(filter %.xml,$(_dest)),\
            $(eval $(call copy-xml-file-checked,$(_src),$(_fulldest))),\
            $(eval $(call copy-one-file,$(_src),$(_fulldest)))) \
        $(eval ALL_DEFAULT_INSTALLED_MODULES += $(_fulldest)) \
        $(eval unique_product_copy_files_destinations += $(_dest))))
unique_product_copy_files_pairs :=
unique_product_copy_files_destinations :=

# -----------------------------------------------------------------
# docs/index.html
ifeq (,$(TARGET_BUILD_APPS))
gen := $(OUT_DOCS)/index.html
ALL_DOCS += $(gen)
$(gen): frameworks/base/docs/docs-redirect-index.html
	@mkdir -p $(dir $@)
	@cp -f $< $@
endif

# -----------------------------------------------------------------
# default.prop
INSTALLED_DEFAULT_PROP_TARGET := $(TARGET_ROOT_OUT)/default.prop
ALL_DEFAULT_INSTALLED_MODULES += $(INSTALLED_DEFAULT_PROP_TARGET)
ADDITIONAL_DEFAULT_PROPERTIES := \
    $(call collapse-pairs, $(ADDITIONAL_DEFAULT_PROPERTIES))
ADDITIONAL_DEFAULT_PROPERTIES += \
    $(call collapse-pairs, $(PRODUCT_DEFAULT_PROPERTY_OVERRIDES))
ADDITIONAL_DEFAULT_PROPERTIES := $(call uniq-pairs-by-first-component, \
    $(ADDITIONAL_DEFAULT_PROPERTIES),=)

$(INSTALLED_DEFAULT_PROP_TARGET):
	@echo Target buildinfo: $@
	@mkdir -p $(dir $@)
	$(hide) echo "#" > $@; \
	        echo "# ADDITIONAL_DEFAULT_PROPERTIES" >> $@; \
	        echo "#" >> $@;
	$(hide) $(foreach line,$(ADDITIONAL_DEFAULT_PROPERTIES), \
		echo "$(line)" >> $@;)
	build/tools/post_process_props.py $@

# -----------------------------------------------------------------
# build.prop
INSTALLED_BUILD_PROP_TARGET := $(TARGET_OUT)/build.prop
ALL_DEFAULT_INSTALLED_MODULES += $(INSTALLED_BUILD_PROP_TARGET)

# A list of arbitrary tags describing the build configuration.
# Force ":=" so we can use +=
BUILD_VERSION_TAGS := $(BUILD_VERSION_TAGS)
ifeq ($(TARGET_BUILD_TYPE),debug)
  BUILD_VERSION_TAGS += debug
endif
BUILD_VERSION_TAGS += dev-keys
BUILD_VERSION_TAGS += $(BUILD_KEYS)
BUILD_VERSION_TAGS := $(subst $(space),$(comma),$(sort $(BUILD_VERSION_TAGS)))

# A human-readable string that descibes this build in detail.
build_desc := $(TARGET_PRODUCT)-$(TARGET_BUILD_VARIANT) $(PLATFORM_VERSION) $(BUILD_ID) $(BUILD_NUMBER) $(BUILD_VERSION_TAGS)
$(INSTALLED_BUILD_PROP_TARGET): PRIVATE_BUILD_DESC := $(build_desc)

# The string used to uniquely identify this build;  used by the OTA server.
ifeq (,$(strip $(BUILD_FINGERPRINT)))
  BUILD_FINGERPRINT := $(PRODUCT_BRAND)/$(TARGET_PRODUCT)/$(TARGET_DEVICE):$(PLATFORM_VERSION)/$(BUILD_ID)/$(BUILD_NUMBER):$(TARGET_BUILD_VARIANT)/$(BUILD_VERSION_TAGS)
endif
ifneq ($(words $(BUILD_FINGERPRINT)),1)
  $(error BUILD_FINGERPRINT cannot contain spaces: "$(BUILD_FINGERPRINT)")
endif

# Display parameters shown under Settings -> About Phone
ifeq ($(TARGET_BUILD_VARIANT),user)
  # User builds should show:
  # release build number or branch.buld_number non-release builds

  # Dev. branches should have DISPLAY_BUILD_NUMBER set
  ifeq "true" "$(DISPLAY_BUILD_NUMBER)"
    BUILD_DISPLAY_ID := $(BUILD_ID).$(BUILD_NUMBER) $(BUILD_KEYS)
  else
    BUILD_DISPLAY_ID := $(BUILD_ID) $(BUILD_KEYS)
  endif
else
  # Non-user builds should show detailed build information
  BUILD_DISPLAY_ID := $(build_desc)
endif

# Whether there is default locale set in PRODUCT_PROPERTY_OVERRIDES
product_property_override_locale_language := $(strip \
    $(patsubst ro.product.locale.language=%,%,\
    $(filter ro.product.locale.language=%,$(PRODUCT_PROPERTY_OVERRIDES))))
product_property_overrides_locale_region := $(strip \
    $(patsubst ro.product.locale.region=%,%,\
    $(filter ro.product.locale.region=%,$(PRODUCT_PROPERTY_OVERRIDES))))

# Selects the first locale in the list given as the argument,
# and splits it into language and region, which each may be
# empty.
define default-locale
$(subst _, , $(firstword $(1)))
endef

# Selects the first locale in the list given as the argument
# and returns the language (or the region), if it's not set in PRODUCT_PROPERTY_OVERRIDES;
# Return empty string if it's already set in PRODUCT_PROPERTY_OVERRIDES.
define default-locale-language
$(if $(product_property_override_locale_language),,$(word 1, $(call default-locale, $(1))))
endef
define default-locale-region
$(if $(product_property_overrides_locale_region),,$(word 2, $(call default-locale, $(1))))
endef

BUILDINFO_SH := build/tools/buildinfo.sh

ifdef TARGET_SYSTEM_PROP
system_prop_file := $(TARGET_SYSTEM_PROP)
else
system_prop_file := $(wildcard $(TARGET_DEVICE_DIR)/system.prop)
endif

$(INSTALLED_BUILD_PROP_TARGET): $(BUILDINFO_SH) $(INTERNAL_BUILD_ID_MAKEFILE) $(BUILD_SYSTEM)/version_defaults.mk $(system_prop_file)
	@echo Target buildinfo: $@
	@mkdir -p $(dir $@)
	$(hide) TARGET_BUILD_TYPE="$(TARGET_BUILD_VARIANT)" \
			TARGET_DEVICE="$(TARGET_DEVICE)" \
			PRODUCT_NAME="$(TARGET_PRODUCT)" \
			PRODUCT_BRAND="$(PRODUCT_BRAND)" \
			PRODUCT_DEFAULT_LANGUAGE="$(call default-locale-language,$(PRODUCT_LOCALES))" \
			PRODUCT_DEFAULT_REGION="$(call default-locale-region,$(PRODUCT_LOCALES))" \
			PRODUCT_DEFAULT_WIFI_CHANNELS="$(PRODUCT_DEFAULT_WIFI_CHANNELS)" \
			PRODUCT_MODEL="$(PRODUCT_MODEL)" \
			PRODUCT_MANUFACTURER="$(PRODUCT_MANUFACTURER)" \
			PRIVATE_BUILD_DESC="$(PRIVATE_BUILD_DESC)" \
			BUILD_ID="$(BUILD_ID)" \
			BUILD_DISPLAY_ID="$(BUILD_DISPLAY_ID)" \
			BUILD_NUMBER="$(BUILD_NUMBER)" \
			PLATFORM_VERSION="$(PLATFORM_VERSION)" \
			PLATFORM_SDK_VERSION="$(PLATFORM_SDK_VERSION)" \
			PLATFORM_VERSION_CODENAME="$(PLATFORM_VERSION_CODENAME)" \
			BUILD_VERSION_TAGS="$(BUILD_VERSION_TAGS)" \
			TARGET_BOOTLOADER_BOARD_NAME="$(TARGET_BOOTLOADER_BOARD_NAME)" \
			BUILD_FINGERPRINT="$(BUILD_FINGERPRINT)" \
			TARGET_BOARD_PLATFORM="$(TARGET_BOARD_PLATFORM)" \
			TARGET_CPU_ABI_LIST="$(TARGET_CPU_ABI_LIST)" \
			TARGET_CPU_ABI_LIST_32_BIT="$(TARGET_CPU_ABI_LIST_32_BIT)" \
			TARGET_CPU_ABI_LIST_64_BIT="$(TARGET_CPU_ABI_LIST_64_BIT)" \
			TARGET_CPU_ABI="$(TARGET_CPU_ABI)" \
			TARGET_CPU_ABI2="$(TARGET_CPU_ABI2)" \
			TARGET_AAPT_CHARACTERISTICS="$(TARGET_AAPT_CHARACTERISTICS)" \
	        bash $(BUILDINFO_SH) > $@
	$(hide) $(foreach file,$(system_prop_file), \
		if [ -f "$(file)" ]; then \
			echo "#" >> $@; \
			echo Target buildinfo from: "$(file)"; \
			echo "# from $(file)" >> $@; \
			echo "#" >> $@; \
			cat $(file) >> $@; \
		fi;)
	$(hide) build/tools/post_process_props.py $@

build_desc :=

# -----------------------------------------------------------------
# sdk-build.prop
#
# There are certain things in build.prop that we don't want to
# ship with the sdk; remove them.

# This must be a list of entire property keys followed by
# "=" characters, without any internal spaces.
sdk_build_prop_remove := \
	ro.build.user= \
	ro.build.host= \
	ro.product.brand= \
	ro.product.manufacturer= \
	ro.product.device=
# TODO: Remove this soon-to-be obsolete property
sdk_build_prop_remove += ro.build.product=
INSTALLED_SDK_BUILD_PROP_TARGET := $(PRODUCT_OUT)/sdk/sdk-build.prop
$(INSTALLED_SDK_BUILD_PROP_TARGET): $(INSTALLED_BUILD_PROP_TARGET)
	@echo SDK buildinfo: $@
	@mkdir -p $(dir $@)
	$(hide) grep -v "$(subst $(space),\|,$(strip \
				$(sdk_build_prop_remove)))" $< > $@.tmp
	$(hide) for x in $(sdk_build_prop_remove); do \
				echo "$$x"generic >> $@.tmp; done
	$(hide) mv $@.tmp $@

# -----------------------------------------------------------------
# package stats
PACKAGE_STATS_FILE := $(PRODUCT_OUT)/package-stats.txt
PACKAGES_TO_STAT := \
    $(sort $(filter $(TARGET_OUT)/% $(TARGET_OUT_DATA)/%, \
	$(filter %.jar %.apk, $(ALL_DEFAULT_INSTALLED_MODULES))))
$(PACKAGE_STATS_FILE): $(PACKAGES_TO_STAT)
	@echo Package stats: $@
	@mkdir -p $(dir $@)
	$(hide) rm -f $@
	$(hide) build/tools/dump-package-stats $^ > $@

.PHONY: package-stats
package-stats: $(PACKAGE_STATS_FILE)

# -----------------------------------------------------------------
# Cert-to-package mapping.  Used by the post-build signing tools.
# Use a macro to add newline to each echo command
define _apkcerts_echo_with_newline
$(hide) echo $(1)

endef

name := $(TARGET_PRODUCT)
ifeq ($(TARGET_BUILD_TYPE),debug)
  name := $(name)_debug
endif
name := $(name)-apkcerts-$(FILE_NAME_TAG)
intermediates := \
	$(call intermediates-dir-for,PACKAGING,apkcerts)
APKCERTS_FILE := $(intermediates)/$(name).txt
# We don't need to really build all the modules.
# TODO: rebuild APKCERTS_FILE if any app change its cert.
$(APKCERTS_FILE):
	@echo APK certs list: $@
	@mkdir -p $(dir $@)
	@rm -f $@
	$(foreach p,$(PACKAGES),\
	  $(if $(PACKAGES.$(p).EXTERNAL_KEY),\
	    $(call _apkcerts_echo_with_newline,\
	      'name="$(p).apk" certificate="EXTERNAL" \
	      private_key=""' >> $@),\
	    $(call _apkcerts_echo_with_newline,\
	      'name="$(p).apk" certificate="$(PACKAGES.$(p).CERTIFICATE)" \
	      private_key="$(PACKAGES.$(p).PRIVATE_KEY)"' >> $@)))
	# In case value of PACKAGES is empty.
	$(hide) touch $@

.PHONY: apkcerts-list
apkcerts-list: $(APKCERTS_FILE)

ifneq (,$(TARGET_BUILD_APPS))
  $(call dist-for-goals, apps_only, $(APKCERTS_FILE):apkcerts.txt)
endif

# -----------------------------------------------------------------
# module info file
ifdef CREATE_MODULE_INFO_FILE
  MODULE_INFO_FILE := $(PRODUCT_OUT)/module-info.txt
  $(info Generating $(MODULE_INFO_FILE)...)
  $(shell rm -f $(MODULE_INFO_FILE))
  $(foreach m,$(ALL_MODULES), \
    $(shell echo "NAME=\"$(m)\"" \
	"PATH=\"$(strip $(ALL_MODULES.$(m).PATH))\"" \
	"TAGS=\"$(strip $(filter-out _%,$(ALL_MODULES.$(m).TAGS)))\"" \
	"BUILT=\"$(strip $(ALL_MODULES.$(m).BUILT))\"" \
	"INSTALLED=\"$(strip $(ALL_MODULES.$(m).INSTALLED))\"" >> $(MODULE_INFO_FILE)))
endif

.PHONY: event-log-tags

# Produce an event logs tag file for everything we know about, in order
# to properly allocate numbers.  Then produce a file that's filtered
# for what's going to be installed.

all_event_log_tags_file := $(TARGET_OUT_COMMON_INTERMEDIATES)/all-event-log-tags.txt

event_log_tags_file := $(TARGET_OUT)/etc/event-log-tags

# Include tags from all packages that we know about
all_event_log_tags_src := \
    $(sort $(foreach m, $(ALL_MODULES), $(ALL_MODULES.$(m).EVENT_LOG_TAGS)))

# PDK builds will already have a full list of tags that needs to get merged
# in with the ones from source
pdk_fusion_log_tags_file := $(patsubst $(PRODUCT_OUT)/%,$(_pdk_fusion_intermediates)/%,$(filter $(event_log_tags_file),$(ALL_PDK_FUSION_FILES)))

$(all_event_log_tags_file): PRIVATE_SRC_FILES := $(all_event_log_tags_src) $(pdk_fusion_log_tags_file)
$(all_event_log_tags_file): $(all_event_log_tags_src) $(pdk_fusion_log_tags_file)
	$(hide) mkdir -p $(dir $@)
	$(hide) build/tools/merge-event-log-tags.py -o $@ $(PRIVATE_SRC_FILES)

# Include tags from all packages included in this product, plus all
# tags that are part of the system (ie, not in a vendor/ or device/
# directory).
event_log_tags_src := \
    $(sort $(foreach m,\
      $(PRODUCTS.$(INTERNAL_PRODUCT).PRODUCT_PACKAGES) \
      $(call module-names-for-tag-list,user), \
      $(ALL_MODULES.$(m).EVENT_LOG_TAGS)) \
      $(filter-out vendor/% device/% out/%,$(all_event_log_tags_src)))

$(event_log_tags_file): PRIVATE_SRC_FILES := $(event_log_tags_src) $(pdk_fusion_log_tags_file)
$(event_log_tags_file): PRIVATE_MERGED_FILE := $(all_event_log_tags_file)
$(event_log_tags_file): $(event_log_tags_src) $(all_event_log_tags_file) $(pdk_fusion_log_tags_file)
	$(hide) mkdir -p $(dir $@)
	$(hide) build/tools/merge-event-log-tags.py -o $@ -m $(PRIVATE_MERGED_FILE) $(PRIVATE_SRC_FILES)

event-log-tags: $(event_log_tags_file)


# -----------------------------------------------------------------
# NOTICE files
#
# We are required to publish the licenses for all code under BSD, GPL and
# Apache licenses (and possibly other more exotic ones as well). We err on the
# side of caution, so the licenses for other third-party code are included here
# too.
#

.PHONY: notice_files

# Create the rule to combine the files into text and html forms
# $(1) - Plain text output file
# $(2) - HTML output file
# $(3) - File title
# $(4) - Directory to use.  Notice files are all $(4)/src.  Other
#		 directories in there will be used for scratch
# $(5) - Dependencies for the output files
#
# The algorithm here is that we go collect a hash for each of the notice
# files and write the names of the files that match that hash.  Then
# to generate the real files, we go print out all of the files and their
# hashes.
#
# These rules are fairly complex, so they depend on this makefile so if
# it changes, they'll run again.
#
# TODO: We could clean this up so that we just record the locations of the
# original notice files instead of making rules to copy them somwehere.
# Then we could traverse that without quite as much bash drama.
define combine-notice-files
$(1) $(2): PRIVATE_MESSAGE := $(3)
$(1) $(2): PRIVATE_DIR := $(4)
$(1) : $(2)
$(2) : $(5) $(BUILD_SYSTEM)/Makefile build/tools/generate-notice-files.py
	build/tools/generate-notice-files.py $(1) $(2) $$(PRIVATE_MESSAGE) $$(PRIVATE_DIR)/src
notice_files: $(1) $(2)
endef

# TODO These intermediate NOTICE.txt/NOTICE.html files should go into
# TARGET_OUT_NOTICE_FILES now that the notice files are gathered from
# the src subdirectory.

target_notice_file_txt := $(TARGET_OUT_INTERMEDIATES)/NOTICE.txt
target_notice_file_html := $(TARGET_OUT_INTERMEDIATES)/NOTICE.html
target_notice_file_html_gz := $(TARGET_OUT_INTERMEDIATES)/NOTICE.html.gz
tools_notice_file_txt := $(HOST_OUT_INTERMEDIATES)/NOTICE.txt
tools_notice_file_html := $(HOST_OUT_INTERMEDIATES)/NOTICE.html

pdk_fusion_notice_files := $(filter $(TARGET_OUT_NOTICE_FILES)/%, $(ALL_PDK_FUSION_FILES))

$(eval $(call combine-notice-files, \
			$(target_notice_file_txt), \
			$(target_notice_file_html), \
			"Notices for files contained in the filesystem images in this directory:", \
			$(TARGET_OUT_NOTICE_FILES), \
			$(ALL_DEFAULT_INSTALLED_MODULES) $(pdk_fusion_notice_files)))

$(eval $(call combine-notice-files, \
			$(tools_notice_file_txt), \
			$(tools_notice_file_html), \
			"Notices for files contained in the tools directory:", \
			$(HOST_OUT_NOTICE_FILES), \
			$(ALL_DEFAULT_INSTALLED_MODULES)))

# Install the html file at /system/etc/NOTICE.html.gz.
# This is not ideal, but this is very late in the game, after a lot of
# the module processing has already been done -- in fact, we used the
# fact that all that has been done to get the list of modules that we
# need notice files for.
$(target_notice_file_html_gz): $(target_notice_file_html) | $(MINIGZIP)
	$(hide) $(MINIGZIP) -9 < $< > $@
installed_notice_html_gz := $(TARGET_OUT)/etc/NOTICE.html.gz
$(installed_notice_html_gz): $(target_notice_file_html_gz) | $(ACP)
	$(copy-file-to-target)

ifneq ($(BOARD_NAND_PAGE_SIZE),)
mkyaffs2_extra_flags := -c $(BOARD_NAND_PAGE_SIZE)
else
mkyaffs2_extra_flags :=
BOARD_NAND_PAGE_SIZE := 2048
endif

ifneq ($(BOARD_NAND_SPARE_SIZE),)
mkyaffs2_extra_flags += -s $(BOARD_NAND_SPARE_SIZE)
else
BOARD_NAND_SPARE_SIZE := 64
endif

#######
## system tarball
define build-systemtarball-target
    $(call pretty,"Target system fs tarball: $(INSTALLED_SYSTEMTARBALL_TARGET)")
    $(MKTARBALL) $(FS_GET_STATS) \
		$(PRODUCT_OUT) system $(PRIVATE_SYSTEM_TAR) \
		$(INSTALLED_SYSTEMTARBALL_TARGET)
endef

ifndef SYSTEM_TARBALL_FORMAT
    SYSTEM_TARBALL_FORMAT := bz2
endif

system_tar := $(PRODUCT_OUT)/system.tar
INSTALLED_SYSTEMTARBALL_TARGET := $(system_tar).$(SYSTEM_TARBALL_FORMAT)
$(INSTALLED_SYSTEMTARBALL_TARGET): PRIVATE_SYSTEM_TAR := $(system_tar)
$(INSTALLED_SYSTEMTARBALL_TARGET): $(FS_GET_STATS) $(INTERNAL_SYSTEMIMAGE_FILES)
	$(build-systemtarball-target)

.PHONY: systemtarball-nodeps
systemtarball-nodeps: $(FS_GET_STATS) \
                      $(filter-out systemtarball-nodeps stnod,$(MAKECMDGOALS))
	$(build-systemtarball-target)

.PHONY: stnod
stnod: systemtarball-nodeps

# For platform-java goal, add platform as well
ifneq (,$(filter platform-java, $(MAKECMDGOALS)))
PLATFORM_ZIP_ADD_JAVA := true
endif

#######
## platform.zip: system, plus other files to be used in PDK fusion build,
## in a zip file
##
## PDK_PLATFORM_ZIP_PRODUCT_BINARIES is used to store specified files to platform.zip.
## The variable will be typically set from BoardConfig.mk.
## Files under out dir will be rejected to prevent possible conflicts with other rules.
PDK_PLATFORM_ZIP_PRODUCT_BINARIES := $(filter-out $(OUT_DIR)/%,$(PDK_PLATFORM_ZIP_PRODUCT_BINARIES))
INSTALLED_PLATFORM_ZIP := $(PRODUCT_OUT)/platform.zip
$(INSTALLED_PLATFORM_ZIP) : $(INTERNAL_SYSTEMIMAGE_FILES)
	$(call pretty,"Platform zip package: $(INSTALLED_PLATFORM_ZIP)")
	$(hide) rm -f $@
	$(hide) cd $(dir $@) && zip -qry $(notdir $@) \
		$(TARGET_COPY_OUT_SYSTEM) \
		$(patsubst $(PRODUCT_OUT)/%, %, $(TARGET_OUT_NOTICE_FILES)) \
		$(addprefix symbols/,$(PDK_SYMBOL_FILES_LIST))
ifeq (true,$(PLATFORM_ZIP_ADD_JAVA))
	$(hide) cd $(OUT_DIR) && zip -qry $(patsubst $(OUT_DIR)/%,%,$@) $(PDK_PLATFORM_JAVA_ZIP_CONTENTS)
endif
ifneq ($(PDK_PLATFORM_ZIP_PRODUCT_BINARIES),)
	$(hide) zip -qry $@ $(PDK_PLATFORM_ZIP_PRODUCT_BINARIES)
endif

.PHONY: platform
platform: $(INSTALLED_PLATFORM_ZIP)

.PHONY: platform-java
platform-java: platform

# Dist the platform.zip
ifneq (,$(filter platform platform-java, $(MAKECMDGOALS)))
$(call dist-for-goals, platform platform-java, $(INSTALLED_PLATFORM_ZIP))
endif

# -----------------------------------------------------------------
# A zip of the directories that map to the target filesystem.
# This zip can be used to create a filesystem image as a post-build
# step.
#
name := $(TARGET_PRODUCT)
ifeq ($(TARGET_BUILD_TYPE),debug)
  name := $(name)_debug
endif
name := $(name)-target_files-$(FILE_NAME_TAG)

intermediates := $(call intermediates-dir-for,PACKAGING,target_files)
BUILT_TARGET_FILES_PACKAGE := $(intermediates)/$(name).zip
$(BUILT_TARGET_FILES_PACKAGE): intermediates := $(intermediates)
$(BUILT_TARGET_FILES_PACKAGE): \
		zip_root := $(intermediates)/$(name)

# $(1): Directory to copy
# $(2): Location to copy it to
# The "ls -A" is to prevent "acp s/* d" from failing if s is empty.
define package_files-copy-root
  if [ -d "$(strip $(1))" -a "$$(ls -A $(1))" ]; then \
    mkdir -p $(2) && \
    $(ACP) -rd $(strip $(1))/* $(2); \
  fi
endef

$(BUILT_TARGET_FILES_PACKAGE): PRIVATE_RECOVERY_API_VERSION := $(RECOVERY_API_VERSION)
$(BUILT_TARGET_FILES_PACKAGE): PRIVATE_RECOVERY_FSTAB_VERSION := $(RECOVERY_FSTAB_VERSION)

ifeq ($(TARGET_RELEASETOOLS_EXTENSIONS),)
# default to common dir for device vendor
$(BUILT_TARGET_FILES_PACKAGE): tool_extensions := $(TARGET_DEVICE_DIR)/../common
else
$(BUILT_TARGET_FILES_PACKAGE): tool_extensions := $(TARGET_RELEASETOOLS_EXTENSIONS)
endif

# Depending on the various images guarantees that the underlying
# directories are up-to-date.
$(BUILT_TARGET_FILES_PACKAGE): \
		$(INSTALLED_SYSTEMTARBALL_TARGET) \
		$(built_ota_tools) \
		$(APKCERTS_FILE) \
		$(HOST_OUT_EXECUTABLES)/fs_config \
		| $(ACP)
	@echo "Package target files: $@"
	$(hide) rm -rf $@ $(zip_root)
	$(hide) mkdir -p $(dir $@) $(zip_root)
ifdef INSTALLED_KERNEL_TARGET
	$(hide) $(ACP) $(INSTALLED_KERNEL_TARGET) $(zip_root)/RECOVERY/kernel
endif
ifdef INSTALLED_2NDBOOTLOADER_TARGET
	$(hide) $(ACP) \
		$(INSTALLED_2NDBOOTLOADER_TARGET) $(zip_root)/RECOVERY/second
endif
ifdef BOARD_KERNEL_CMDLINE
	$(hide) echo "$(BOARD_KERNEL_CMDLINE)" > $(zip_root)/RECOVERY/cmdline
endif
ifdef BOARD_KERNEL_BASE
	$(hide) echo "$(BOARD_KERNEL_BASE)" > $(zip_root)/RECOVERY/base
endif
ifdef BOARD_KERNEL_PAGESIZE
	$(hide) echo "$(BOARD_KERNEL_PAGESIZE)" > $(zip_root)/RECOVERY/pagesize
endif
ifdef INSTALLED_KERNEL_TARGET
	$(hide) $(ACP) $(INSTALLED_KERNEL_TARGET) $(zip_root)/BOOT/kernel
endif
ifdef INSTALLED_2NDBOOTLOADER_TARGET
	$(hide) $(ACP) \
		$(INSTALLED_2NDBOOTLOADER_TARGET) $(zip_root)/BOOT/second
endif
ifdef BOARD_KERNEL_CMDLINE
	$(hide) echo "$(BOARD_KERNEL_CMDLINE)" > $(zip_root)/BOOT/cmdline
endif
ifdef BOARD_KERNEL_BASE
	$(hide) echo "$(BOARD_KERNEL_BASE)" > $(zip_root)/BOOT/base
endif
ifdef BOARD_KERNEL_PAGESIZE
	$(hide) echo "$(BOARD_KERNEL_PAGESIZE)" > $(zip_root)/BOOT/pagesize
endif
	@# Contents of the system image
	$(hide) $(call package_files-copy-root, \
		$(SYSTEMIMAGE_SOURCE_DIR),$(zip_root)/SYSTEM)
	@# Contents of the data image
	$(hide) $(call package_files-copy-root, \
		$(TARGET_OUT_DATA),$(zip_root)/DATA)
ifdef BOARD_FLASH_BLOCK_SIZE
	$(hide) echo "blocksize=$(BOARD_FLASH_BLOCK_SIZE)" >> $(zip_root)/META/misc_info.txt
endif
	@# Zip everything up, preserving symlinks
	$(hide) (cd $(zip_root) && zip -qry ../$(notdir $@) .)
	@# Run fs_config on all the system, boot ramdisk, and recovery ramdisk files in the zip, and save the output
	$(hide) zipinfo -1 $@ | awk 'BEGIN { FS="SYSTEM/" } /^SYSTEM\// {print "system/" $$2}' | $(HOST_OUT_EXECUTABLES)/fs_config -C -S $(SELINUX_FC) > $(zip_root)/META/filesystem_config.txt
	$(hide) zipinfo -1 $@ | awk 'BEGIN { FS="BOOT/RAMDISK/" } /^BOOT\/RAMDISK\// {print $$2}' | $(HOST_OUT_EXECUTABLES)/fs_config -C -S $(SELINUX_FC) > $(zip_root)/META/boot_filesystem_config.txt
	$(hide) zipinfo -1 $@ | awk 'BEGIN { FS="RECOVERY/RAMDISK/" } /^RECOVERY\/RAMDISK\// {print $$2}' | $(HOST_OUT_EXECUTABLES)/fs_config -C -S $(SELINUX_FC) > $(zip_root)/META/recovery_filesystem_config.txt
	$(hide) (cd $(zip_root) && zip -q ../$(notdir $@) META/*filesystem_config.txt)

.PHONY: target-files-package
target-files-package: $(BUILT_TARGET_FILES_PACKAGE)


ifneq ($(TARGET_PRODUCT),sdk)
ifeq ($(filter generic%,$(TARGET_DEVICE)),)
ifneq ($(TARGET_NO_KERNEL),true)
ifneq ($(recovery_fstab),)

# -----------------------------------------------------------------
# The update package

name := $(TARGET_PRODUCT)
ifeq ($(TARGET_BUILD_TYPE),debug)
  name := $(name)_debug
endif
name := $(name)-img-$(FILE_NAME_TAG)

INTERNAL_UPDATE_PACKAGE_TARGET := $(PRODUCT_OUT)/$(name).zip

ifeq ($(TARGET_RELEASETOOLS_EXTENSIONS),)
# default to common dir for device vendor
$(INTERNAL_UPDATE_PACKAGE_TARGET): extensions := $(TARGET_DEVICE_DIR)/../common
else
$(INTERNAL_UPDATE_PACKAGE_TARGET): extensions := $(TARGET_RELEASETOOLS_EXTENSIONS)
endif

$(INTERNAL_UPDATE_PACKAGE_TARGET): $(BUILT_TARGET_FILES_PACKAGE) $(DISTTOOLS)
	@echo "Package: $@"
	$(hide) MKBOOTIMG=$(BOARD_CUSTOM_MKBOOTIMG) \
	   ./build/tools/releasetools/img_from_target_files -v \
	   -s $(extensions) \
	   -p $(HOST_OUT) \
	   $(BUILT_TARGET_FILES_PACKAGE) $@

.PHONY: updatepackage
updatepackage: $(INTERNAL_UPDATE_PACKAGE_TARGET)

endif    # recovery_fstab is defined
endif    # TARGET_NO_KERNEL != true
endif    # TARGET_DEVICE != generic*
endif    # TARGET_PRODUCT != sdk

# -----------------------------------------------------------------
# A zip of the symbols directory.  Keep the full paths to make it
# more obvious where these files came from.
#
name := $(TARGET_PRODUCT)
ifeq ($(TARGET_BUILD_TYPE),debug)
  name := $(name)_debug
endif
name := $(name)-symbols-$(FILE_NAME_TAG)

SYMBOLS_ZIP := $(PRODUCT_OUT)/$(name).zip
$(SYMBOLS_ZIP): $(INSTALLED_SYSTEMTARBALL_TARGET)
	@echo "Package symbols: $@"
	$(hide) rm -rf $@
	$(hide) mkdir -p $(dir $@)
	$(hide) zip -qr $@ $(TARGET_OUT_UNSTRIPPED)

# -----------------------------------------------------------------
# A zip of the Android Apps. Not keeping full path so that we don't
# include product names when distributing
#
name := $(TARGET_PRODUCT)
ifeq ($(TARGET_BUILD_TYPE),debug)
  name := $(name)_debug
endif
name := $(name)-apps-$(FILE_NAME_TAG)

APPS_ZIP := $(PRODUCT_OUT)/$(name).zip
$(APPS_ZIP): $(INSTALLED_SYSTEMTARBALL_TARGET)
	@echo "Package apps: $@"
	$(hide) rm -rf $@
	$(hide) mkdir -p $(dir $@)
	$(hide) zip -qj $@ $(TARGET_OUT_APPS)/* $(TARGET_OUT_APPS_PRIVILEGED)/*


#------------------------------------------------------------------
# A zip of emma code coverage meta files. Generated for fully emma
# instrumented build.
#
ifeq (true,$(EMMA_INSTRUMENT))
EMMA_META_ZIP := $(PRODUCT_OUT)/emma_meta.zip
# the dependency will be set up later in build/core/main.mk.
$(EMMA_META_ZIP) :
	@echo "Collecting Emma coverage meta files."
	$(hide) find $(TARGET_COMMON_OUT_ROOT) -name "coverage.em" | \
		zip -@ -q $@

endif # EMMA_INSTRUMENT=true

#------------------------------------------------------------------
# A zip of Proguard obfuscation dictionary files.
# Only for apps_only build.
#
ifdef TARGET_BUILD_APPS
PROGUARD_DICT_ZIP := $(PRODUCT_OUT)/$(TARGET_PRODUCT)-proguard-dict-$(FILE_NAME_TAG).zip
# the dependency will be set up later in build/core/main.mk.
$(PROGUARD_DICT_ZIP) :
	@echo "Packaging Proguard obfuscation dictionary files."
	$(hide) dict_files=`find $(TARGET_OUT_COMMON_INTERMEDIATES)/APPS -name proguard_dictionary`; \
		if [ -n "$$dict_files" ]; then \
		  zip -q $@ $$dict_files; \
		else \
		  touch $(dir $@)/dummy; \
		  (cd $(dir $@) && zip -q $(notdir $@) dummy); \
		  zip -qd $@ dummy; \
		  rm $(dir $@)/dummy; \
		fi

endif # TARGET_BUILD_APPS

# -----------------------------------------------------------------
# Old PDK stuffs, retired
# The pdk package (Platform Development Kit)

#ifneq (,$(filter pdk,$(MAKECMDGOALS)))
#  include development/pdk/Pdk.mk
#endif


# -----------------------------------------------------------------
# The SDK

# The SDK includes host-specific components, so it belongs under HOST_OUT.
sdk_dir := $(HOST_OUT)/sdk

# Build a name that looks like:
#
#     linux-x86   --> android-sdk_12345_linux-x86
#     darwin-x86  --> android-sdk_12345_mac-x86
#     windows-x86 --> android-sdk_12345_windows
#
sdk_name := android-sdk_$(FILE_NAME_TAG)
ifeq ($(HOST_OS),darwin)
  INTERNAL_SDK_HOST_OS_NAME := mac
else
  INTERNAL_SDK_HOST_OS_NAME := $(HOST_OS)
endif
ifneq ($(HOST_OS),windows)
  INTERNAL_SDK_HOST_OS_NAME := $(INTERNAL_SDK_HOST_OS_NAME)-$(HOST_ARCH)
endif
sdk_name := $(sdk_name)_$(INTERNAL_SDK_HOST_OS_NAME)

sdk_dep_file := $(sdk_dir)/sdk_deps.mk

ATREE_FILES :=
-include $(sdk_dep_file)

# if we don't have a real list, then use "everything"
ifeq ($(strip $(ATREE_FILES)),)
ATREE_FILES := \
	$(ALL_PREBUILT) \
	$(ALL_COPIED_HEADERS) \
	$(ALL_GENERATED_SOURCES) \
	$(ALL_DEFAULT_INSTALLED_MODULES) \
	$(ALL_DOCS) \
	$(ALL_SDK_FILES)
endif

atree_dir := development/build


sdk_atree_files := \
	$(atree_dir)/sdk.exclude.atree \
	$(atree_dir)/sdk.atree \
	$(atree_dir)/sdk-$(HOST_OS)-$(HOST_ARCH).atree

# development/build/sdk-android-<abi>.atree is used to differentiate
# between architecture models (e.g. ARMv5TE versus ARMv7) when copying
# files like the kernel image. We use TARGET_CPU_ABI because we don't
# have a better way to distinguish between CPU models.
ifneq (,$(strip $(wildcard $(atree_dir)/sdk-android-$(TARGET_CPU_ABI).atree)))
  sdk_atree_files += $(atree_dir)/sdk-android-$(TARGET_CPU_ABI).atree
endif

deps := \
	$(target_notice_file_txt) \
	$(tools_notice_file_txt) \
	$(OUT_DOCS)/offline-sdk-timestamp \
	$(SYMBOLS_ZIP) \
	$(INSTALLED_SYSTEMTARBALL_TARGET) \
	$(INSTALLED_SDK_BUILD_PROP_TARGET) \
	$(INSTALLED_BUILD_PROP_TARGET) \
	$(ATREE_FILES) \
	$(atree_dir)/sdk.atree \
	$(HOST_OUT_EXECUTABLES)/atree \
	$(HOST_OUT_EXECUTABLES)/line_endings

INTERNAL_SDK_TARGET := $(sdk_dir)/$(sdk_name).zip
$(INTERNAL_SDK_TARGET): PRIVATE_NAME := $(sdk_name)
$(INTERNAL_SDK_TARGET): PRIVATE_DIR := $(sdk_dir)/$(sdk_name)
$(INTERNAL_SDK_TARGET): PRIVATE_DEP_FILE := $(sdk_dep_file)
$(INTERNAL_SDK_TARGET): PRIVATE_INPUT_FILES := $(sdk_atree_files)

# Set SDK_GNU_ERROR to non-empty to fail when a GNU target is built.
#
#SDK_GNU_ERROR := true

$(INTERNAL_SDK_TARGET): $(deps)
	@echo "Package SDK: $@"
	$(hide) rm -rf $(PRIVATE_DIR) $@
	$(hide) for f in $(target_gnu_MODULES); do \
	  if [ -f $$f ]; then \
	    echo SDK: $(if $(SDK_GNU_ERROR),ERROR:,warning:) \
	        including GNU target $$f >&2; \
	    FAIL=$(SDK_GNU_ERROR); \
	  fi; \
	done; \
	if [ $$FAIL ]; then exit 1; fi
	$(hide) ( \
		ATREE_STRIP="strip -x" \
		$(HOST_OUT_EXECUTABLES)/atree \
		$(addprefix -f ,$(PRIVATE_INPUT_FILES)) \
			-m $(PRIVATE_DEP_FILE) \
			-I . \
			-I $(PRODUCT_OUT) \
			-I $(HOST_OUT) \
			-I $(TARGET_COMMON_OUT_ROOT) \
			-v "PLATFORM_NAME=android-$(PLATFORM_VERSION)" \
			-v "OUT_DIR=$(OUT_DIR)" \
			-v "HOST_OUT=$(HOST_OUT)" \
			-v "TARGET_ARCH=$(TARGET_ARCH)" \
			-v "TARGET_CPU_ABI=$(TARGET_CPU_ABI)" \
			-v "DLL_EXTENSION=$(HOST_SHLIB_SUFFIX)" \
			-o $(PRIVATE_DIR) && \
		cp -f $(target_notice_file_txt) \
				$(PRIVATE_DIR)/system-images/android-$(PLATFORM_VERSION)/$(TARGET_CPU_ABI)/NOTICE.txt && \
		cp -f $(tools_notice_file_txt) $(PRIVATE_DIR)/platform-tools/NOTICE.txt && \
		HOST_OUT_EXECUTABLES=$(HOST_OUT_EXECUTABLES) HOST_OS=$(HOST_OS) \
			development/build/tools/sdk_clean.sh $(PRIVATE_DIR) && \
		chmod -R ug+rwX $(PRIVATE_DIR) && \
		cd $(dir $@) && zip -rq $(notdir $@) $(PRIVATE_NAME) \
	) || ( rm -rf $(PRIVATE_DIR) $@ && exit 44 )


# Is a Windows SDK requested? If so, we need some definitions from here
# in order to find the Linux SDK used to create the Windows one.
MAIN_SDK_NAME := $(sdk_name)
MAIN_SDK_DIR  := $(sdk_dir)
MAIN_SDK_ZIP  := $(INTERNAL_SDK_TARGET)
ifneq ($(filter win_sdk,$(MAKECMDGOALS)),)
include $(TOPDIR)development/build/tools/windows_sdk.mk
endif

# -----------------------------------------------------------------
# Findbugs
INTERNAL_FINDBUGS_XML_TARGET := $(PRODUCT_OUT)/findbugs.xml
INTERNAL_FINDBUGS_HTML_TARGET := $(PRODUCT_OUT)/findbugs.html
$(INTERNAL_FINDBUGS_XML_TARGET): $(ALL_FINDBUGS_FILES)
	@echo UnionBugs: $@
	$(hide) prebuilt/common/findbugs/bin/unionBugs $(ALL_FINDBUGS_FILES) \
	> $@
$(INTERNAL_FINDBUGS_HTML_TARGET): $(INTERNAL_FINDBUGS_XML_TARGET)
	@echo ConvertXmlToText: $@
	$(hide) prebuilt/common/findbugs/bin/convertXmlToText -html:fancy.xsl \
	$(INTERNAL_FINDBUGS_XML_TARGET) > $@

# -----------------------------------------------------------------
# Findbugs

# -----------------------------------------------------------------
# These are some additional build tasks that need to be run.
ifneq ($(dont_bother),true)
include $(sort $(wildcard $(BUILD_SYSTEM)/tasks/*.mk))
-include $(sort $(wildcard vendor/*/build/tasks/*.mk))
-include $(sort $(wildcard device/*/build/tasks/*.mk))
endif

# -----------------------------------------------------------------
# Create SDK repository packages. Must be done after tasks/* since
# we need the addon rules defined.
ifneq ($(sdk_repo_goal),)
include $(TOPDIR)development/build/tools/sdk_repo.mk
endif
