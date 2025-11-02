# Custom Armbian Image for Orange Pi 4 LTS - Octoprint Edition

This project creates a customized Armbian image for the Orange Pi 4 LTS that includes:

- **Docker** and **Portainer** for container management
- **Octoprint** running as a Docker container with full USB, GPIO, I2C, SPI access
- **Comitup** for easy WiFi configuration via access point

## Features

### Automated Setup
- Docker and Portainer pre-installed
- Octoprint container auto-deployed on first boot with comprehensive device access
- WiFi configuration via captive portal (comitup)
- Avahi/mDNS for easy network discovery

### Container Stack
- **Portainer**: Web-based Docker management interface (Port 9000)
- **Octoprint**: 3D printer management interface (Port 5000)

### Hardware Access
- **USB Serial**: All USB devices (ttyUSB*, ttyACM*) for printer connectivity
- **GPIO**: Full GPIO access via /dev/gpiomem and gpiochip
- **I2C/SPI**: Support for displays, sensors, and custom hardware
- **Video**: Webcam support for print monitoring
- See [Device Access Documentation](docs/DEVICE_ACCESS.md) for details

## Quick Start - Download Pre-Built Image

**Don't want to build? Download ready-to-flash images from [Releases](../../releases)!**

1. Download the latest `OctoprintOS-OrangePi4LTS-*.img.xz` from [Releases](../../releases)
2. Verify with the `.sha256` checksum file
3. Flash to SD card using [Etcher](https://www.balena.io/etcher/) or:
   ```bash
   xz -d OctoprintOS-OrangePi4LTS-*.img.xz
   sudo dd if=OctoprintOS-*.img of=/dev/sdX bs=4M status=progress
   ```
4. Boot and configure WiFi (see [First Boot Setup](#first-boot-setup) below)

For eMMC installation, see [eMMC Installation Guide](docs/EMMC_INSTALL.md)

## Building the Image Yourself

### Prerequisites

- Linux system (Ubuntu 20.04+ or Debian 11+ recommended)
- At least 20GB of free disk space
- 8GB+ RAM recommended
- Git installed
- sudo/root access

### Local Build

1. Clone this repository:
```bash
git clone <your-repo-url>
cd armbian-orangepi4-octoprint
```

2. Make the build script executable:
```bash
chmod +x build.sh
```

3. Run the build script:
```bash
./build.sh
```

The script will:
- Clone the Armbian build system (if not already present)
- Copy custom configurations
- Build the image (this takes 1-2 hours)

### Manual Build

If you prefer to build manually:

1. Clone Armbian build system:
```bash
git clone --depth 1 https://github.com/armbian/build ~/armbian-build
```

2. Copy userpatches:
```bash
cp -r userpatches/* ~/armbian-build/userpatches/
```

3. Run the build:
```bash
cd ~/armbian-build
./compile.sh BOARD=orangepi4-lts BRANCH=current RELEASE=bookworm
```

### Automated Builds with GitHub Actions

This repository includes GitHub Actions workflow for automated image building and releases.

**Creating a Release:**

1. Tag a version:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. GitHub Actions will automatically:
   - Build the Armbian image
   - Compress it with xz
   - Generate SHA256 checksums
   - Create a GitHub Release
   - Upload the image as `OctoprintOS-OrangePi4LTS-v1.0.0.img.xz`

**Manual Workflow Trigger:**

You can also trigger a build manually:
1. Go to Actions tab in GitHub
2. Select "Build and Release Armbian Image"
3. Click "Run workflow"
4. Choose branch and release type
5. Image will be available as workflow artifact

The build takes approximately 2-4 hours in GitHub Actions.

**Workflow Features:**
- Automated disk space cleanup for CI
- Parallel compression with xz
- Automatic checksum generation
- Release notes with quick start guide
- Artifact retention for 30 days

See `.github/workflows/build-release.yml` for configuration details.

## Flashing the Image

1. Find the built image in `~/armbian-build/output/images/`

2. Flash to SD card (Linux):
```bash
sudo dd if=Armbian_*.img of=/dev/sdX bs=4M status=progress
sync
```

Or use [Etcher](https://www.balena.io/etcher/) (cross-platform GUI tool)

## First Boot Setup

### 1. Initial Boot
- Insert the SD card into your Orange Pi 4 LTS
- Connect power and wait for boot (LED will indicate activity)
- First boot takes 2-3 minutes as it expands the filesystem

### 2. WiFi Configuration with Comitup

When the device has no WiFi configured, it will create an access point:

- **SSID**: `Octoprint-Setup-XXXX` (XXXX = last 4 chars of MAC)
- **Password**: `octoprint`

**To configure WiFi:**

1. Connect to the `Octoprint-Setup` WiFi network
2. Open a browser and go to `http://10.41.0.1`
3. Select your WiFi network from the list
4. Enter your WiFi password
5. Click "Connect"
6. The device will reboot and connect to your WiFi

### 3. Finding Your Device

After WiFi is configured, find your device IP:

**Option 1: mDNS (if supported on your network)**
```
http://orangepi4-lts.local
```

**Option 2: Check your router's DHCP leases**

**Option 3: Network scan**
```bash
nmap -sn 192.168.1.0/24
```

### 4. Accessing Services

Once connected to your network:

- **Portainer**: `http://<device-ip>:9000`
  - First-time setup: Create admin account
  - Select "Local" environment

- **Octoprint**: `http://<device-ip>:5000`
  - Follow the setup wizard
  - Configure your 3D printer connection

## Container Management

### Using Portainer

Access Portainer at `http://<device-ip>:9000` to:
- View container logs
- Restart containers
- Update container images
- Manage volumes
- Deploy additional containers

### Manual Docker Commands

SSH into the device (default credentials: `root/1234`, you'll be prompted to change on first login):

```bash
# View running containers
docker ps

# View Octoprint logs
docker logs octoprint

# Restart Octoprint
docker restart octoprint

# Access Octoprint container shell
docker exec -it octoprint bash
```

### Using Docker Compose (Alternative)

A `docker-compose.yml` file is provided in `/opt/docker-configs/`:

```bash
cd /opt/docker-configs
docker-compose up -d
```

## Configuration

### Octoprint

- **Data directory**: `/opt/octoprint/data`
- **Serial port**: `/dev/ttyUSB0` (adjust if your printer uses a different port)
- **Webcam**: `/dev/video0` (optional)

To change the serial port, edit and restart the container:
```bash
docker stop octoprint
docker rm octoprint
# Edit /usr/local/bin/setup-octoprint.sh
# Change --device=/dev/ttyUSB0 to your port
/usr/local/bin/setup-octoprint.sh
```

### Comitup

Configuration file: `/etc/comitup/comitup.conf`

To change the access point name or password:
```bash
nano /etc/comitup/comitup.conf
systemctl restart comitup
```

## Customization

### Project Structure

```
armbian-orangepi4-octoprint/
├── build.sh                          # Build script
├── README.md                         # This file
├── userpatches/
│   ├── customize-image.sh            # Image customization script
│   ├── config-default.conf           # Armbian build config
│   └── overlay/                      # Files copied to image
│       ├── etc/
│       │   ├── comitup/
│       │   │   └── comitup.conf      # Comitup configuration
│       │   └── systemd/system/
│       │       └── setup-containers.service
│       └── usr/local/bin/
│           ├── setup-portainer.sh    # Portainer deployment
│           └── setup-octoprint.sh    # Octoprint deployment
├── docker-configs/
│   └── docker-compose.yml            # Alternative deployment method
└── scripts/
    └── install-comitup.sh            # Comitup installation script
```

### Adding More Containers

Edit `/usr/local/bin/setup-containers.sh` or use Portainer to deploy additional containers.

### Modifying the Build

Edit files in `userpatches/` then rebuild:
```bash
./build.sh
```

## Troubleshooting

### WiFi Access Point Not Appearing

1. Check if comitup service is running:
```bash
systemctl status comitup
```

2. Restart comitup:
```bash
systemctl restart comitup
```

### Containers Not Starting

1. Check Docker service:
```bash
systemctl status docker
```

2. View setup logs:
```bash
journalctl -u setup-containers.service
```

3. Check container status:
```bash
docker ps -a
```

### Octoprint Can't Find Printer

1. Verify USB device:
```bash
ls -l /dev/ttyUSB* /dev/ttyACM*
```

2. Check device permissions:
```bash
ls -l /dev/ttyUSB0
```

3. Update container device mapping if needed

### Can't Access Services

1. Check if containers are running:
```bash
docker ps
```

2. Verify firewall settings:
```bash
iptables -L
```

3. Check network connectivity:
```bash
ip addr show
ping 8.8.8.8
```

## Security Recommendations

1. **Change default passwords** immediately after first boot
2. **Update the system** regularly:
```bash
apt update && apt upgrade
```

3. **Enable firewall** if exposing to internet:
```bash
apt install ufw
ufw allow 22/tcp
ufw allow 5000/tcp
ufw allow 9000/tcp
ufw enable
```

4. **Use HTTPS** for Portainer (configure in Portainer settings)

5. **Disable comitup** after initial WiFi setup (optional):
```bash
systemctl disable comitup
systemctl disable comitup-web
```

## Support and Resources

- [Armbian Documentation](https://docs.armbian.com/)
- [Octoprint Documentation](https://docs.octoprint.org/)
- [Portainer Documentation](https://docs.portainer.io/)
- [Comitup Documentation](https://github.com/davesteele/comitup)

## License

This project is provided as-is for educational and personal use.

## Contributing

Feel free to submit issues and enhancement requests!
