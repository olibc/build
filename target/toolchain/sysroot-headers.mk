TARGET_SYSROOT_INCLUDE := $(TARGET_SYSROOT)/usr/include/

LIBC_RAW_HEADERS := $(shell find bionic/libc/include/ -name *.h -printf "%P ")
LIBC_HEADERS := $(addprefix $(TARGET_SYSROOT_INCLUDE), $(LIBC_RAW_HEADERS))
LIBCXX_RAW_HEADERS := $(shell find bionic/libstdc++/include/ -name "*" -printf "%P ")
LIBCXX_HEADERS := $(addprefix $(TARGET_SYSROOT_INCLUDE), $(LIBCXX_RAW_HEADERS))
KERNEL_RAW_HEADERS := $(shell find $(KERNEL_HEADERS_ARCH) -name *.h -printf "%P ")
KERNEL_HEADERS := $(addprefix $(TARGET_SYSROOT_INCLUDE), $(KERNEL_RAW_HEADERS))
KERNEL_RAW_COMMON_HEADERS := $(shell find bionic/libc/kernel/common/ -name *.h -printf "%P ")
KERNEL_COMMON_HEADERS := $(addprefix $(TARGET_SYSROOT_INCLUDE), $(KERNEL_RAW_COMMON_HEADERS))
ARCH_RAW_HEADERS := $(shell find bionic/libc/arch-$(TARGET_ARCH)/include/ -name *.h -printf "%P ")
ARCH_HEADERS := $(addprefix $(TARGET_SYSROOT_INCLUDE), $(ARCH_RAW_HEADERS))
LIBTHREAD_DB_RAW_HEADERS := $(shell find bionic/libthread_db/include/ -name *.h -printf "%P ")
LIBTHREAD_DB_HEADERS := $(addprefix $(TARGET_SYSROOT_INCLUDE), $(LIBTHREAD_DB_RAW_HEADERS))
LIBM_RAW_HEADERS := $(shell find bionic/libm/include/ -maxdepth 1 -name *.h -printf "%P ")
LIBM_HEADERS := $(addprefix $(TARGET_SYSROOT_INCLUDE), $(LIBM_RAW_HEADERS))
LIBM_ARCH_RAW_HEADERS := $(shell find bionic/libm/include/$(TARGET_ARCH)/ -name *.h -printf "%P ")
LIBM_ARCH_HEADERS := $(addprefix $(TARGET_SYSROOT_INCLUDE), $(LIBM_ARCH_RAW_HEADERS))

$(TARGET_SYSROOT_INCLUDE)%.h: bionic/libc/include/%.h
	$(hide) mkdir -p $(dir $@)
	$(hide) cp $< $@

$(TARGET_SYSROOT_INCLUDE)%.h: bionic/libm/include/%.h
	$(hide) mkdir -p $(dir $@)
	$(hide) cp $< $@

$(TARGET_SYSROOT_INCLUDE)%.h: bionic/libm/include/$(TARGET_ARCH)/%.h
	$(hide) mkdir -p $(dir $@)
	$(hide) cp $< $@

$(TARGET_SYSROOT_INCLUDE)%.h: $(KERNEL_HEADERS_ARCH)/%.h
	$(hide) mkdir -p $(dir $@)
	$(hide) cp $< $@

$(TARGET_SYSROOT_INCLUDE)%.h: bionic/libc/kernel/common/%.h
	$(hide) mkdir -p $(dir $@)
	$(hide) cp $< $@

$(TARGET_SYSROOT_INCLUDE)%.h: bionic/libc/arch-$(TARGET_ARCH)/include/%.h
	$(hide) mkdir -p $(dir $@)
	$(hide) cp $< $@

$(TARGET_SYSROOT_INCLUDE)%: bionic/libstdc++/include/%
	$(hide) mkdir -p $(dir $@)
	$(hide) cp $< $@

$(TARGET_SYSROOT_INCLUDE)%.h: bionic/libthread_db/include/%.h
	$(hide) mkdir -p $(dir $@)
	$(hide) cp $< $@

sysroot: $(LIBC_HEADERS) $(KERNEL_HEADERS) \
         $(LIBCXX_HEADERS) $(KERNEL_COMMON_HEADERS) \
         $(ARCH_HEADERS) $(LIBTHREAD_DB_HEADERS) \
         $(LIBM_HEADERS) $(LIBM_ARCH_HEADERS)