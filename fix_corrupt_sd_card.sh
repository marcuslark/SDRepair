#!/bin/bash

#######################################################################
#Author, Marcuslark
#Marcus Lärk Ståhlberg
 #Fullstack, DevOps & Secure Developer
 #Java, Golang, C#, JavaScript
#######################################################################

# Setting up custom colors
red() { echo -e "\033[31m\033[01m$1\033[0m"; }
green() { echo -e "\033[32m\033[01m$1\033[0m"; }
yellow() { echo -e "\033[33m\033[01m$1\033[0m"; }
reading() { read -rp "$(green "$1")" "$2"; }

# Check if fsck is installed
if ! command -v fsck &> /dev/null; then
    echo "$(red "fsck is not installed. Installing util-linux...")"
    if ! sudo apt-get install -y util-linux; then
        echo "$(red "Failed to install util-linux. Please install it manually and rerun the script.")"
        exit 1
    fi
    echo "$(green "util-linux (including fsck) has been installed.")"
fi

# Check if lsblk is installed
if ! command -v lsblk &> /dev/null; then
    echo "$(red "lsblk is not installed. Installing util-linux...")"
    if ! sudo apt-get install -y util-linux; then
        echo "$(red "Failed to install util-linux. Please install it manually and rerun the script.")"
        exit 1
    fi
    echo "$(green "util-linux (including lsblk) has been installed.")"
fi

if [ "$EUID" -ne 0 ]; then
    echo "$(red "This script must be run with sudo. Please use 'sudo $0' to run the script.")"
    exit 1
fi

# List partition names of the SD card using lsblk and save them into variables
partition1=$(lsblk | grep -oE 'mmcblk0p[0-9]+' | head -n 1)
partition2=$(lsblk | grep -oE 'mmcblk0p[0-9]+' | tail -n 1)

if [ -z "$partition1" ] || [ -z "$partition2" ]; then
    echo "$(red "Partition names not found. Exiting.")"
    exit 1
fi

# Display partition names
echo "$(green "Found partitions:") $(yellow "$partition1 and $partition2")"

# Prompt the user to confirm they want to proceed
reading "Do you want to check and repair the SD card's partitions? (y/n): " response

if [ "$response" != "y" ]; then
    echo "$(red "Operation canceled. Exiting.")"
    exit 1
fi

# Prompt the user to confirm the partitions for fsck
reading "You are about to run fsck on $partition1 and $partition2. Are these the correct partitions? (y/n): " confirm_partitions

if [ "$confirm_partitions" != "y" ]; then
    echo "$(red "Operation canceled. Exiting.")"
    exit 1
fi

# Unmount partitions
echo "$(green "Unmounting partitions...")"
umount /dev/"$partition1"
umount /dev/"$partition2"

# Check and repair partitions
echo "$(green "Checking and repairing partitions...")"

# Loop through partitions and perform fsck
for partition in "$partition1" "$partition2"; do
    reading "Do you want to run fsck on /dev/$partition? (y/n): " confirm_fsck
    if [ "$confirm_fsck" == "y" ]; then
        sudo fsck -y /dev/"$partition"
        if [ $? -eq 0 ]; then
            echo "$(green "Filesystem on /dev/$partition is clean.")"
        else
            reading "Errors were found on /dev/$partition. Do you want to repair them? (y/n): " repair_response
            if [ "$repair_response" == "y" ]; then
                sudo fsck -y /dev/"$partition"
                if [ $? -eq 0 ]; then
                    echo "$(green "Errors on /dev/$partition have been repaired.")"
                else
                    echo "$(red "Error: Unable to repair /dev/$partition. Manual intervention may be required.")"
                fi
            else
                echo "$(yellow "No repairs were made to /dev/$partition.")"
            fi
        fi
    else
        echo "$(yellow "Skipping /dev/$partition.")"
    fi
done

echo "$(green "SD card maintenance completed.")"

