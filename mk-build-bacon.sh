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
DTBIMAGE="$KERNEL-dtb"
DEFCONFIG="cyanogenmod_bacon_defconfig"

# Kernel Details
BASE_NAME="mk-linaro-"
BUILD_NO="1.0"
BUILD_VER="$BASE_NAME$BUILD_NO"

# Vars
export LOCALVERSION=~`echo $BUILD_VER`
export CROSS_COMPILE=${HOME}/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-
export ARCH=arm
export SUBARCH=arm
export KBUILD_BUILD_USER=mk
export KBUILD_BUILD_HOST=mk-kernel

# Paths
KERNEL_DIR="${HOME}/android_kernel_oneplus_msm8974"
TOOLS_DIR="${HOME}/mk-kernel-tools"
ZIP_DIR="${TOOLS_DIR}/kernel-update-zip"
ARM_TOOLS="${TOOLS_DIR}/arm-tools"
RELEASE_DIR="${TOOLS_DIR}/release"
MODULES_DIR="${RELEASE_DIR}/modules"

# Functions
function clean_all {
		rm -rf "$ZIP_DIR/boot.img"
		rm -rf "$RELEASE_DIR/$DTBIMAGE"
		rm -rf "$RELEASE_DIR/$KERNEL"
		rm -rf "$RELEASE_DIR/*.zip"
		rm -rf "$MODULES_DIR/*"
	        curr_dir=${PWD}
		cd $KERNEL_DIR
		make clean && make mrproper
		cd $curr_dir
}

function make_kernel {
		echo
		curr_dir=${PWD}
		cd $KERNEL_DIR
		make $DEFCONFIG
		make $THREAD
		cp -vr $KERNEL_DIR/arch/arm/boot/$KERNEL $RELEASE_DIR
		cd $curr_dir
}

function make_modules {
		rm `echo $MODULES_DIR"/*"`
		find $KERNEL_DIR -name '*.ko' -exec cp -v {} $MODULES_DIR \;
}

function make_dtb {
		curr_dir=${PWD}
                cd $KERNEL_DIR
		$ARM_TOOLS/dtbToolCM -2 -o $RELEASE_DIR/$DTBIMAGE -s 2048 -p scripts/dtc/ arch/arm/boot/
		cd $curr_dir
}


function make_zip {
		echo "zip"
		curr_dir=${PWD}
		cd $ZIP_DIR
		rm -rf $RELEASE_DIR/mk-kernel.zip
		zip -r9 $RELEASE_DIR/mk-kernel.zip *
		cd $curr_dir
}

function make_bootimage {
		$ARM_TOOLS/mkbootimg --base 0 --pagesize 2048 --kernel_offset 0x00008000 --ramdisk_offset 0x02000000 --second_offset 0x00f00000 --tags_offset 0x01e00000 --cmdline 'console=ttyHSL0,115200,n8 androidboot.hardware=bacon user_debug=31 msm_rtb.filter=0x3F ehci-hcd.park=3 androidboot.bootdevice=msm_sdcc.1' --kernel $RELEASE_DIR/$KERNEL --ramdisk ramdisk/ramdisk.cpio.gz --dt $RELEASE_DIR/$DTBIMAGE -o $ZIP_DIR/boot.img
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

