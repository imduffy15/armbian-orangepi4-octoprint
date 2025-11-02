#!/bin/bash

# This script is called by Armbian build system to customize the image
# It runs in a chroot environment

Main() {
    case $RELEASE in
        jammy|bookworm)
            # Install required packages
            echo "Installing base packages..."
            apt-get update
            apt-get install -y \
                docker.io \
                docker-compose \
                python3 \
                python3-pip \
                network-manager \
                avahi-daemon \
                git

            # Enable and start Docker
            systemctl enable docker

            # Add default user to docker group
            usermod -aG docker root

            # Install comitup for WiFi configuration
            echo "Installing comitup..."
            apt-get install -y dnsmasq hostapd
            pip3 install comitup

            # Copy custom scripts and configurations
            if [ -d "/tmp/overlay" ]; then
                echo "Copying overlay files..."
                cp -r /tmp/overlay/* / 2>/dev/null || true
            fi

            # Make scripts executable
            chmod +x /usr/local/bin/setup-*.sh

            # Configure comitup
            systemctl disable systemd-networkd 2>/dev/null || true
            systemctl disable wpa_supplicant 2>/dev/null || true
            systemctl enable NetworkManager

            # Create comitup web service
            cat > /etc/systemd/system/comitup-web.service <<'EOF'
[Unit]
Description=Comitup Web Interface
After=comitup.service network.target
Requires=comitup.service

[Service]
Type=simple
ExecStart=/usr/local/bin/comitup-web
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

            # Enable services
            systemctl enable docker
            systemctl enable avahi-daemon
            systemctl enable comitup
            systemctl enable comitup-web
            systemctl enable setup-containers.service

            echo "Customization completed!"
            ;;
    esac
}

Main "$@"
