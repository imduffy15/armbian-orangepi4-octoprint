# Orange Pi 4 LTS Octoprint Image

Simple Armbian image with Docker and Octoprint for Orange Pi 4 LTS.

## Build

```bash
./docker-build.sh
```

## Flash

```bash
xz -d output/octoprint-orangepi4.img.xz
sudo dd if=output/octoprint-orangepi4.img of=/dev/sdX bs=4M status=progress
```

## Default Login

SSH: root/1234 (change on first login)

## Services

- Octoprint: http://device-ip:5000
- Portainer: http://device-ip:9000

## WiFi Setup

Device creates "Octoprint-Setup" access point. Connect and configure at http://10.41.0.1
