# OctoPrint Management via Portainer

This setup provides Portainer for web-based Docker container management, with OctoPrint deployed as a separate stack.

## Initial Setup

1. **Access Portainer**: After the image boots, visit `http://[device-ip]:9000` to access Portainer
2. **First-time setup**: Create an admin account when prompted
3. **Select Local environment**: Choose "Docker" and "Connect" to manage the local Docker instance

## Deploying OctoPrint

### Method 1: Using Stacks (Recommended)

1. In Portainer, go to **Stacks** → **Add Stack**
2. Name your stack: `octoprint`
3. Copy the contents of `octoprint-stack.yml` into the web editor
4. Click **Deploy the stack**

### Method 2: Using Containers

1. In Portainer, go to **Containers** → **Add Container**
2. Configure manually:
   - **Name**: `octoprint`
   - **Image**: `octoprint/octoprint:latest`
   - **Ports**: Map `5000:5000`
   - **Volumes**: Create volume `octoprint_data` mounted to `/octoprint`
   - **Devices**: Add `/dev/ttyUSB0:/dev/ttyUSB0` and `/dev/video0:/dev/video0`
   - **Advanced**: Add group `dialout`

## Device Access Notes

- **USB Devices**: The USB devices (`/dev/ttyUSB0`, etc.) must exist on the host
- **Camera**: `/dev/video0` is for webcam support
- **Permissions**: The container runs with `dialout` group for serial port access
- **Privileged Mode**: May be required if device access fails

## Accessing Services

- **Portainer**: `http://[device-ip]:9000`
- **OctoPrint**: `http://[device-ip]:5000` (after deployment)

## Useful Commands

Check connected USB devices:
```bash
ls -la /dev/tty* | grep USB
```

Check video devices:
```bash
ls -la /dev/video*
```

View container logs in Portainer or via CLI:
```bash
docker logs octoprint
```

## Troubleshooting

1. **No USB device found**: 
   - Check if printer is connected: `lsusb`
   - Device name might be different (e.g., `/dev/ttyACM0`)

2. **Permission denied**: 
   - Ensure user is in `dialout` group
   - Consider using privileged mode

3. **Camera not working**: 
   - Check available cameras: `v4l2-ctl --list-devices`
   - Update device path in stack configuration