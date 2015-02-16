#!/bin/bash

# Bash Color
green='\033[01;32m'
red='\033[01;31m'
blink_red='\033[05;31m'
restore='\033[0m'

clear

# Resources
THREAD="-j$(grep -c ^processor /proc/cpuinfo)"
KERNEL="zImage"
DTBIMAGE="${KERNEL}-dtb"
DEFCONFIG="cyanogenmod_bacon_defconfig"

# Kernel Details
BASE_NAME="MK-CYAN"
BUILD_NO="1.0"
BUILD_VER="$BASE_NAME$BUILD_NO"

# Vars
export LOCALVERSION=~`echo $BUILD_VER`
export CROSS_COMPILE=${HOME}/android/prebuilts/gcc/linux-x86/arm/arm-eabi-4.8/bin/arm-eabi-
export ARCH=arm
export SUBARCH=arm
export KBUILD_BUILD_USER=mk
export KBUILD_BUILD_HOST=mk-cyan-kernel

# Paths
KERNEL_DIR=`pwd`
RELEASE_DIR="${HOME}/mk-releases"
TOOLS_DIR="${HOME}/arm-tools"
MODULES_DIR="${RELEASE_DIR}/modules"
ZIMAGE_DIR="${RELEASE_DIR}"

# Functions
function clean_all {
		rm -rf $MODULES_DIR/*
		rm -rf $RELEASE_DIR/$KERNEL
		rm -rf $RELEASE_DIR/$DTBIMAGE
		make clean && make mrproper
}

function make_kernel {
		echo
		make $DEFCONFIG
		make $THREAD
		cp -vr $KERNEL_DIR/arch/arm/boot/$KERNEL $RELEASE_DIR
}

function make_modules {
		rm `echo $MODULES_DIR"/*"`
		find $KERNEL_DIR -name '*.ko' -exec cp -v {} $MODULES_DIR \;
}

function make_dtb {
		$TOOLS_DIR/dtbToolCM -2 -o $RELEASE_DIR/$DTBIMAGE -s 2048 -p scripts/dtc/ arch/arm/boot/
}

function make_zip {
		echo "N/A"
}

function make_bootimage {
		$TOOLS_DIR/mkbootimg --kernel $RELEASE_DIR/$KERNEL --ramdisk $RELEASE_DIR/ramdisk --cmdline "console=ttyHSL0,115200,n8 androidboot.hardware=bacon user_debug=31 msm_rtb.filter=0x3F ehci-hcd.park=3 androidboot.bootdevice=msm_sdcc.1" --base 0x00000000 --pagesize 2048 --dt $RELEASE_DIR/$DTBIMAGE --ramdisk_offset 0x02000000 --tags_offset 0x01e00000 --output $RELEASE_DIR/bootimg
}
	

DATE_START=$(date +"%s")

echo -e "${green}"
echo "MK Kernel Creation Script:"
echo

echo "---------------"
echo "Kernel Version:"
echo "---------------"

echo -e "${red}"; echo -e "${blink_red}"; echo "$BUILD_VER"; echo -e "${restore}";

echo -e "${green}"
echo "-----------------"
echo "Making Kernel:"
echo "-----------------"
echo -e "${restore}"

while read -p "Do you want to clean stuffs (y/n)? " cchoice
do
case "$cchoice" in
	y|Y )
		clean_all
		echo
		echo "All Cleaned now."
		break
		;;
	n|N )
		break
		;;
	* )
		echo
		echo "Invalid try again!"
		echo
		;;
esac
done

echo

while read -p "Do you want to build kernel (y/n)? " dchoice
do
case "$dchoice" in
	y|Y)
		make_kernel
		make_dtb
		make_modules
		make_bootimage
		make_zip
		break
		;;
	n|N )
		break
		;;
	* )
		echo
		echo "Invalid try again!"
		echo
		;;
esac
done

echo -e "${green}"
echo "-------------------"
echo "Build Completed in:"
echo "-------------------"
echo -e "${restore}"

DATE_END=$(date +"%s")
DIFF=$(($DATE_END - $DATE_START))
echo "Time: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
echo

