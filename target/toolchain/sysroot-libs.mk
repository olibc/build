TARGET_SYSROOT_LIB := $(TARGET_SYSROOT)/usr/lib/

ifeq ($(SINGLE_BINARY_SUPPORT),true)
  SYSROOT_RAW_LIBS := olibc libolibc
  SYSROOT_RAW_STATIC_LIBS := olibc libc libm libolibc
else
  SYSROOT_RAW_LIBS := libc libdl libm
  SYSROOT_RAW_STATIC_LIBS := libc libm
endif

CRT_RAW_FILES := crtbegin_so.o crtbegin_static1.o crtbegin_static.o \
                 crtbrand.o crtend_android.o crtend_so.o \
                 crtbegin_dynamic.o crtbegin_dynamic1.o

$(TARGET_SYSROOT_LIB)%.o: $(TARGET_OUT_INTERMEDIATE_LIBRARIES)/%.o
	$(hide) mkdir -p $(dir $@)
	$(hide) cp $< $@

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

$(TARGET_SYSROOT_LIB)libolibc.%: $(TARGET_SYSROOT_LIB)olibc.%
	$(hide) mkdir -p $(dir $@)
	$(hide) ln -s $(notdir $<) $@

SYSROOT_STATIC_LIBS := $(addsuffix .a, \
                  $(addprefix $(TARGET_SYSROOT_LIB), \
                    $(SYSROOT_RAW_STATIC_LIBS)))

SYSROOT_LIBS := $(addsuffix .so, \
                  $(addprefix $(TARGET_SYSROOT_LIB), \
                    $(SYSROOT_RAW_LIBS)))

CRT_FILES := $(addprefix $(TARGET_SYSROOT_LIB), $(CRT_RAW_FILES))

sysroot: $(SYSROOT_LIBS) $(SYSROOT_STATIC_LIBS) $(CRT_FILES)
