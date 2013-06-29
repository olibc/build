TOOLS := strip as ld ranlib ar nm objcopy objdump addr2line

GCC_WRAPPER_NAME := $(TARGET_ARCH)-olibc-linux-gnueabi-gcc
GCC_WRAPPER := $(TOOLCHAIN_ROOT)/bin/$(GCC_WRAPPER_NAME)
CC_WRAPPER_NAME := $(TARGET_ARCH)-olibc-linux-gnueabi-cc
CC_WRAPPER := $(TOOLCHAIN_ROOT)/bin/$(CC_WRAPPER_NAME)
GXX_WRAPPER_NAME := $(TARGET_ARCH)-olibc-linux-gnueabi-g++
GXX_WRAPPER := $(TOOLCHAIN_ROOT)/bin/$(GXX_WRAPPER_NAME)
GCC_SPEC := $(TOOLCHAIN_ROOT)/etc/olibc-gcc-spec

TOOL_WRAPPERS_NAME := $(addprefix $(TARGET_ARCH)-olibc-linux-gnueabi-, $(TOOLS))
TOOL_WRAPPERS := $(addprefix $(TOOLCHAIN_ROOT)/bin/$(TARGET_ARCH)-olibc-linux-gnueabi-, $(TOOLS))

GCC_CFLAGS := $(TOOLCHAIN_INTERMEDIATES)/gcc_default_cflags
GCC_CPPFLAGS := $(TOOLCHAIN_INTERMEDIATES)/gcc_default_cxxflags
GCC_LDFLAGS := $(TOOLCHAIN_INTERMEDIATES)/gcc_default_ldflags
GCC_SPEC_TEMPLATE := build/target/toolchain/spec_template
GCC_SPEC_GENERATER := build/target/toolchain/gen_spec.py
GCC_WRAPPER_TEMPLATE := build/target/toolchain/wrapper_template
GCC_WRAPPER_GENERATER := build/target/toolchain/gen_wrapper.py
RAW_TOOLCHAIN_PATH := $(abspath $(dir $(TARGET_TOOLS_PREFIX)))/../
RAW_TOOLCHAIN_OUTPUT := $(TOOLCHAIN_ROOT)/etc/raw-toolchain
RAW_TOOLS := $(addprefix $(RAW_TOOLCHAIN_OUTPUT)/bin/$(notdir $(TARGET_TOOLS_PREFIX)), $(TOOLS))

$(RAW_TOOLCHAIN_OUTPUT): $(RAW_TOOLCHAIN_PATH) $(OLIBC_CONF)
	@mkdir -p $(dir $@)
	@cp -a $(RAW_TOOLCHAIN_PATH) $(RAW_TOOLCHAIN_OUTPUT)
	@touch $@/

$(GCC_CFLAGS): $(OLIBC_CONF)
	@mkdir -p $(dir $@)
	@echo $(TARGET_GLOBAL_CFLAGS) > $@
	@echo "host generate gcc flags"

$(GCC_CPPFLAGS): $(OLIBC_CONF)
	@mkdir -p $(dir $@)
	@echo $(TARGET_GLOBAL_CPPFLAGS) > $@
	@echo "host generate g++ flags"

$(GCC_LDFLAGS): $(OLIBC_CONF)
	@mkdir -p $(dir $@)
	@echo $(TARGET_GLOBAL_LDFLAGS) > $@
	@echo "host generate ld flags"

$(GCC_SPEC): $(GCC_CFLAGS) $(GCC_CPPFLAGS) $(GCC_LDFLAGS) \
             $(GCC_SPEC_TEMPLATE) $(OLIBC_CONF) $(GCC_SPEC_GENERATER)
	@mkdir -p $(dir $@)
	@echo "host generate gcc specs"
	$(hide) $(GCC_SPEC_GENERATER) $(GCC_SPEC_TEMPLATE) \
                                      $(TOOLCHAIN_INTERMEDIATES) $@

$(GCC_WRAPPER): $(GCC_WRAPPER_GENERATER) $(GCC_WRAPPER_TEMPLATE) $(OLIBC_CONF)
	@mkdir -p $(dir $@)
	@echo "host generate gcc wrapper"
	$(hide) $(GCC_WRAPPER_GENERATER) $(GCC_WRAPPER_TEMPLATE) \
                                         $(notdir $(TARGET_TOOLS_PREFIX))gcc $@
	@chmod +x $@

$(GXX_WRAPPER): $(GCC_WRAPPER_GENERATER) $(GCC_WRAPPER_TEMPLATE) $(OLIBC_CONF)
	@mkdir -p $(dir $@)
	@echo "host generate g++ wrapper"
	$(hide) $(GCC_WRAPPER_GENERATER) $(GCC_WRAPPER_TEMPLATE) \
                                         $(notdir $(TARGET_TOOLS_PREFIX))g++ $@
	@chmod +x $@

$(CC_WRAPPER): $(GCC_WRAPPER) $(OLIBC_CONF)
	@mkdir -p $(dir $@)
	@echo "host generate cc wrapper"
	$(hide) ln -f -s $(notdir $(GCC_WRAPPER)) $@
	@touch $(GCC_WRAPPER)

$(RAW_TOOLCHAIN_OUTPUT)/bin/$(notdir $(TARGET_TOOLS_PREFIX))%: \
	$(RAW_TOOLCHAIN_OUTPUT)
	@touch $@

$(TOOLCHAIN_ROOT)/bin/$(TARGET_ARCH)-olibc-linux-gnueabi-%: \
	$(RAW_TOOLCHAIN_OUTPUT)/bin/$(notdir $(TARGET_TOOLS_PREFIX))% \
 	$(OLIBC_CONF)
	@mkdir -p $(dir $@)
	@echo "host generate" \
	      $(subst $(TARGET_ARCH)-olibc-linux-gnueabi-,, $(notdir $@)) \
              "wrapper"
	$(hide) ln -f -s ../etc/raw-toolchain/bin/$(notdir $<) $@

gcc-wrapper: $(GCC_WRAPPER) $(GXX_WRAPPER) \
             $(TOOL_WRAPPERS) $(CC_WRAPPER) $(RAW_TOOLS) \
             sysroot $(GCC_SPEC) $(RAW_TOOLCHAIN_OUTPUT)
