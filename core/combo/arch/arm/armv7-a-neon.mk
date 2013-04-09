# Configuration for Linux on ARM.
# Generating binaries for the ARMv7-a architecture and higher with NEON
#
ARCH_ARM_HAVE_ARMV7A            := true
ARCH_ARM_HAVE_VFP               := true
ARCH_ARM_HAVE_VFP_D32           := true
ARCH_ARM_HAVE_NEON              := true

# Note: Hard coding the 'tune' value here is probably not ideal,
# and a better solution should be found in the future.
#
ifeq ($(strip $(TARGET_ARM_CORTEX_A15)),true)
# Wrok around for Crotex-A15 since -mcpu=cortex-a15 is conflict
# with -march=armv7-a,armv7
arch_variant_cflags := \
    -mfloat-abi=softfp \
    -mfpu=neon
else
arch_variant_cflags := \
    -march=armv7-a \
    -mfloat-abi=softfp \
    -mfpu=neon
endif

arch_variant_ldflags := \
	-Wl,--fix-cortex-a8
