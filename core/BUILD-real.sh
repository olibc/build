#!/usr/bin/env bash

DEFAULT_PRODUCT=mini_armv7a_neon
OLIBC_CONF=.config-olibc
TOP=`pwd`

function fatal() {
    echo "FATAL: $1"
    exit -1
}

KCONFIG_DIR=$TOP/external/kconfig
MCONF=mconf

function build_mconf() {
    cd $KCONFIG_DIR
    make -f Makefile.olibc mconf \
	    obj=`pwd` \
	    CC="gcc" HOSTCC="gcc" \
	    LKC_GENPARSER=1
    cd $TOP
}

function menuconfig() {
    if [ ! -f $KCONFIG_DIR/$MCONF ]; then
        build_mconf
    fi
    $KCONFIG_DIR/$MCONF bionic/Config.in
    if [ -f .config ]; then
    # Generate Android build system friendly configurations
    cat .config | sed -e "s/=y$/=true/g" > $OLIBC_CONF
    else
        fatal "Error: no configuration is specified"
    fi

    true > Makefile
    echo "-include $OLIBC_CONF" >> Makefile
    echo "include build/core/main.mk" >> Makefile
}

# FIXME: remove ugly hack
function convert_target() {
  if test "$1" = "arm"; then
      echo "armv7a"
  else
      echo "$1"
  fi
}

product=
subarch=
function select_product_from() {
    if [ -f $1 ]; then
        source $1
	product=$(convert_target $TARGET_ARCH)
	if [ $TARGET_SUBARCH ]; then
		subarch="_$TARGET_SUBARCH"
	fi
	echo "mini_$product$subarch"
    else
        echo "$DEFAULT_PRODUCT"
    fi
}

function select_product() {
    echo "$(select_product_from $OLIBC_CONF)"
}

function sanity_check() {
    if [ ! -f build/envsetup.sh ]; then
        fatal "The build environment is incomplete/incorrect."
    fi
}

BUILD_TARGET_OPTS=
function build() {
    sanity_check
    source build/envsetup.sh

    if [ -f $OLIBC_CONF ]; then
        echo "Use the existing configurations"
    else
        menuconfig
    fi

    lunch "$(select_product)-userdebug" >/dev/null

    BUILD_TARGET_OPTS="`grep TARGET_TOOLS_PREFIX $OLIBC_CONF`"
    eval $BUILD_TARGET_OPTS
    if [ $TARGET_TOOLS_PREFIX ]; then
        BUILD_TARGET_OPTS="TARGET_TOOLS_PREFIX=$TARGET_TOOLS_PREFIX"
    fi
    make $BUILD_TARGET_OPTS $*
}

function clean() {
    rm -rf out
}

function distclean() {
    clean
    make -C $KCONFIG_DIR -f Makefile.olibc distclean
    rm -f .config $OLIBC_CONF
}

function usage() {
    echo "usage: ./BUILD.sh <command|module_name>"
    echo "  Commands:"
    echo "    config     Configure olibc"
    echo "    clean      Clean up all output"
    echo "    distclean  Clean up config file and all output"
    echo "    help       Show this message"
    echo
    echo "If no command is assigned, the script will build olibc from source."
    echo "Alternatively, you can specify module name defined in Android.mk"
    echo "and the build system would try to satisfy the dependency."
    echo
}

case "$1" in
"clean" | "--clean")
    clean
    ;;
"config" | "--config")
    menuconfig
    ;;
"distclean" | "--distclean")
    distclean
    ;;
"") # default rule
    build
    ;;
"help" | "--help")
    usage
    ;;
*)
    build $*
    ;;
esac
