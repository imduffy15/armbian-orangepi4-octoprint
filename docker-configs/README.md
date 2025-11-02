# OctoPrint with Nginx Reverse Proxy Setup

This configuration sets up OctoPrint with Portainer and a WiFi setup interface behind an nginx reverse proxy, making all services accessible through user-friendly domain names.

## Services Available

| Service | URL | Description |
|---------|-----|-------------|
| OctoPrint | http://octoprint.local | Main 3D printer management interface |
| Portainer | http://portainer.octoprint.local | Docker container management |
| Camera Stream | http://camera.octoprint.local | Webcam live stream (uStreamer) |
| WiFi Setup | http://setup.octoprint.local | WiFi configuration interface (Comitup) |

## Features

- **Domain-based routing**: Access services using memorable local domain names
- **Avahi/mDNS service discovery**: Services are automatically discoverable on the network
- **WebSocket support**: Full support for real-time features in OctoPrint and Portainer
- **Dedicated camera stream**: High-performance uStreamer for webcam with MJPEG output
- **Large file uploads**: Configured to handle large G-code files (100MB limit)
- **Automatic service discovery**: nginx-proxy automatically configures routing based on container environment variables

## Setup Instructions

1. **Deploy the services:**
   ```bash
   cd docker-configs
   docker-compose up -d
   ```

2. **Configure local DNS (choose one method):**

   **Method A: Router Configuration (Recommended)**
   - Add these entries to your router's DNS settings or DHCP reservations:
     - `octoprint.local` → [Orange Pi IP]
     - `portainer.octoprint.local` → [Orange Pi IP]
     - `setup.octoprint.local` → [Orange Pi IP]

   **Method B: Local hosts file**
   - On your computer, edit `/etc/hosts` (Linux/Mac) or `C:\Windows\System32\drivers\etc\hosts` (Windows)
   - Add these lines (replace with your Orange Pi's IP):
     ```
     192.168.1.100 octoprint.local
     192.168.1.100 portainer.octoprint.local
     192.168.1.100 setup.octoprint.local
     ```

   **Method C: Using Avahi/mDNS (Automatic)**
   - The `.local` domains should resolve automatically on most modern networks
   - Services will be discoverable in network browsers and Bonjour-compatible applications
   - Avahi service files are included for automatic HTTP service discovery

3. **Access the services:**
   - Open your browser and navigate to any of the service URLs listed above

## Architecture

```
[Client Browser] 
       ↓
[nginx-proxy:80] 
       ↓
┌─────────────────┬─────────────────┬─────────────────┬─────────────────┐
│   octoprint     │   portainer     │   ustreamer     │   comitup       │
│   :5000         │   :9000         │   :8080         │   :80           │
└─────────────────┴─────────────────┴─────────────────┴─────────────────┘
```

## Configuration Details

### Nginx Virtual Hosts

Custom nginx configurations are stored in `nginx/vhost.d/` and include:

- **OctoPrint** (`octoprint.local`): WebSocket support for real-time updates and camera streaming
- **Portainer** (`portainer.octoprint.local`): WebSocket support for container management
- **Camera** (`camera.octoprint.local`): CORS headers and stream optimization for uStreamer
- **Setup** (`setup.octoprint.local`): Proxies to host comitup service with fallback page

### Container Environment Variables

Each service is configured with `VIRTUAL_HOST` and `VIRTUAL_PORT` environment variables that nginx-proxy uses for automatic configuration:

```yaml
environment:
  - VIRTUAL_HOST=octoprint.local
  - VIRTUAL_PORT=5000
```

## Camera Streaming with uStreamer

The setup includes a dedicated uStreamer service for high-performance webcam streaming:

- **URL**: http://camera.octoprint.local
- **Stream URL**: http://camera.octoprint.local/stream
- **Format**: MJPEG at 1280x720 resolution, 30 FPS
- **Features**: Hardware-accelerated streaming, frame dropping for smooth performance

### Camera Configuration

uStreamer is configured with optimal settings for 3D printer monitoring:
- 30 FPS with frame dropping to maintain smooth streaming
- 3 buffers and 3 workers for efficient processing
- Persistent connection handling
- CORS headers for cross-origin access from OctoPrint

## Device Access Notes

- **USB Devices**: The USB devices (`/dev/ttyUSB0`, etc.) must exist on the host
- **Camera**: `/dev/video0` is for webcam support
- **Permissions**: The container runs with `dialout` group for serial port access
- **Privileged Mode**: Required for device access

## Troubleshooting

### Services not accessible
1. Check that all containers are running: `docker-compose ps`
2. Verify nginx-proxy logs: `docker-compose logs nginx-proxy`
3. Ensure DNS resolution is working: `nslookup octoprint.local`

### OctoPrint WebSocket errors
- Check that the nginx configuration includes WebSocket headers
- Verify the `/sockjs/` location block in `nginx/vhost.d/octoprint.local`

### Large file upload failures
- The configuration supports up to 100MB uploads
- For larger files, increase `client_max_body_size` in the virtual host configs

### Device Access Issues

1. **No USB device found**: 
   - Check if printer is connected: `lsusb`
   - Device name might be different (e.g., `/dev/ttyACM0`)

2. **Permission denied**: 
   - Ensure user is in `dialout` group
   - Container uses privileged mode for device access

3. **Camera not working**: 
   - Check available cameras: `v4l2-ctl --list-devices`
   - Update device path in docker-compose.yml

## Security Considerations

- This setup is designed for local network use
- For internet access, consider adding SSL/TLS certificates
- Change default passwords for all services
- Consider firewall rules to restrict access

## Avahi Service Discovery

Avahi service files are included to make HTTP services automatically discoverable on the network:

- Services appear in network browsers (like macOS Finder's Network section)
- Compatible with Bonjour/Zeroconf browsers
- Each service includes descriptive text and proper service types
- Services are advertised as `_http._tcp` for web browser compatibility

### Service Files Location
Service discovery files are stored in: `userpatches/overlay/etc/avahi/services/`

## Integration with Comitup

The setup includes a proxy to the host comitup service for WiFi configuration. When comitup is running on the host system (port 80), it will be accessible through `setup.octoprint.local`. If comitup is not available, a fallback page with service links is displayed.

To ensure comitup integration works:
1. Install comitup on the host system
2. Configure it to run on port 80
3. The docker container will automatically proxy requests to the host service

## Legacy Setup (Portainer Only)

For the previous Portainer-only setup, see `octoprint-stack.yml` for deploying OctoPrint as a separate stack through Portainer.