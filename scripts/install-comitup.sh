#!/bin/bash

# Install and configure comitup
# This script should be run during image customization

set -e

echo "Installing comitup dependencies..."

# Install required packages
apt-get update
apt-get install -y \
    python3 \
    python3-pip \
    python3-setuptools \
    network-manager \
    dnsmasq \
    hostapd

# Install comitup from PyPI
pip3 install comitup

# Enable and disable appropriate services
systemctl disable systemd-networkd
systemctl disable wpa_supplicant
systemctl enable NetworkManager
systemctl enable comitup

# Create comitup web service systemd unit
cat > /etc/systemd/system/comitup-web.service <<EOF
[Unit]
Description=Comitup Web Interface
After=comitup.service
Requires=comitup.service

[Service]
Type=simple
ExecStart=/usr/local/bin/comitup-web
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl enable comitup-web

echo "Comitup installation completed!"
