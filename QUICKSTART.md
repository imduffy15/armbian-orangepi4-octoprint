# Quick Start Guide

## Build the Image

```bash
chmod +x build.sh
./build.sh
```

## Flash to SD Card

Using Etcher (recommended): https://www.balena.io/etcher/

Or using dd:
```bash
sudo dd if=~/armbian-build/output/images/Armbian_*.img of=/dev/sdX bs=4M status=progress
sync
```

## First Boot

1. Insert SD card and power on
2. Wait 2-3 minutes for first boot

## Configure WiFi

1. Connect to WiFi: `Octoprint-Setup-XXXX`
2. Password: `octoprint`
3. Open browser: http://10.41.0.1
4. Select your network and enter password
5. Device will reboot and connect

## Access Services

Find your device IP (check router or use mDNS: `orangepi4-lts.local`)

- **Portainer**: http://DEVICE-IP:9000
- **Octoprint**: http://DEVICE-IP:5000

## Default Login

SSH: `root` / `1234` (you'll be prompted to change on first login)

## Troubleshooting

### WiFi AP not showing up
```bash
ssh root@10.41.0.1  # if connected to AP
systemctl restart comitup
```

### Containers not running
```bash
docker ps -a
journalctl -u setup-containers.service
```

### Printer not detected
Check USB device: `ls -l /dev/ttyUSB*`

Update device in Octoprint settings or container configuration.

## Next Steps

1. Set up Octoprint (follow wizard at http://DEVICE-IP:5000)
2. Configure your 3D printer in Octoprint
3. Optional: Add webcam for monitoring
4. Optional: Install Octoprint plugins via web interface

Enjoy your Octoprint setup!
