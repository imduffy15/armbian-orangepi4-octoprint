#!/bin/bash

# Automated eMMC installation script for Orange Pi 4 LTS
# This script helps transfer the system from SD card to eMMC

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Orange Pi 4 LTS eMMC Installation ===${NC}"
echo

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run as root${NC}"
    echo "Please run: sudo $0"
    exit 1
fi

# Check if nand-sata-install is available (Armbian built-in)
if command -v nand-sata-install &> /dev/null; then
    echo -e "${GREEN}Found nand-sata-install utility${NC}"
    echo -e "${YELLOW}We recommend using the official Armbian tool for eMMC installation.${NC}"
    echo
    echo "Would you like to use nand-sata-install? (recommended) [Y/n]"
    read -r response
    if [[ ! "$response" =~ ^[Nn]$ ]]; then
        echo -e "${GREEN}Launching nand-sata-install...${NC}"
        nand-sata-install
        exit 0
    fi
fi

echo -e "${YELLOW}Manual eMMC Installation${NC}"
echo

# Detect devices
echo "Detecting storage devices..."
SD_DEVICE=""
EMMC_DEVICE=""

# Try to identify SD card (usually mmcblk0)
if [ -b "/dev/mmcblk0" ]; then
    # Check if this is the boot device
    if mount | grep -q "/dev/mmcblk0"; then
        SD_DEVICE="/dev/mmcblk0"
        echo -e "${GREEN}Found SD card: $SD_DEVICE${NC}"
    fi
fi

# Try to identify eMMC (usually mmcblk1 or mmcblk2)
for device in /dev/mmcblk1 /dev/mmcblk2; do
    if [ -b "$device" ]; then
        EMMC_DEVICE="$device"
        echo -e "${GREEN}Found eMMC: $EMMC_DEVICE${NC}"
        break
    fi
done

if [ -z "$SD_DEVICE" ]; then
    echo -e "${RED}Error: Could not detect SD card${NC}"
    echo "Please ensure you're booted from SD card"
    exit 1
fi

if [ -z "$EMMC_DEVICE" ]; then
    echo -e "${RED}Error: Could not detect eMMC${NC}"
    echo "Please ensure eMMC module is properly installed"
    exit 1
fi

echo
echo "Detected devices:"
echo "  Source (SD card): $SD_DEVICE"
echo "  Target (eMMC):    $EMMC_DEVICE"
echo

# Show device information
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT | grep -E "mmcblk|NAME"

echo
echo -e "${RED}WARNING: This will ERASE all data on $EMMC_DEVICE!${NC}"
echo -e "${RED}Make sure you have backed up any important data.${NC}"
echo
echo "Type 'yes' to continue or anything else to cancel:"
read -r confirmation

if [ "$confirmation" != "yes" ]; then
    echo "Installation cancelled."
    exit 0
fi

echo
echo -e "${YELLOW}Starting installation...${NC}"

# Step 1: Clone SD to eMMC
echo -e "${GREEN}[1/4] Cloning SD card to eMMC...${NC}"
echo "This may take 10-15 minutes depending on the image size..."

dd if="$SD_DEVICE" of="$EMMC_DEVICE" bs=4M status=progress conv=fsync

echo -e "${GREEN}Clone completed!${NC}"

# Step 2: Resize partition
echo -e "${GREEN}[2/4] Resizing eMMC partition...${NC}"

# Install parted if not available
if ! command -v parted &> /dev/null; then
    apt-get update
    apt-get install -y parted
fi

# Get eMMC size
EMMC_SIZE=$(blockdev --getsize64 "$EMMC_DEVICE")
EMMC_SIZE_GB=$((EMMC_SIZE / 1024 / 1024 / 1024))

echo "eMMC size: ${EMMC_SIZE_GB}GB"

# Resize the partition to use all available space
parted -s "$EMMC_DEVICE" resizepart 1 100%

# Resize the filesystem
EMMC_PART="${EMMC_DEVICE}p1"
e2fsck -f -y "$EMMC_PART" || true
resize2fs "$EMMC_PART"

echo -e "${GREEN}Partition resized!${NC}"

# Step 3: Update boot configuration
echo -e "${GREEN}[3/4] Updating boot configuration...${NC}"

# Mount eMMC
MOUNT_POINT="/mnt/emmc-install"
mkdir -p "$MOUNT_POINT"
mount "$EMMC_PART" "$MOUNT_POINT"

# Update /etc/fstab if needed
if [ -f "$MOUNT_POINT/etc/fstab" ]; then
    # Replace SD card UUID with eMMC UUID
    EMMC_UUID=$(blkid -s UUID -o value "$EMMC_PART")
    if [ -n "$EMMC_UUID" ]; then
        sed -i "s|^UUID=[^ ]*|UUID=$EMMC_UUID|" "$MOUNT_POINT/etc/fstab"
        echo "Updated fstab with eMMC UUID: $EMMC_UUID"
    fi
fi

# Sync and unmount
sync
umount "$MOUNT_POINT"
rmdir "$MOUNT_POINT"

echo -e "${GREEN}Boot configuration updated!${NC}"

# Step 4: Final steps
echo -e "${GREEN}[4/4] Finalizing installation...${NC}"

# Clear any cached data
sync
echo 3 > /proc/sys/vm/drop_caches

echo
echo -e "${GREEN}=== Installation Complete! ===${NC}"
echo
echo "Next steps:"
echo "1. Power off the device: sudo poweroff"
echo "2. Remove the SD card"
echo "3. Power on the device"
echo "4. The system should boot from eMMC"
echo
echo "To verify eMMC boot after startup, run: df -h /"
echo "You should see ${EMMC_PART} as the root filesystem"
echo
