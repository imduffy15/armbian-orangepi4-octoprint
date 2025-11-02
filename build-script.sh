#!/bin/bash
set -e

# Cleanup function to run on script exit
cleanup() {
    echo "Cleaning up..."
    # Unmount if mounted
    if mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
        umount "$MOUNT_POINT/etc/resolv.conf" 2>/dev/null || true
        umount "$MOUNT_POINT/dev/pts" 2>/dev/null || true
        umount "$MOUNT_POINT/dev" "$MOUNT_POINT/proc" "$MOUNT_POINT/sys" "$MOUNT_POINT" 2>/dev/null || true
    fi
    # Clean up loop devices for our image file
    if [ -n "$LOOP_DEV" ]; then
        losetup -d "$LOOP_DEV" 2>/dev/null || true
    fi
    # Clean up any remaining loop devices for our image
    for loop_dev in $(losetup -l | grep "$WORK_DIR/armbian.img" | awk '{print $1}' 2>/dev/null || true); do
        losetup -d "$loop_dev" 2>/dev/null || true
    done
}

# Set trap to run cleanup on script exit
trap cleanup EXIT

# Configuration
ARMBIAN_VERSION="25.8.1"
# Use fast European mirror (French) to avoid slow Aliyun redirect
IMAGE_URL="https://armbian.nardol.ovh/dl/orangepi4-lts/archive/Armbian_${ARMBIAN_VERSION}_Orangepi4-lts_bookworm_current_6.12.41_minimal.img.xz"
WORK_DIR="/tmp/armbian-work"
MOUNT_POINT="$WORK_DIR/mnt"

# Install required packages
# Configure faster apt mirrors (US/Europe)
sed -i 's|archive.ubuntu.com|mirror.math.princeton.edu/pub|g' /etc/apt/sources.list
sed -i 's|security.ubuntu.com|mirror.math.princeton.edu/pub|g' /etc/apt/sources.list

apt-get update
apt-get install -y wget xz-utils mount qemu-user-static util-linux parted fdisk e2fsprogs file lsof udev

# Register QEMU emulation for ARM64
echo "Setting up ARM64 emulation..."
update-binfmts --enable qemu-aarch64

# Download and extract image
mkdir -p "$WORK_DIR"

# Clean up any existing loop devices that might be left from previous runs
echo "Cleaning up any existing loop devices from previous runs..."
for loop_dev in $(losetup -l | grep -E "(armbian\.img|armbian-custom\.img)" | awk '{print $1}'); do
    echo "Detaching orphaned loop device: $loop_dev"
    losetup -d "$loop_dev" 2>/dev/null || true
done

wget -O "$WORK_DIR/armbian.img.xz" "$IMAGE_URL" || {
    echo "Primary mirror failed, trying Armbian subdomain mirror..."
    IMAGE_URL_FALLBACK="https://imola.armbian.com/dl/orangepi4-lts/archive/Armbian_${ARMBIAN_VERSION}_Orangepi4-lts_bookworm_current_6.12.41_minimal.img.xz"
    wget -O "$WORK_DIR/armbian.img.xz" "$IMAGE_URL_FALLBACK" || {
        echo "Second mirror failed, trying Russian mirror..."
        IMAGE_URL_FALLBACK2="https://mirror.yandex.ru/mirrors/armbian/dl/orangepi4-lts/archive/Armbian_${ARMBIAN_VERSION}_Orangepi4-lts_bookworm_current_6.12.41_minimal.img.xz"
        wget -O "$WORK_DIR/armbian.img.xz" "$IMAGE_URL_FALLBACK2"
    }
}
xz -d "$WORK_DIR/armbian.img.xz"

# Expand the image to have more space (add 2GB)
echo "Adding 2GB to image file..."
dd if=/dev/zero bs=1M count=2048 >> "$WORK_DIR/armbian.img"

# Check file exists and get info before partition expansion
echo "Image file status before partition expansion:"
ls -la "$WORK_DIR/armbian.img"
file "$WORK_DIR/armbian.img"

# Create a backup copy before modifying partition table
echo "Creating backup before partition modification..."
cp "$WORK_DIR/armbian.img" "$WORK_DIR/armbian.img.backup"

# Expand the partition with more robust error checking
echo "Expanding partition using parted (more reliable than sfdisk)..."

# Try parted first as it's more reliable
parted "$WORK_DIR/armbian.img" --script resizepart 1 100%
PARTED_EXIT_CODE=$?

if [ $PARTED_EXIT_CODE -ne 0 ]; then
    echo "Parted failed, trying sfdisk as fallback..."
    # Restore backup if parted failed
    cp "$WORK_DIR/armbian.img.backup" "$WORK_DIR/armbian.img"
    
    # Try sfdisk as fallback
    echo ", +" | sfdisk -N 1 "$WORK_DIR/armbian.img"
    SFDISK_EXIT_CODE=$?
    
    if [ $SFDISK_EXIT_CODE -ne 0 ]; then
        echo "Error: Both parted and sfdisk failed"
        echo "Restoring from backup..."
        mv "$WORK_DIR/armbian.img.backup" "$WORK_DIR/armbian.img"
        exit 1
    fi
fi

# Sync and wait to ensure file is ready
echo "Syncing filesystem..."
sync
sleep 3

# Verify the image file exists and is accessible
echo "Checking file status after partition expansion:"
if [ ! -f "$WORK_DIR/armbian.img" ]; then
    echo "Error: armbian.img not found after partition expansion"
    echo "Attempting to restore from backup..."
    if [ -f "$WORK_DIR/armbian.img.backup" ]; then
        mv "$WORK_DIR/armbian.img.backup" "$WORK_DIR/armbian.img"
        echo "Backup restored. Trying alternative partition expansion method..."
        
        # Alternative method using parted instead of sfdisk
        parted "$WORK_DIR/armbian.img" --script resizepart 1 100%
        sync
        sleep 2
    else
        echo "No backup available. Exiting."
        exit 1
    fi
fi

ls -la "$WORK_DIR/armbian.img"
echo "File appears to be intact. Proceeding with loop device setup..."

# Additional verification before loop device setup
echo "Final verification before loop device setup:"
if [ ! -f "$WORK_DIR/armbian.img" ]; then
    echo "CRITICAL ERROR: File disappeared between checks!"
    exit 1
fi

# Check file permissions and accessibility
ls -la "$WORK_DIR/armbian.img"
file "$WORK_DIR/armbian.img"
echo "File size: $(stat -c%s "$WORK_DIR/armbian.img") bytes"

# Check if file is being used by other processes
echo "Checking if file is in use:"
lsof "$WORK_DIR/armbian.img" 2>/dev/null || echo "No processes using the file"

# Clean up any existing loop devices for this file
echo "Cleaning up existing loop devices for this file..."
for loop_dev in $(losetup -l | grep "$WORK_DIR/armbian.img" | awk '{print $1}'); do
    echo "Detaching existing loop device: $loop_dev"
    losetup -d "$loop_dev" 2>/dev/null || true
done

# Wait a moment for cleanup to complete
sleep 2

# Final sync before loop setup
sync
sleep 1

# Mount image
mkdir -p "$MOUNT_POINT"

# Setup loop device with better error handling
echo "Setting up loop device..."
echo "Available loop devices before setup:"
losetup -l

LOOP_DEV=$(losetup -f --show -o $((32768 * 512)) "$WORK_DIR/armbian.img")
LOOP_EXIT_CODE=$?

if [ $LOOP_EXIT_CODE -ne 0 ] || [ -z "$LOOP_DEV" ]; then
    echo "Error: Failed to set up loop device (exit code: $LOOP_EXIT_CODE)"
    echo "Available loop devices:"
    losetup -l
    echo "File info:"
    ls -la "$WORK_DIR/armbian.img"
    file "$WORK_DIR/armbian.img"
    exit 1
fi

echo "Loop device $LOOP_DEV created successfully"

# Resize the filesystem
e2fsck -f "$LOOP_DEV" || true
resize2fs "$LOOP_DEV"

mount "$LOOP_DEV" "$MOUNT_POINT"

# Verify mount was successful
if ! mountpoint -q "$MOUNT_POINT"; then
    echo "Error: Failed to mount $LOOP_DEV to $MOUNT_POINT"
    losetup -d "$LOOP_DEV"
    exit 1
fi

# Setup chroot
mount --bind /dev "$MOUNT_POINT/dev"
mount --bind /dev/pts "$MOUNT_POINT/dev/pts"
mount --bind /proc "$MOUNT_POINT/proc"
mount --bind /sys "$MOUNT_POINT/sys"

# Ensure QEMU static binary exists and copy it
if [ ! -f "/usr/bin/qemu-aarch64-static" ]; then
    echo "Error: qemu-aarch64-static not found"
    exit 1
fi
cp /usr/bin/qemu-aarch64-static "$MOUNT_POINT/usr/bin/"

# Verify QEMU binary is executable in chroot
chmod +x "$MOUNT_POINT/usr/bin/qemu-aarch64-static"

# Test ARM64 emulation before proceeding
echo "Testing ARM64 emulation..."
chroot "$MOUNT_POINT" /usr/bin/qemu-aarch64-static /bin/echo "ARM64 emulation working" || {
    echo "Error: ARM64 emulation test failed"
    echo "Available QEMU binaries:"
    ls -la /usr/bin/qemu-* 2>/dev/null || echo "No QEMU binaries found"
    echo "Checking binfmt registrations:"
    cat /proc/sys/fs/binfmt_misc/qemu-aarch64 2>/dev/null || echo "No ARM64 binfmt registration"
    exit 1
}

# Verify filesystem structure and setup DNS for chroot
echo "Checking mounted filesystem structure..."
ls -la "$MOUNT_POINT/"

# Ensure /etc directory exists and is accessible
if [ ! -d "$MOUNT_POINT/etc" ]; then
    echo "Error: /etc directory not found in mounted filesystem"
    echo "Available directories:"
    ls -la "$MOUNT_POINT/"
    exit 1
fi

# Setup DNS for chroot - use host's resolv.conf
echo "Setting up DNS configuration by mounting host resolv.conf..."

# Check if resolv.conf is a symlink and handle it
if [ -L "$MOUNT_POINT/etc/resolv.conf" ]; then
    echo "resolv.conf is a symlink, removing it to enable bind mount"
    rm -f "$MOUNT_POINT/etc/resolv.conf"
elif [ -f "$MOUNT_POINT/etc/resolv.conf" ]; then
    echo "Backing up existing resolv.conf"
    cp "$MOUNT_POINT/etc/resolv.conf" "$MOUNT_POINT/etc/resolv.conf.backup" 2>/dev/null || true
fi

# Create an empty file for bind mounting
touch "$MOUNT_POINT/etc/resolv.conf"

# Bind mount the host's resolv.conf for internet access during chroot
mount --bind /etc/resolv.conf "$MOUNT_POINT/etc/resolv.conf"

# Copy overlay files
cp -r /workspace/userpatches/overlay/* "$MOUNT_POINT/" 2>/dev/null || true
mkdir -p "$MOUNT_POINT/opt/docker-configs"
cp -r /workspace/docker-configs/* "$MOUNT_POINT/opt/docker-configs/" 2>/dev/null || true

# Install packages in chroot
cat > "$MOUNT_POINT/tmp/setup.sh" << 'EOF'
#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

# Test network connectivity
echo "Testing network connectivity..."
if ping -c 1 google.com >/dev/null 2>&1; then
    echo "Network connectivity: OK"
else
    echo "Warning: Network connectivity test failed"
    echo "DNS servers:"
    cat /etc/resolv.conf
    echo "Attempting to resolve google.com manually:"
    nslookup google.com || true
fi

# Clear apt cache first
apt-get clean
rm -rf /var/cache/apt/archives/*

# Update package lists
apt-get update

# Install core packages
apt-get install -y --no-install-recommends python3 python3-pip
apt-get clean && rm -rf /var/cache/apt/archives/*

apt-get install -y --no-install-recommends docker.io
apt-get clean && rm -rf /var/cache/apt/archives/*

apt-get install -y --no-install-recommends network-manager
apt-get clean && rm -rf /var/cache/apt/archives/*

apt-get install -y --no-install-recommends avahi-daemon
apt-get clean && rm -rf /var/cache/apt/archives/*

apt-get install -y --no-install-recommends git
apt-get clean && rm -rf /var/cache/apt/archives/*

apt-get install -y --no-install-recommends docker-compose
apt-get clean && rm -rf /var/cache/apt/archives/*

# Install comitup (from official repository)
# Add the comitup repository and install
wget -qO - https://davesteele.github.io/comitup/keys/davesteele-comitup.gpg.key | apt-key add -
echo "deb https://davesteele.github.io/comitup/repo comitup main" > /etc/apt/sources.list.d/comitup.list
apt-get update
apt-get install -y --no-install-recommends comitup
apt-get clean && rm -rf /var/cache/apt/archives/*

# Enable services
systemctl enable docker 2>/dev/null || true
systemctl enable NetworkManager 2>/dev/null || true  
systemctl enable avahi-daemon 2>/dev/null || true
systemctl enable comitup 2>/dev/null || true
systemctl enable setup-containers.service 2>/dev/null || true
systemctl disable systemd-networkd 2>/dev/null || true
systemctl disable wpa_supplicant 2>/dev/null || true
EOF

chmod +x "$MOUNT_POINT/tmp/setup.sh"

# Run the setup script with explicit ARM64 emulation
echo "Running setup script in ARM64 chroot..."
chroot "$MOUNT_POINT" /usr/bin/qemu-aarch64-static /bin/bash /tmp/setup.sh

# Cleanup
rm -f "$MOUNT_POINT/tmp/setup.sh" "$MOUNT_POINT/usr/bin/qemu-aarch64-static"

# Restore original resolv.conf
if [ -f "$MOUNT_POINT/etc/resolv.conf.backup" ]; then
    mv "$MOUNT_POINT/etc/resolv.conf.backup" "$MOUNT_POINT/etc/resolv.conf"
else
    # Create a basic resolv.conf for the final image
    cat > "$MOUNT_POINT/etc/resolv.conf" << 'RESOLV_EOF'
# This will be overwritten by NetworkManager
nameserver 127.0.0.53
RESOLV_EOF
fi

umount "$MOUNT_POINT/etc/resolv.conf" "$MOUNT_POINT/dev/pts" "$MOUNT_POINT/dev" "$MOUNT_POINT/proc" "$MOUNT_POINT/sys" "$MOUNT_POINT"
losetup -d "$LOOP_DEV"

# Create output
mkdir -p /workspace/output
mv "$WORK_DIR/armbian.img" "/workspace/output/octoprint-orangepi4.img"
xz "/workspace/output/octoprint-orangepi4.img"