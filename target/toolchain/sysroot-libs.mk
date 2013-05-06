TARGET_SYSROOT_LIB := $(TARGET_SYSROOT)/lib/

ifeq ($(SINGLE_BINARY_SUPPORT),true)
  SYSROOT_RAW_LIBS := olibc
  SYSROOT_RAW_STATIC_LIBS := olibc libc libm
else
  SYSROOT_RAW_LIBS := libc libdl libm
  SYSROOT_RAW_STATIC_LIBS := libc libm
endif

$(TARGET_OUT_SHARED_LIBRARIES_UNSTRIPPED)/%.so: %

$(TARGET_SYSROOT_LIB)%.so: $(TARGET_OUT_SHARED_LIBRARIES_UNSTRIPPED)/%.so
	$(hide) mkdir -p $(dir $@)
	$(hide) cp $< $@

$(TARGET_SYSROOT_LIB)libc.a: $(call intermediates-dir-for, STATIC_LIBRARIES,libc,)/libc.a
	$(hide) mkdir -p $(dir $@)
	$(hide) cp $< $@

$(TARGET_SYSROOT_LIB)libm.a: $(call intermediates-dir-for, STATIC_LIBRARIES,libm,)/libm.a
	$(hide) mkdir -p $(dir $@)
	$(hide) cp $< $@

$(TARGET_SYSROOT_LIB)olibc.a: $(call intermediates-dir-for, STATIC_LIBRARIES,olibc,)/olibc.a
	$(hide) mkdir -p $(dir $@)
	$(hide) cp $< $@

SYSROOT_STATIC_LIBS := $(addsuffix .a, \
                  $(addprefix $(TARGET_SYSROOT_LIB), \
                    $(SYSROOT_RAW_STATIC_LIBS)))

SYSROOT_LIBS := $(addsuffix .so, \
                  $(addprefix $(TARGET_SYSROOT_LIB), \
                    $(SYSROOT_RAW_LIBS)))

sysroot: $(SYSROOT_LIBS) $(SYSROOT_STATIC_LIBS)
