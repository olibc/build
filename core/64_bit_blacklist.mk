ifneq ($(TARGET_2ND_ARCH),)

# JNI - needs 64-bit VM
_64_bit_directory_blacklist += \
	external/conscrypt \
	external/neven \
	external/svox \
	libcore \
	packages \

# Chromium/V8: needs 64-bit support
_64_bit_directory_blacklist += \
	external/chromium \
	external/chromium-libpac \
	external/chromium_org \
	external/skia \
	external/v8 \
	frameworks/webview \

# misc build errors
_64_bit_directory_blacklist += \
	external/bluetooth/bluedroid \
	external/oprofile/opcontrol \
	external/tcpdump \
	frameworks/av \
	frameworks/base \
	frameworks/ex \
	frameworks/ml \
	frameworks/opt \
	frameworks/wilhelm \
	device/generic/goldfish/opengl \
	device/generic/goldfish/camera \

# depends on libnl_2
_64_bit_directory_blacklist += \
	external/android-clat \
	external/wpa_suplicant_8

# depends on frameworks/av
_64_bit_directory_blacklist += \
	external/srec \
	hardware/libhardware_legacy/audio \
	hardware/libhardware/modules/audio_remote_submix \

_64_bit_directory_blacklist_pattern := $(addsuffix %,$(_64_bit_directory_blacklist))

define directory_is_64_bit_blacklisted
$(if $(filter $(_64_bit_directory_blacklist_pattern),$(1)),true)
endef
else
define directory_is_64_bit_blacklisted
endef
endif
