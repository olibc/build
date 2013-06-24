TARGET_SYSROOT_LIB := $(TARGET_SYSROOT)/usr/lib/

SYSROOT_RAW_LIBS := libc libdl libm libthread_db
SYSROOT_RAW_STATIC_LIBS := libc libm libthread_db
ifeq ($(SINGLE_BINARY_SUPPORT),true)
  SYSROOT_RAW_LIBS += olibc libolibc
  SYSROOT_RAW_STATIC_LIBS += olibc libolibc
endif

CRT_RAW_FILES := crtbegin_so.o crtbegin_static1.o crtbegin_static.o \
                 crtbrand.o crtend_android.o crtend_so.o \
                 crtbegin_dynamic.o crtbegin_dynamic1.o

define generate-sysroot-lib
  @mkdir -p $(dir $@)
  @echo "host sysroot lib: ($@)"
  $(hide) cp $< $@
endef

$(TARGET_SYSROOT_LIB)%.o: $(TARGET_OUT_INTERMEDIATE_LIBRARIES)/%.o
	$(generate-sysroot-lib)

$(TARGET_OUT_SHARED_LIBRARIES_UNSTRIPPED)/%.so: %

$(TARGET_SYSROOT_LIB)%.so: $(TARGET_OUT_SHARED_LIBRARIES_UNSTRIPPED)/%.so
	$(generate-sysroot-lib)

ifeq ($(SINGLE_BINARY_SUPPORT),true)
$(TARGET_SYSROOT_LIB)libc.so:
	@mkdir -p $(dir $@)
	@ln -f -s olibc.so $@

$(TARGET_SYSROOT_LIB)libm.so:
	@mkdir -p $(dir $@)
	@ln -f -s olibc.so $@

$(TARGET_SYSROOT_LIB)libdl.so:
	@mkdir -p $(dir $@)
	@ln -f -s olibc.so $@
endif

$(TARGET_SYSROOT_LIB)libc.a: $(call intermediates-dir-for, STATIC_LIBRARIES,libc,)/libc.a
	$(generate-sysroot-lib)

$(TARGET_SYSROOT_LIB)libm.a: $(call intermediates-dir-for, STATIC_LIBRARIES,libm,)/libm.a
	$(generate-sysroot-lib)

$(TARGET_SYSROOT_LIB)olibc.a: $(call intermediates-dir-for, STATIC_LIBRARIES,olibc,)/olibc.a
	$(generate-sysroot-lib)

$(TARGET_SYSROOT_LIB)libthread_db.a: $(call intermediates-dir-for, STATIC_LIBRARIES,olibc,)/olibc.a
	$(generate-sysroot-lib)

$(TARGET_SYSROOT_LIB)libolibc.%: $(TARGET_SYSROOT_LIB)olibc.%
	$(generate-sysroot-lib)

SYSROOT_STATIC_LIBS := $(addsuffix .a, \
                  $(addprefix $(TARGET_SYSROOT_LIB), \
                    $(SYSROOT_RAW_STATIC_LIBS)))

SYSROOT_LIBS := $(addsuffix .so, \
                  $(addprefix $(TARGET_SYSROOT_LIB), \
                    $(SYSROOT_RAW_LIBS)))

CRT_FILES := $(addprefix $(TARGET_SYSROOT_LIB), $(CRT_RAW_FILES))

sysroot: $(SYSROOT_LIBS) $(SYSROOT_STATIC_LIBS) $(CRT_FILES)
