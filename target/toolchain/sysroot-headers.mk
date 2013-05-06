TARGET_SYSROOT_INCLUDE := $(TARGET_SYSROOT)/include/

LIBC_RAW_HEADERS := $(shell find bionic/libc/include/ -name *.h -printf "%P ")
LIBC_HEADERS := $(addprefix $(TARGET_SYSROOT_INCLUDE), $(LIBC_RAW_HEADERS))
LIBCXX_RAW_HEADERS := $(shell find bionic/libstdc++/include/ -name "*" -printf "%P ")
LIBCXX_HEADERS := $(addprefix $(TARGET_SYSROOT_INCLUDE), $(LIBCXX_RAW_HEADERS))
KERNEL_RAW_HEADERS := $(shell find $(KERNEL_HEADERS_ARCH) -name *.h -printf "%P ")
KERNEL_HEADERS := $(addprefix $(TARGET_SYSROOT_INCLUDE), $(KERNEL_RAW_HEADERS))
KERNEL_RAW_COMMON_HEADERS := $(shell find bionic/libc/kernel/common/ -name *.h -printf "%P ")
KERNEL_COMMON_HEADERS := $(addprefix $(TARGET_SYSROOT_INCLUDE), $(KERNEL_RAW_COMMON_HEADERS))

$(TARGET_SYSROOT_INCLUDE)%.h: bionic/libc/include/%.h
	$(hide) mkdir -p $(dir $@)
	$(hide) cp $< $@

$(TARGET_SYSROOT_INCLUDE)%.h: $(KERNEL_HEADERS_ARCH)/%.h
	$(hide) mkdir -p $(dir $@)
	$(hide) cp $< $@

$(TARGET_SYSROOT_INCLUDE)%.h: bionic/libc/kernel/common/%.h
	$(hide) mkdir -p $(dir $@)
	$(hide) cp $< $@


$(TARGET_SYSROOT_INCLUDE)%: bionic/libstdc++/include/%
	$(hide) mkdir -p $(dir $@)
	$(hide) cp $< $@


sysroot: $(LIBC_HEADERS) $(KERNEL_HEADERS) $(LIBCXX_HEADERS) $(KERNEL_COMMON_HEADERS)
