# Transform CPU Variant to TARGET_CPU_VARIANT
#
# TODO: Scorpion and Sparrow are just set to krait now...

ifeq ($(strip $(TARGET_ARM_GENERIC)),true)
TARGET_CPU_VARIANT := generic
endif

ifeq ($(strip $(TARGET_ARM_CORTEX_A9)),true)
TARGET_CPU_VARIANT := cortex-a9
endif

ifeq ($(strip $(TARGET_ARM_CORTEX_A15)),true)
TARGET_CPU_VARIANT := cortex-a15
endif

ifeq ($(strip $(TARGET_ARM_KRAIT)),true)
TARGET_CPU_VARIANT := krait
TARGET_USE_KRAIT_BIONIC_OPTIMIZATION := true
endif

ifeq ($(strip $(TARGET_ARM_SCORPION)),true)
TARGET_CPU_VARIANT := krait
TARGET_USE_SCORPION_BIONIC_OPTIMIZATION := true
endif

ifeq ($(strip $(TARGET_ARM_SPARROW)),true)
TARGET_CPU_VARIANT := krait
TARGET_USE_SPARROW_BIONIC_OPTIMIZATION := true
endif
