# Device Access in Octoprint Container

This document explains the comprehensive device access configured for the Octoprint container, allowing you to use USB devices, GPIO pins, I2C, SPI, and more.

## Devices Available to Octoprint

The Octoprint container has been configured with access to the following devices:

### USB Serial Devices (3D Printer Communication)

**Devices:**
- `/dev/ttyUSB0`, `/dev/ttyUSB1`, etc. - USB-to-Serial adapters
- `/dev/ttyACM0`, `/dev/ttyACM1`, etc. - USB CDC ACM devices (Arduino-like boards)
- `/dev/ttyAMA0`, etc. - UART serial ports

**Use Cases:**
- 3D printer control via USB
- Serial communication with printer mainboard
- Connection to Marlin, Klipper, or other firmware

**Configuration:**
In Octoprint Settings → Serial Connection:
1. Set Serial Port to "AUTO" or select specific device (e.g., `/dev/ttyUSB0`)
2. Set Baudrate to match your printer (usually 115200 or 250000)
3. Click "Connect"

### Video Devices (Webcams)

**Devices:**
- `/dev/video0`, `/dev/video1`, etc. - USB webcams or CSI cameras

**Use Cases:**
- 3D print monitoring
- Timelapse video creation
- Remote viewing during prints

**Configuration:**
The MJPG-Streamer is automatically enabled. To verify webcam:

```bash
# Check if webcam is detected
docker exec octoprint ls -l /dev/video*

# View webcam stream
http://<device-ip>:5000/?action=stream
```

If you have multiple cameras, edit the environment variable:
```bash
docker stop octoprint
docker rm octoprint
# Edit CAMERA_DEV in docker-compose.yml or setup script
docker-compose up -d octoprint
```

### GPIO (General Purpose Input/Output)

**Devices:**
- `/dev/gpiomem` - Memory-mapped GPIO access (safer, non-root)
- `/dev/gpiochip0`, `/dev/gpiochip1` - Character device GPIO interface

**Use Cases:**
- Control LEDs (status lights, enclosure lighting)
- Read buttons or switches
- Control relays (power management, printer power)
- PSU control plugin
- Enclosure plugin for temperature/humidity sensors

**Orange Pi 4 LTS GPIO Pinout:**
The Orange Pi 4 LTS has 40-pin GPIO header compatible with Raspberry Pi.

**Example - Control GPIO with Octoprint:**

1. Install GPIO plugin in Octoprint:
   - Settings → Plugin Manager → Get More
   - Search for "GPIO Control" or "Enclosure Plugin"

2. Use Python in Octoprint scripts:
   ```python
   # Using gpiod library (recommended)
   import gpiod

   chip = gpiod.Chip('gpiochip0')
   line = chip.get_line(17)  # GPIO 17
   line.request(consumer="octoprint", type=gpiod.LINE_REQ_DIR_OUT)
   line.set_value(1)  # Turn on
   ```

3. Or use sysfs (legacy method):
   ```bash
   # Export GPIO
   echo 17 > /sys/class/gpio/export
   echo out > /sys/class/gpio/gpio17/direction
   echo 1 > /sys/class/gpio/gpio17/value  # Turn on
   ```

**Common GPIO Use Cases:**
- **PSU Control**: Auto power on/off printer PSU
- **LED Strips**: Status indication or enclosure lighting
- **Relays**: Control external devices
- **Buttons**: Emergency stop, pause/resume

### I2C Devices (Displays, Sensors)

**Devices:**
- `/dev/i2c-0`, `/dev/i2c-1`, `/dev/i2c-2` - I2C buses

**Use Cases:**
- OLED/LCD displays (SSD1306, ST7789, etc.)
- Temperature sensors (BME280, DHT22 via I2C)
- Light sensors
- ADC converters

**Example - I2C OLED Display:**

1. Install Python I2C libraries in Octoprint:
   ```bash
   docker exec -it octoprint bash
   pip install smbus2 Pillow
   ```

2. Use with Octoprint Display plugin:
   - Install "OctoPrint-Display" plugin
   - Configure for I2C display

3. Manual I2C access:
   ```python
   from smbus2 import SMBus

   bus = SMBus(1)  # I2C bus 1
   address = 0x3C  # Common OLED address

   # Write to device
   bus.write_byte_data(address, 0x00, 0xFF)
   ```

**Check I2C devices:**
```bash
# Install i2c-tools
apt-get install i2c-tools

# Scan I2C bus
i2cdetect -y 1
```

### SPI Devices

**Devices:**
- `/dev/spidev0.0`, `/dev/spidev0.1` - SPI interfaces

**Use Cases:**
- TFT displays
- SD card readers
- High-speed sensors
- Custom hardware interfaces

**Example - SPI Display:**
```python
import spidev

spi = spidev.SpiDev()
spi.open(0, 0)  # Bus 0, Device 0
spi.max_speed_hz = 1000000

# Transfer data
spi.xfer([0x01, 0x02, 0x03])
```

## Device Permissions

The Octoprint container runs with the following groups for device access:

- `dialout` - Serial port access
- `video` - Video device access
- `gpio` - GPIO access
- `i2c` - I2C device access
- `spi` - SPI device access

And the following capabilities:

- `SYS_RAWIO` - Raw I/O operations for GPIO/I2C/SPI
- `NET_ADMIN` - Network administration (for VPN plugins, etc.)

## Troubleshooting Device Access

### Serial Device Not Found

1. Check if device exists on host:
   ```bash
   ls -l /dev/ttyUSB* /dev/ttyACM*
   ```

2. Check device in container:
   ```bash
   docker exec octoprint ls -l /dev/ttyUSB* /dev/ttyACM*
   ```

3. If device appears after container starts, restart container:
   ```bash
   docker restart octoprint
   ```

4. Check permissions:
   ```bash
   # On host
   ls -l /dev/ttyUSB0
   # Should show: crw-rw---- 1 root dialout
   ```

### GPIO Access Denied

1. Check if gpiomem is accessible:
   ```bash
   docker exec octoprint ls -l /dev/gpiomem
   ```

2. Install required libraries:
   ```bash
   docker exec octoprint pip install gpiod RPi.GPIO
   ```

3. For some operations, you may need privileged mode:
   ```yaml
   # In docker-compose.yml
   privileged: true
   ```

### I2C/SPI Not Working

1. Enable I2C/SPI on Orange Pi:
   ```bash
   # Edit /boot/armbianEnv.txt
   nano /boot/armbianEnv.txt

   # Add or uncomment:
   overlays=i2c0 i2c1 spi-spidev
   ```

2. Reboot:
   ```bash
   reboot
   ```

3. Verify devices exist:
   ```bash
   ls -l /dev/i2c-* /dev/spidev*
   ```

4. Check container access:
   ```bash
   docker exec octoprint ls -l /dev/i2c-* /dev/spidev*
   ```

### Webcam Not Streaming

1. Check video device:
   ```bash
   ls -l /dev/video*
   v4l2-ctl --list-devices
   ```

2. Test webcam on host:
   ```bash
   apt-get install v4l-utils
   v4l2-ctl --device=/dev/video0 --all
   ```

3. Check MJPG-Streamer logs:
   ```bash
   docker logs octoprint | grep mjpg
   ```

4. Manually test in container:
   ```bash
   docker exec -it octoprint bash
   /scripts/webcam.sh
   ```

## Useful Octoprint Plugins for Hardware

### GPIO & Hardware Control

- **PSU Control** - Auto power on/off for printer PSU
- **Enclosure Plugin** - Temperature, humidity, GPIO control
- **GPIO Control** - Simple GPIO on/off control
- **Tasmota Plugin** - Control Tasmota smart switches

### Display Plugins

- **OctoPrint-Display** - OLED/LCD display support
- **TouchUI** - Touch-friendly interface for displays

### Camera/Streaming

- **Octolapse** - Advanced timelapse with stabilization
- **Multi-Cam** - Multiple camera support
- **The Spaghetti Detective** - AI-powered print monitoring

## Hardware Project Examples

### Example 1: PSU Control with Relay

Control printer power supply via GPIO-connected relay:

1. Connect relay to GPIO 17 (pin 11)
2. Install PSU Control plugin
3. Configure in Octoprint:
   - GPIO Pin: 17
   - Switching: Active High
   - Auto On: Before print
   - Auto Off: After completion

### Example 2: Status LED Strip

RGB LED strip for print status:

1. Connect WS2812B LED strip to GPIO 18 (PWM pin)
2. Install Enclosure Plugin
3. Configure LED output
4. Set events:
   - Printing: Blue
   - Complete: Green
   - Error: Red

### Example 3: Temperature Display

OLED display showing printer stats:

1. Connect SSD1306 OLED to I2C-1
2. Install OctoPrint-Display plugin
3. Configure I2C address (usually 0x3C)
4. Display shows:
   - Print progress
   - Temperatures
   - ETA

### Example 4: Emergency Stop Button

Physical button for emergency stop:

1. Connect button to GPIO 27 (pull-up)
2. Create Octoprint event script
3. On button press: Issue M112 (emergency stop)

## Security Considerations

### Device Access Security

The container has extensive device access, which is necessary for hardware control but comes with security implications:

**Risks:**
- Container can access all USB devices
- GPIO access could control connected hardware
- Potential for hardware damage if misconfigured

**Mitigations:**
1. Run Octoprint behind firewall
2. Use strong passwords
3. Enable HTTPS (via Portainer or reverse proxy)
4. Regularly update container image
5. Monitor access logs

### Restricting Device Access

If you don't need all devices, you can restrict access by editing the container configuration:

**Remove unnecessary devices in docker-compose.yml:**
```yaml
# Comment out devices you don't need
devices:
  - /dev/ttyUSB0:/dev/ttyUSB0  # Keep: printer
  # - /dev/i2c-1:/dev/i2c-1    # Remove: not using I2C
```

**Or modify setup-octoprint.sh** to skip certain device types.

## Additional Resources

- [Octoprint Plugin Repository](https://plugins.octoprint.org/)
- [Armbian Documentation](https://docs.armbian.com/)
- [Orange Pi GPIO Guide](http://www.orangepi.org/html/hardWare/computerAndMicrocontrollers/service-and-support/Orange-Pi-4-LTS.html)
- [gpiod Documentation](https://git.kernel.org/pub/scm/libs/libgpiod/libgpiod.git/about/)
- [Linux I2C Documentation](https://www.kernel.org/doc/Documentation/i2c/)

## Getting Help

If you encounter issues with device access:

1. Check device exists on host system
2. Verify device exists in container
3. Check permissions and group membership
4. Review container logs: `docker logs octoprint`
5. Test device functionality on host first
6. File an issue with:
   - Output of `lsblk`, `ls -l /dev/`
   - Container logs
   - docker-compose.yml configuration
