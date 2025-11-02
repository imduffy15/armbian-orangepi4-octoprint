# Armbian Orange Pi 4 LTS - OctoPrint Image

Custom Armbian image for Orange Pi 4 LTS with OctoPrint, Portainer, and WiFi setup via reverse proxy.

## Hardware Information

**Board**: Orange Pi 4 LTS  
**SoC**: Rockchip RK3399 (Dual Cortex-A72 + Quad Cortex-A53)  
**RAM**: 4GB LPDDR4  
**Storage**: eMMC + MicroSD support  
**Connectivity**: Gigabit Ethernet, WiFi 802.11ac, Bluetooth 5.0  

📋 **[Hardware Reference & GPIO Pinout](HARDWARE.md)** - Detailed pinout and 3D printer connection guide

## Services Available

Access all services through user-friendly domain names:

| Service | URL | Description |
|---------|-----|-------------|
| 🖨️ OctoPrint | http://octoprint.local | 3D printer management interface |
| 🐳 Portainer | http://portainer.octoprint.local | Docker container management |
| 📹 Camera | http://camera.octoprint.local | Webcam live stream |
| 📶 WiFi Setup | http://setup.octoprint.local | Network configuration |

*Legacy access: OctoPrint at device-ip:5000, Portainer at device-ip:9000*

## Quick Start

### Building the Image
```bash
# Build with Docker
./docker-build.sh

# Or build locally 
chmod +x build-script.sh
sudo ./build-script.sh
```

### Flashing
```bash
# Extract and flash image
xz -d output/octoprint-orangepi4.img.xz
sudo dd if=output/octoprint-orangepi4.img of=/dev/sdX bs=4M status=progress
```

### Initial Setup
1. **Boot the Orange Pi** and wait for startup
2. **Connect to WiFi Setup**: Access point "Octoprint-Setup" → http://10.41.0.1
3. **Configure network** and connect to your WiFi
4. **Access services** via the domain names above

### Default Login
**SSH**: `root/1234` (change on first login)

## Features

- **Pre-configured OctoPrint** with webcam support
- **Nginx reverse proxy** for clean domain routing  
- **Automatic service discovery** via Avahi/mDNS
- **Docker management** through Portainer
- **WiFi setup interface** via Comitup
- **Hardware-accelerated streaming** with uStreamer
- **USB device access** for 3D printer communication

## Directory Structure

```
📁 armbian-orangepi4-octoprint/
├── 📁 docker-configs/          # Docker services configuration
│   ├── docker-compose.yml     # Main services with reverse proxy
│   ├── nginx/                 # Reverse proxy configuration
│   └── README.md              # Detailed setup guide
├── 📁 userpatches/            # Armbian customization
│   └── overlay/               # Files copied to image
│       └── etc/avahi/services/  # mDNS service discovery
├── 📄 HARDWARE.md             # GPIO pinout & hardware guide
├── 📄 build-script.sh         # Image build automation
└── 📄 docker-build.sh         # Container build helper
```

## Configuration

### Network Setup
- **Reverse Proxy**: All services accessible through port 80
- **mDNS/Avahi**: Automatic .local domain resolution  
- **Service Discovery**: Services discoverable in network browsers
- **Comitup**: WiFi configuration at setup.octoprint.local

### Hardware Integration
- **USB Serial**: `/dev/ttyUSB0` or `/dev/ttyACM0` for 3D printer
- **Camera**: `/dev/video0` for webcam streaming via uStreamer
- **GPIO**: 40-pin header for additional hardware (see HARDWARE.md)

### Services Configuration
All services defined in `docker-configs/docker-compose.yml`:
- Nginx reverse proxy with virtual host routing
- OctoPrint with device access and WebSocket support
- Portainer for container management
- uStreamer for high-performance camera streaming
- Comitup proxy with fallback setup page

## Troubleshooting

### Common Issues
```bash
# Check service status
cd docker-configs && docker-compose ps

# View logs
docker-compose logs nginx-proxy
docker-compose logs octoprint

# Check USB devices
lsusb
ls -la /dev/tty* | grep USB

# Test DNS resolution
nslookup octoprint.local
```

### Hardware Connections
- **3D Printer**: USB connection to `/dev/ttyUSB0` or `/dev/ttyACM0`
- **Camera**: USB webcam to `/dev/video0`
- **GPIO**: See HARDWARE.md for pinout and voltage levels (3.3V logic)

## Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature-name`
3. Test changes thoroughly
4. Submit pull request with detailed description

## License

This project follows component licensing:
- Armbian: GPL v2
- OctoPrint: AGPL v3  
- Portainer: Zlib License

---

**⚠️ Security Note**: This image is designed for local network use. For internet access, implement proper security including SSL certificates and strong authentication.
