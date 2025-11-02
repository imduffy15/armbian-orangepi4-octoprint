#!/bin/bash

# Build script for custom Armbian image for Orange Pi 4 LTS with Octoprint

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARMBIAN_DIR="${ARMBIAN_DIR:-$HOME/armbian-build}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Armbian Orange Pi 4 LTS Octoprint Builder ===${NC}"
echo

# Check if Armbian build system exists
if [ ! -d "$ARMBIAN_DIR" ]; then
    echo -e "${YELLOW}Armbian build directory not found at $ARMBIAN_DIR${NC}"
    echo -e "${YELLOW}Cloning Armbian build system...${NC}"

    git clone --depth 1 https://github.com/armbian/build "$ARMBIAN_DIR"
    echo -e "${GREEN}Armbian build system cloned successfully${NC}"
fi

# Copy userpatches to Armbian build directory
echo -e "${YELLOW}Copying custom configurations...${NC}"
cp -r "$SCRIPT_DIR/userpatches/"* "$ARMBIAN_DIR/userpatches/"

echo -e "${GREEN}Custom configurations copied${NC}"
echo

# Build the image
echo -e "${YELLOW}Starting Armbian build...${NC}"
echo -e "${YELLOW}This may take a while (1-2 hours depending on your system)${NC}"
echo

cd "$ARMBIAN_DIR"

# Run the build
./compile.sh \
    BOARD=orangepi4-lts \
    BRANCH=current \
    RELEASE=bookworm \
    BUILD_MINIMAL=no \
    BUILD_DESKTOP=no \
    KERNEL_CONFIGURE=no \
    COMPRESS_OUTPUTIMAGE=sha,img

echo
echo -e "${GREEN}=== Build completed! ===${NC}"
echo -e "${GREEN}Image location: $ARMBIAN_DIR/output/images/${NC}"
echo
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Flash the image to SD card using Etcher or dd"
echo "2. Boot the Orange Pi 4 LTS"
echo "3. Connect to 'Octoprint-Setup' WiFi network (password: octoprint)"
echo "4. Navigate to http://10.41.0.1 to configure WiFi"
echo "5. After WiFi is configured, access:"
echo "   - Portainer: http://<device-ip>:9000"
echo "   - Octoprint: http://<device-ip>:5000"
echo
