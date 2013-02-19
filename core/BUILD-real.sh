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
    if [ ! -f $KCONFIG_DIR/MCONF ]; then
        build_mconf
    fi
    $KCONFIG_DIR/$MCONF build/Config.in
    if [ -f .config ]; then
    # Generate Android build system friendly configurations
    cat .config | sed -e :x -e "N; s/=y/=true/; tx" > $OLIBC_CONF
    else
        fatal "Error: no configuration is specified"
    fi

    true > Makefile
    echo "-include .config-olibc" >> Makefile
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

function build() {
    sanity_check
    source build/envsetup.sh

    if [ -f $OLIBC_CONF ]; then
        echo "Use the existing configurations"
    else
        menuconfig
    fi

    lunch "$(select_product)-userdebug" >/dev/null

    make
}

function clean() {
    rm -rf out
}

function distclean() {
    clean
    rm .config $OLIBC_CONF
}

function usage() {
    echo "usage: ./BUILD.sh <command>"
    echo "  Commands:"
    echo "    build      Build olibc"
    echo "    config     Configure olibc"
    echo "    menuconfig Alias of config"
    echo "    clean      Clean up all output"
    echo "    distclean  Clean up config file and all output"
    echo "    help       Show this message"
}

case "$1" in
"clean")
    clean
    ;;
"config" | "menuconfig")
    menuconfig
    ;;
"distclean")
    distclean
    ;;
"build" | "")
    build
    ;;
"help" | "--help")
    usage
    ;;
*)
    echo "Unknown command '$1' !"
    ;;
esac
