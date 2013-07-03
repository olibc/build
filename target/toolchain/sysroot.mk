include build/target/toolchain/sysroot-headers.mk
include build/target/toolchain/sysroot-libs.mk

$(TARGET_SYSROOT_STMP): $(SYSROOT_LIBS) $(SYSROOT_STATIC_LIBS) $(CRT_FILES)
	@mkdir -p $(dir $@)
	@touch $@

sysroot: $(TARGET_SYSROOT_STMP)
