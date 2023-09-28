#!/bin/bash

KERNEL_DIR=$(pwd)
TOOLCHAINS=$HOME/toolchains
CLANG_DIR=clang
GCC_AARCH64_DIR=gcc_4.9
GCC_ARM_DIR=gcc_4.9_arm
BUILD_TOOLS_DIR=build_tools
RELEASE_DIR=release

if [[ ! -e KernelSU/kernel/Kconfig ]]; then
    exit -1
fi

fetch_clang() {
    CLANG_URL=https://github.com/LineageOS/android_prebuilts_clang_kernel_linux-x86_clang-r416183b.git
    if [[ ! -d $CLANG_DIR ]]; then
        git clone --depth=1 $CLANG_URL $CLANG_DIR
    fi
}

fetch_gcc() {
    GCC_AARCH64_URL=https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9.git
    GCC_ARM_URL=https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9.git
    if [[ ! -d $GCC_AARCH64_DIR ]]; then
        git clone --depth=1 $GCC_AARCH64_URL $GCC_AARCH64_DIR
    fi
    if [[ ! -d $GCC_ARM_DIR ]]; then
        git clone --depth=1 $GCC_ARM_URL $GCC_ARM_DIR
    fi
}

fetch_build_tools() {
    BUILD_TOOLS_URL=https://github.com/LineageOS/android_prebuilts_build-tools.git
    if [[ ! -d $BUILD_TOOLS_DIR ]]; then
        git clone --depth=1 $BUILD_TOOLS_URL $BUILD_TOOLS_DIR
    fi
}

install_toolchains() {
    export PATH=$TOOLCHAINS/$BUILD_TOOLS_DIR/path/linux-x86/:$PATH
    export PATH=$TOOLCHAINS/$BUILD_TOOLS_DIR/linux-x86/bin/:$PATH
    export PATH=$TOOLCHAINS/$CLANG_DIR/bin:$PATH
    export PATH=$TOOLCHAINS/$GCC_AARCH64_DIR/bin:$PATH
    export PATH=$TOOLCHAINS/$GCC_ARM_DIR/bin:$PATH
}

fetch_toolchains() {
    if [[ ! -d $TOOLCHAINS ]]; then
        mkdir $TOOLCHAINS
    fi
    cd $TOOLCHAINS

    fetch_clang
    fetch_gcc
    fetch_build_tools

    install_toolchains
}

copy_output_to_release() {
    if [[ ! -d $RELEASE_DIR ]]; then
        mkdir $RELEASE_DIR
    fi
    IMAGE=out/arch/arm64/boot/Image.gz
    if [[ -e $IMAGE ]]; then
        cp $IMAGE $RELEASE_DIR
    fi
}

OUT=out
ARCH=arm64
SUBARCH=arm64
CC=clang
CROSS_COMPILE=aarch64-linux-android-
CROSS_COMPILE_ARM32=arm-linux-androideabi-
CLANG_TRIPLE=aarch64-linux-gnu-

fetch_toolchains

cd $KERNEL_DIR
make O=$OUT ARCH=$ARCH SUBARCH=$SUBARCH CC=$CC sagit_defconfig

make O=$OUT \
    CC=$CC \
    ARCH=$ARCH \
    SUBARCH=$SUBARCH \
    CROSS_COMPILE=$CROSS_COMPILE \
    CROSS_COMPILE_ARM32=$CROSS_COMPILE_ARM32 \
    CLANG_TRIPLE=$CLANG_TRIPLE \
    -j$(nproc --all)

copy_output_to_release
