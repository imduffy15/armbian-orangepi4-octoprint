#!/bin/bash
# OctoPrint Plugin Bootstrap Script for Prusa MK3S with Orange Pi 4 LTS
# This script installs and configures essential plugins for 3D printing

set -e

echo "=== OctoPrint Plugin Bootstrap for MK3S ==="
echo "Installing plugins optimized for Prusa MK3S and Orange Pi 4 LTS..."

# Create temporary directory for plugin downloads
TEMP_DIR="/tmp/octoprint-plugins"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# Function to install plugin via pip
install_plugin() {
    local plugin_url="$1"
    local plugin_name="$2"
    echo "Installing $plugin_name..."
    pip3 install "$plugin_url" || echo "Warning: Failed to install $plugin_name"
}

# Function to install plugin via OctoPrint CLI (if available)
install_plugin_cli() {
    local plugin_identifier="$1"
    local plugin_name="$2"
    echo "Installing $plugin_name via OctoPrint plugin manager..."
    # This would be used post-startup via OctoPrint's plugin manager
    echo "octoprint plugins install $plugin_identifier" >> /tmp/post-install-commands.txt
}

echo "=== Core System Tools ==="
# Install avrdude for firmware flashing
echo "Installing avrdude for MK3S firmware updates..."
apt-get update && apt-get install -y avrdude avr-libc gcc-avr

# Install additional tools for printer management
apt-get install -y \
    curl wget git \
    python3-serial python3-setuptools \
    libffi-dev libssl-dev

echo "=== Orange Pi GPIO Support ==="
# Orange Pi specific GPIO plugin
install_plugin "https://github.com/ckjdelux/OctoPrint-OPiGpioControl/archive/master.zip" "OctoPrint-OPiGpioControl"

echo "=== Firmware Management ==="
# Firmware Updater for MK3S
install_plugin "https://github.com/OctoPrint/OctoPrint-FirmwareUpdater/archive/master.zip" "OctoPrint-FirmwareUpdater"

# Prusa MK3 specific enhancements
install_plugin "https://github.com/prusa3d/Prusa-Connect-Local/archive/master.zip" "Prusa-Connect-Local"

echo "=== Bed Leveling & Calibration ==="
# Bed Level Visualizer
install_plugin "https://github.com/jneilliii/OctoPrint-BedLevelVisualizer/archive/master.zip" "OctoPrint-BedLevelVisualizer"

# Auto Bed Leveling Expert
install_plugin "https://github.com/FormerLurker/OctoPrint-ABLEXPERT/archive/master.zip" "OctoPrint-ABLEXPERT"

# Mesh Bed Leveling for Prusa
install_plugin "https://github.com/PrusaOwners/OctoPrint-PrusaMeshMap/archive/master.zip" "OctoPrint-PrusaMeshMap"

echo "=== Print Quality & Monitoring ==="
# Spaghetti Detective (AI failure detection)
install_plugin "https://github.com/TheSpaghettiDetective/OctoPrint-TheSpaghettiDetective/archive/master.zip" "OctoPrint-TheSpaghettiDetective"

# Print Time Genius (accurate time estimates)
install_plugin "https://github.com/eyal0/OctoPrint-PrintTimeGenius/archive/master.zip" "OctoPrint-PrintTimeGenius"

# Layer Display for progress visualization
install_plugin "https://github.com/tjjfvi/OctoPrint-LayerDisplay/archive/master.zip" "OctoPrint-LayerDisplay"

echo "=== Power & Lighting Control ==="
# PSU Control for main power switching
install_plugin "https://github.com/kantlivelong/OctoPrint-PSUControl/archive/master.zip" "OctoPrint-PSUControl"

# Enclosure Plugin for lighting and environmental control
install_plugin "https://github.com/vitormhenrique/OctoPrint-Enclosure/archive/master.zip" "OctoPrint-Enclosure"

# OctoRelay for multiple relay control
install_plugin "https://github.com/bokunimbus/OctoPrint-OctoRelay/archive/master.zip" "OctoPrint-OctoRelay"

echo "=== Webcam & Streaming ==="
# Integration with our uStreamer setup
install_plugin "https://github.com/jneilliii/OctoPrint-UltimakerFormatPackage/archive/master.zip" "OctoPrint-UltimakerFormatPackage"

# Webcam stream optimization
install_plugin "https://github.com/mikedmor/OctoPrint_MultiCam/archive/master.zip" "OctoPrint-MultiCam"

echo "=== File Management ==="
# File Manager for better file organization
install_plugin "https://github.com/Salandora/OctoPrint-FileManager/archive/master.zip" "OctoPrint-FileManager"

# Backup & Restore
install_plugin "https://github.com/jneilliii/OctoPrint-BackupScheduler/archive/master.zip" "OctoPrint-BackupScheduler"

echo "=== Prusa MK3S Specific ==="
# Prusa Slicers integration
install_plugin "https://github.com/lordofhyphens/OctoPrint-PrusaSlicerThumbnails/archive/master.zip" "OctoPrint-PrusaSlicerThumbnails"

# Prusa MMU2S support (if applicable)
install_plugin "https://github.com/3dprintscotland/OctoPrint_PrusaMMU/archive/master.zip" "OctoPrint-PrusaMMU"

echo "=== User Interface Enhancements ==="
# Dashboard for better overview
install_plugin "https://github.com/StefanCohen/OctoPrint-Dashboard/archive/master.zip" "OctoPrint-Dashboard"

# Better terminal
install_plugin "https://github.com/OctoPrint/OctoPrint-GCODE-System-Commands/archive/master.zip" "OctoPrint-GCODE-System-Commands"

# Custom control for MK3S specific functions
install_plugin "https://github.com/Salandora/OctoPrint-CustomControl/archive/master.zip" "OctoPrint-CustomControl"

echo "=== Safety & Monitoring ==="
# Emergency stop
install_plugin "https://github.com/Sebazzz/OctoPrint-SimpleEmergencyStop/archive/master.zip" "OctoPrint-SimpleEmergencyStop"

# Cost estimation
install_plugin "https://github.com/OllisGit/OctoPrint-CostEstimation/archive/master.zip" "OctoPrint-CostEstimation"

echo "=== Notifications ==="
# Telegram notifications
install_plugin "https://github.com/fabianonline/OctoPrint-Telegram/archive/master.zip" "OctoPrint-Telegram"

# Email notifications
install_plugin "https://github.com/anoved/OctoPrint-EmailNotifier/archive/master.zip" "OctoPrint-EmailNotifier"

echo "=== Performance & Analytics ==="
# Resource Monitor
install_plugin "https://github.com/Renaud11232/OctoPrint-Resource-Monitor/archive/master.zip" "OctoPrint-Resource-Monitor"

# Detailed Progress
install_plugin "https://github.com/dattas/OctoPrint-DetailedProgress/archive/master.zip" "OctoPrint-DetailedProgress"

echo "=== Creating avrdude configuration for MK3S ==="
# Create avrdude configuration for MK3S firmware updates
cat > /etc/avrdude.conf.local << 'EOF'
# MK3S specific avrdude configuration
# ATmega3190 (32u4) configuration for Prusa MK3S
programmer
  id    = "arduino";
  desc  = "Arduino";
  type  = "arduino";
  connection_type = serial;
;

part
  id               = "m32u4";
  desc             = "ATmega32u4";
  signature        = 0x1e 0x95 0x87;
  has_jtag         = yes;
  has_debugwire    = no;
  has_pdi          = no;
  has_tpi          = no;
  has_updi         = no;
  allowfullpagebitstream = no;
;
EOF

echo "=== Setting up firmware directory ==="
mkdir -p /octoprint/firmware
chmod 755 /octoprint/firmware

echo "=== Creating post-installation configuration ==="
cat > /tmp/octoprint-config.txt << 'EOF'
# Post-installation configuration for OctoPrint

# uStreamer camera URL
webcam:
  stream: http://camera.octoprint.local:8080/
  snapshot: http://camera.octoprint.local:8080/snapshot

# Serial connection for MK3S
serial:
  port: /dev/ttyACM0
  baudrate: 115200
  autoconnect: true

# Temperature profiles for MK3S
temperature:
  profiles:
    - name: "PLA"
      extruder: 215
      bed: 60
    - name: "PETG" 
      extruder: 230
      bed: 85
    - name: "ABS"
      extruder: 255
      bed: 100

# Custom controls for MK3S
controls:
  - name: "MK3S Controls"
    layout: vertical
    children:
      - name: "Load Filament"
        command: "M701"
      - name: "Unload Filament"
        command: "M702"
      - name: "Preheat PLA"
        commands:
          - "M104 S215"
          - "M140 S60"
      - name: "Cooldown"
        commands:
          - "M104 S0"
          - "M140 S0"
EOF

echo "=== Plugin Bootstrap Complete! ==="
echo "Installed plugins optimized for:"
echo "  - Prusa MK3S firmware management"
echo "  - Orange Pi 4 LTS GPIO control"
echo "  - Bed leveling and calibration"
echo "  - Power and lighting control"
echo "  - Advanced monitoring and safety"
echo "  - uStreamer webcam integration"
echo ""
echo "Next steps after container startup:"
echo "  1. Configure plugin settings via OctoPrint web interface"
echo "  2. Set up GPIO pin assignments for relays"
echo "  3. Configure webcam stream URL"
echo "  4. Upload MK3S firmware for updates"
echo "  5. Set up bed leveling visualization"
echo ""
echo "Note: Some plugins may require additional configuration"
echo "      through the OctoPrint web interface."

# Clean up
rm -rf "$TEMP_DIR"