# Copyright (C) 2013 olibc developers
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# -----------------------------------------------------------------
# Transform CPU Variant to TARGET_CPU_VARIANT
#
ifeq ($(strip $(TARGET_ARM_GENERIC)),true)
  TARGET_CPU_VARIANT := generic
endif

ifeq ($(strip $(TARGET_ARM_CORTEX_A8)),true)
  TARGET_CPU_VARIANT := cortex-a8
  OLIBC_CFLAGS += -mcpu=cortex-a8
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

ifeq ($(ASYNC_UNWIND_TABLE),true)
  OLIBC_CFLAGS += -fasynchronous-unwind-tables
endif

# -----------------------------------------------------------------
# Build with GNU-Style hash
#

ifeq ($(DEFAULT_GNU_STYLE_HASH),true)
  OLIBC_LDFLAGS += -Wl,--hash-style=gnu
endif

# -----------------------------------------------------------------

OLIBC_CFLAGS += $(EXTRA_OLIBC_CFLAGS)
OLIBC_CPPFLAGS += $(EXTRA_OLIBC_CPPFLAGS)
OLIBC_LDFLAGS += $(EXTRA_OLIBC_LDFLAGS)

# -----------------------------------------------------------------
ifeq ($(SINGLE_BINARY_SUPPORT),true)
  DYNAMIC_LINKER:=/system/lib/olibc.so
else
  DYNAMIC_LINKER:=/system/bin/linker
endif

# -----------------------------------------------------------------
# Android build system hack
#

TARGET_ARCH := $(TARGET_ARCH)

ifeq ($(TARGET_ARCH),arm)
  ifeq ($(ARCH_ARM_HAVE_NEON),true)
    TARGET_PRODUCT=mini_armv7a_neon
  else
    TARGET_PRODUCT=mini_armv7a
  endif
endif

ifeq ($(TARGET_ARCH),mips)
  TARGET_PRODUCT=mini_mips
endif

ifeq ($(TARGET_ARCH),x86)
  TARGET_PRODUCT=mini_x86
endif

TARGET_BUILD_VARIANT=userdebug
TARGET_BUILD_TYPE=release
