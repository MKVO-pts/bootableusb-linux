#!/bin/bash

# check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root." >&2
    exit 1
fi

# select iso file
find / -type f -name "*.iso" 2>/dev/null
read -p "Select the path and the iso file: " iso

# validate that the ISO file exists
while [ ! -f "$iso" ]; do
    read -p "ISO file not found. Please enter a valid file path: " iso
done

# select usb device
lsblk -d -o name,size,type,mountpoint
read -p "Select the device name: " file

# validate that the USB device exists and is not mounted
while true; do
    if [ ! -b "/dev/$file" ]; then
        read -p "USB device not found. Please enter a valid device name: " file
    elif grep -q "/dev/$file" /proc/mounts; then
        read -p "USB device is already mounted. Do you want to unmount it? (y/n): " answer
        case $answer in
            [Yy]* ) umount "/dev/$file"; break;;
            [Nn]* ) read -p "Please enter a different device name: " file;;
            * ) echo "Please answer y or n.";;
        esac
    else
        break
    fi
done

# set variables
iso_file="$iso"
usb_device="/dev/$file"

# unmount all partitions on the USB device
umount "${usb_device}?"* 2>/dev/null

# write the ISO file to the USB device
dd if="$iso_file" of="$usb_device" bs=4M conv=fdatasync status=progress

# sync the device to ensure all data is written
sync

echo "Bootable USB device created: $usb_device"
