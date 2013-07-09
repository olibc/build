TOOLCHAIN_BUILD_INTERMEDIATES := $(TOOLCHAIN_INTERMEDIATES)build
TOOLCHAINS_CONFIG_STMP := $(TOOLCHAIN_INTERMEDIATES)stmp-config
TOOLCHAINS_BUILD_STMP := $(TOOLCHAIN_INTERMEDIATES)stmp-build
TOOLCHAINS_INSTALL_STMP := $(TOOLCHAIN_INTERMEDIATES)stmp-install

TOOLCHAINS_SOURCE := binutils cloog gcc gdb gmp mpc mpfr ppl isl expat

TOOLCHAINS_SOURCE_PREFIX := toolchain/
TOOLCHAINS_SOURCE_PATH := $(addprefix $(TOOLCHAINS_SOURCE_PREFIX), \
                                      $(TOOLCHAINS_SOURCE) build)
TOOLCHAIN_SOURCE_INTERMEDIATES := $(addprefix $(TOOLCHAIN_INTERMEDIATES), \
                                              $(TOOLCHAINS_SOURCE))

PWD:=$(shell pwd)

TOOLCHAIN_GCC_VERSION := 4.8
TOOLCHAIN_GDB_VERSION := 7.6
TOOLCHAIN_BINTUILS_VERSION := 2.23
TOOLCHAIN_GOLD_VERSION := 2.23
TOOLCHAIN_MPFR_VERSION := 3.1.1
TOOLCHAIN_GMP_VERSION := 5.0.5
TOOLCHAIN_CLOOG_VERSION := 0.18.0
TOOLCHAIN_MPC_VERSION := 1.0.1
TOOLCHAIN_PPL_VERSION := 1.0
TOOLCHAIN_ISL_VERSION := 0.11.1
TOOLCHAIN_EXPAT_VERSION := 2.0.1
TOOLCHAIN_PREFIX := $(PWD)/$(TOOLCHAIN_ROOT)
TOOLCHAIN_SYSROOT := $(PWD)/$(TARGET_SYSROOT)

# We only checkout certain version for save hard disk space
# and speed up the checkout time
TOOLCHAINS_SOURCE_PATH += \
  toolchain/gcc/gcc-$(TOOLCHAIN_GCC_VERSION) \
  toolchain/binutils/binutils-$(TOOLCHAIN_BINTUILS_VERSION) \


TOOLCHAIN_CONFIG_ARGS := \
  --target=arm-linux-androideabi \
  --prefix=$(TOOLCHAIN_PREFIX) \
  --with-sysroot=$(TOOLCHAIN_SYSROOT) \
  --program-transform-name="s&^&arm-olibc-linux-gnueabi-&" \
  --with-gcc-version=$(TOOLCHAIN_GCC_VERSION) \
  --with-gdb-version=$(TOOLCHAIN_GDB_VERSION) \
  --with-binutils-version=$(TOOLCHAIN_BINTUILS_VERSION) \
  --with-mpfr-version=$(TOOLCHAIN_MPFR_VERSION) \
  --with-gmp-version=$(TOOLCHAIN_GMP_VERSION) \
  --with-mpc-version=$(TOOLCHAIN_MPC_VERSION) \
  --with-ppl-version=$(TOOLCHAIN_PPL_VERSION) \
  --with-isl-version=$(TOOLCHAIN_ISL_VERSION) \
  --with-cloog-version=$(TOOLCHAIN_CLOOG_VERSION) \
  --with-expat-version=$(TOOLCHAIN_EXPAT_VERSION) \
  --with-gold-version=$(TOOLCHAIN_GOLD_VERSION) \
  --enable-graphite \
  --enable-lto \


ifneq ($(PREDEFINE_ANDROID_MARCO),true)
TOOLCHAIN_CONFIG_ARGS += \
  --with-specs='%{!D__ANDROID__:-U__ANDROID__}' \

endif

STANDALONGE_TOOLCAHIN_GOAL := $(TOOLCHAINS_INSTALL_STMP) \
                              $(CC_WRAPPER)

$(TOOLCHAINS_INSTALL_STMP): $(TOOLCHAINS_BUILD_STMP)
	mkdir -p $(dir $@)
	$(MAKE) -C $(TOOLCHAIN_BUILD_INTERMEDIATES) install -j1 && touch $@

$(TOOLCHAINS_BUILD_STMP): $(TOOLCHAINS_CONFIG_STMP)
	mkdir -p $(dir $@)
	cd $(TOOLCHAIN_BUILD_INTERMEDIATES) && $(MAKE) build
	touch $@

$(TOOLCHAINS_CONFIG_STMP): $(TOOLCHAINS_SOURCE_PATH) \
                           $(TARGET_SYSROOT_STMP) \
                           $(OLIBC_CONF)
	mkdir -p $(dir $@) $(TOOLCHAIN_BUILD_INTERMEDIATES)
	cd $(TOOLCHAIN_BUILD_INTERMEDIATES) && \
	$(PWD)/toolchain/build/configure $(TOOLCHAIN_CONFIG_ARGS)
	touch $@

toolchain/build:
	mkdir -p $(dir $@)
	git clone git@github.com:olibc/toolchain-build.git $@

toolchain/gcc:
	mkdir -p $(dir $@)
	git clone --bare https://android.googlesource.com/toolchain/gcc $@/.git

toolchain/gcc/gcc-%: toolchain/gcc
	cd toolchain/gcc && \
	   git --work-tree=. checkout HEAD -- $(notdir $@)

toolchain/binutils:
	mkdir -p $(dir $@)
	git clone --bare https://android.googlesource.com/toolchain/binutils $@/.git

toolchain/binutils/binutils-%: toolchain/binutils
	cd toolchain/binutils && \
	  git --work-tree=. checkout HEAD -- $(notdir $@)


toolchain/%:
	mkdir -p $(dir $@)
	git clone https://android.googlesource.com/toolchain/$(notdir $@) $@

standalone-toolchain: $(STANDALONGE_TOOLCAHIN_GOAL)
