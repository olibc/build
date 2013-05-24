TOOLCHAIN_ROOT := $(PRODUCT_OUT)/toolchain
TOOLCHAIN_INTERMEDIATES := $(PRODUCT_OUT)/obj/toolchain/

GCC_WRAPPER_NAME := $(TARGET_ARCH)-olibc-linux-gnueabi-gcc
GCC_WRAPPER := $(TOOLCHAIN_ROOT)/bin/$(GCC_WRAPPER_NAME)
GXX_WRAPPER_NAME := $(TARGET_ARCH)-olibc-linux-gnueabi-g++
GXX_WRAPPER := $(TOOLCHAIN_ROOT)/bin/$(GXX_WRAPPER_NAME)
GCC_SPEC := $(TOOLCHAIN_ROOT)/etc/olibc-gcc-spec

GCC_CFLAGS := $(TOOLCHAIN_INTERMEDIATES)/gcc_default_cflags
GCC_CPPFLAGS := $(TOOLCHAIN_INTERMEDIATES)/gcc_default_cxxflags
GCC_LDFLAGS := $(TOOLCHAIN_INTERMEDIATES)/gcc_default_ldflags
GCC_SPEC_TEMPLATE := build/target/toolchain/spec_template
GCC_SPEC_GENERATER := build/target/toolchain/gen_spec.py
GCC_WRAPPER_TEMPLATE := build/target/toolchain/wrapper_template
GCC_WRAPPER_GENERATER := build/target/toolchain/gen_wrapper.py
RAW_TOOLCHAIN_PATH := $(abspath $(dir $(TARGET_TOOLS_PREFIX)))/../
RAW_TOOLCHAIN_OUTPUT := $(TOOLCHAIN_ROOT)/etc/raw-toolchain

$(RAW_TOOLCHAIN_OUTPUT): $(RAW_TOOLCHAIN_PATH) $(OLIBC_CONF)
	@mkdir -p $(dir $@)
	@cp -a $(RAW_TOOLCHAIN_PATH) $(RAW_TOOLCHAIN_OUTPUT)

$(GCC_CFLAGS): $(OLIBC_CONF)
	@mkdir -p $(dir $@)
	@echo $(TARGET_GLOBAL_CFLAGS) > $@

$(GCC_CPPFLAGS): $(OLIBC_CONF)
	@mkdir -p $(dir $@)
	@echo $(TARGET_GLOBAL_CPPFLAGS) > $@

$(GCC_LDFLAGS): $(OLIBC_CONF)
	@mkdir -p $(dir $@)
	@echo $(TARGET_GLOBAL_LDFLAGS) > $@

$(GCC_SPEC): $(GCC_CFLAGS) $(GCC_CPPFLAGS) $(GCC_LDFLAGS) \
             $(GCC_SPEC_TEMPLATE) $(OLIBC_CONF) $(GCC_SPEC_GENERATER)
	@mkdir -p $(dir $@)
	@$(GCC_SPEC_GENERATER) $(GCC_SPEC_TEMPLATE) \
                               $(TOOLCHAIN_INTERMEDIATES) $@

$(GCC_WRAPPER):
	@mkdir -p $(dir $@)
	@$(GCC_WRAPPER_GENERATER) $(GCC_WRAPPER_TEMPLATE) \
                                  $(notdir $(TARGET_TOOLS_PREFIX))gcc $@
	@chmod +x $@

$(GXX_WRAPPER):
	@mkdir -p $(dir $@)
	@$(GCC_WRAPPER_GENERATER) $(GCC_WRAPPER_TEMPLATE) \
                                  $(notdir $(TARGET_TOOLS_PREFIX))g++ $@
	@chmod +x $@

gcc-wrapper: $(GCC_WRAPPER) $(GXX_WRAPPER) \
             sysroot $(GCC_SPEC) $(RAW_TOOLCHAIN_OUTPUT)