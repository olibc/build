LOCAL_PATH := $(call my-dir)

TOOLCHAIN_ROOT := $(OUT_DIR)/toolchain
TOOLCHAIN_INTERMEDIATES := $(PRODUCT_OUT)/obj/toolchain/

TARGET_SYSROOT := $(OUT_DIR)/toolchain/sysroot

TARGET_SYSROOT_STMP := $(TOOLCHAIN_INTERMEDIATES)/stmp-sysroot

include build/target/toolchain/sysroot.mk
include build/target/toolchain/gcc-wrapper.mk
include build/target/toolchain/standalone-toolchain.mk
