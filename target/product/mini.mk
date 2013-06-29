#
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
#

ifeq ($(SINGLE_BINARY_SUPPORT),true)
# dynamic linker
PRODUCT_PACKAGES += olibc

else
# Typical configurations of olibc toolchain
PRODUCT_PACKAGES += \
    libc \
    libdl \
    libm

# dynamic linker
PRODUCT_PACKAGES += linker
endif

ifeq ($(EXTRA_CXX_SUPPORT),true)
PRODUCT_PACKAGES += libstdc++
endif

ifeq ($(EXTRA_STLPORT_SUPPORT),true)
PRODUCT_PACKAGES += libstlport
endif

ifeq ($(OLIBC_GCC_WRAPPER),true)
PRODUCT_PACKAGES += gcc-wrapper
endif

ifeq ($(OLIBC_STANDALONG_TOOLCHAIN),true)
PRODUCT_PACKAGES += standalone-toolchain
endif
