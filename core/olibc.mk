# -----------------------------------------------------------------
# Transform CPU Variant to TARGET_CPU_VARIANT
#

ifeq ($(strip $(TARGET_ARM_GENERIC)),true)
  TARGET_CPU_VARIANT := generic
endif

ifeq ($(strip $(TARGET_ARM_CORTEX_A9)),true)
  TARGET_CPU_VARIANT := cortex-a9
  OLIBC_CFLAGS += -mcpu=cortex-a9
endif

ifeq ($(strip $(TARGET_ARM_CORTEX_A15)),true)
  TARGET_CPU_VARIANT := cortex-a15
  OLIBC_CFLAGS += -mcpu=cortex-a15
endif

ifeq ($(strip $(TARGET_ARM_KRAIT)),true)
  TARGET_CPU_VARIANT := krait
  TARGET_USE_KRAIT_BIONIC_OPTIMIZATION := true
endif

ifeq ($(strip $(TARGET_ARM_SCORPION)),true)
  TARGET_CPU_VARIANT := scorpion
  TARGET_USE_SCORPION_BIONIC_OPTIMIZATION := true
endif

ifeq ($(strip $(TARGET_ARM_SPARROW)),true)
  TARGET_CPU_VARIANT := sparrow
  TARGET_USE_SPARROW_BIONIC_OPTIMIZATION := true
endif

# -----------------------------------------------------------------

ifeq ($(ASYNC_UNWIND_TABLE)),true)
  OLIBC_CFLAGS += -fasynchronous-unwind-tables
endif

# -----------------------------------------------------------------
# Build with GNU-Style hash
#

ifeq ($(DEFAULT_GNU_STYLE_HASH),true)
  OLIBC_LDFLAGS += -Wl,--hash-style=gnu
endif

# -----------------------------------------------------------------

OLIBC_CFLAGS += $(shell echo $(EXTRA_OLIBC_CFLAGS))
OLIBC_CPPFLAGS += $(shell echo $(EXTRA_OLIBC_CPPFLAGS))
OLIBC_LDFLAGS += $(shell echo $(EXTRA_OLIBC_LDFLAGS))

# -----------------------------------------------------------------
#
# This hack is for prevent Makefile dependency broken when OUT_DIR is set
#
# - kconf will generate string along with quote but it might break
#   Makefile dependency due to the fact that its dependency is generated
#   by the compiler which is not specified with quote.
#
ifneq (,$(strip $(OUT_DIR)))
  OUT_DIR := $(shell echo $(OUT_DIR))
endif
