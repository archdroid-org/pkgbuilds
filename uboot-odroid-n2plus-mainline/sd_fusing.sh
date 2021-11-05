#!/bin/sh
#
# Script to facilitate flashing mainline u-boot.
#

abort() {
	echo $1
	exit 1
}

if [ -z $1 ]; then
	echo "Script that facilitates flashing mainline u-boot."
	echo ""
	echo "  Usage: $0 </dev/mmcblk[1-9]>"
	echo ""
	echo "  Example: $0 /dev/mmcblk1"
	echo ""
	echo "  Note: You can also provide the u-boot binary path"
	echo "        by using the UBOOT environment variable."
	echo "        Default u-boot binary: /boot/u-boot.bin.sd.bin"
	echo ""
	echo "        Example:"
	echo "        UBOOT=/boot/u-boot.bin.emmc.bin $0 /dev/sda"

	exit
elif [ ! -b "$1" ]; then
	abort "Error: Provided device is not a valid block device."
fi

if [ "$(id -u)" != "0" ]; then
	abort "This script must be run as root."
fi

[ -z ${UBOOT} ] && UBOOT=/boot/u-boot.bin.sd.bin
[ ! -f ${UBOOT} ] && abort "Error: ${UBOOT} doesn't exist"

START_SECTOR=$(fdisk -l $1 | grep -E "$1[p]*[0-9]" | head -n 1 | awk '{print $2}')

if [ $START_SECTOR -lt 3072 ]; then
	echo "This u-boot binary is larger than upstream and can damage"
	echo "your first partition which starts at sector: $START_SECTOR"
	echo "It is recommended that your first partition starts at least"
	echo "at sector 3072."
	echo ""
	echo "Are you soure you want to continue? y/N: "
	read -r answer

	case $answer in
		[yY][eE][sS]|[yY])
			break
			;;
		*)
			echo "Not flashing."
			exit
			;;
	esac
fi

echo "Flashing $UBOOT..."

dd if=$UBOOT of=$1 conv=fsync,notrunc bs=512 skip=1 seek=1
dd if=$UBOOT of=$1 conv=fsync,notrunc bs=1 count=444

sync

echo "Done!"
