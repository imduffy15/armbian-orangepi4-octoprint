# Prusa MK3S Setup Guide

This guide covers the specific setup for your hardware configuration:
- **Printer**: Prusa MK3S
- **Webcam**: Logitech C920
- **Relay**: GPIO-controlled relay for lights

## Your Specific Configuration

This setup is customized for your Prusa MK3S with:
- **E3D Revo Hotend** (upgraded from stock V6)
- **Revo Firmware** (modified for Revo hotend)
- **Nylon Lock Mod** (nylock nuts instead of springs)

### Important Notes

**Revo Hotend:**
- Max temperature: 300°C (vs 285°C stock)
- Faster heating and better temperature stability
- Quick-change nozzles (no tools required)
- Compatible with Revo firmware

**Nylon Lock Mod:**
- More stable bed leveling (no spring compression)
- Requires careful initial setup
- Less frequent mesh bed leveling needed
- **Z-alignment is critical** - see troubleshooting section

## Hardware Connections

### Prusa MK3S Connection

The Prusa MK3S with Revo firmware connects via USB and appears as a serial device.

**Expected Device:**
- `/dev/ttyACM0` (most common for Prusa MK3S)
- Sometimes `/dev/ttyUSB0` if using USB-to-serial adapter

**To verify connection:**
```bash
# After connecting the printer
dmesg | tail -20
# Look for lines like: "cdc_acm 1-1.2:1.0: ttyACM0: USB ACM device"

# Or list serial devices
ls -l /dev/ttyACM* /dev/ttyUSB*
```

### Logitech C920 Webcam

The C920 is a high-quality webcam with excellent Linux support.

**Expected Device:**
- `/dev/video0` (primary camera)
- May also create `/dev/video1` for metadata

**To verify connection:**
```bash
# List video devices
ls -l /dev/video*

# Get camera details
v4l2-ctl --list-devices

# Check supported resolutions
v4l2-ctl --device=/dev/video0 --list-formats-ext
```

**Recommended Settings for C920:**
- Resolution: 1280x720 (720p) or 1920x1080 (1080p)
- Framerate: 15-30 FPS for streaming
- Format: MJPEG or H.264

### GPIO Relay for Lights

Connect a relay module to control your lights.

**Recommended GPIO Pins:**
- **GPIO 17** (Physical Pin 11) - Relay control signal
- **GND** (Physical Pin 6, 9, 14, 20, 25, 30, 34, or 39) - Ground
- **5V** (Physical Pin 2 or 4) - Relay power (if needed)

**Orange Pi 4 LTS 40-Pin Header:**
```
     3.3V  (1) (2)  5V
    GPIO2  (3) (4)  5V
    GPIO3  (5) (6)  GND
    GPIO4  (7) (8)  GPIO14
      GND  (9) (10) GPIO15
   GPIO17 (11) (12) GPIO18
   GPIO27 (13) (14) GND
   GPIO22 (15) (16) GPIO23
     3.3V (17) (18) GPIO24
   GPIO10 (19) (20) GND
    GPIO9 (21) (22) GPIO25
   GPIO11 (23) (24) GPIO8
      GND (25) (26) GPIO7
```

**Wiring:**
1. Relay VCC → Orange Pi 5V (Pin 2)
2. Relay GND → Orange Pi GND (Pin 6)
3. Relay IN/Signal → Orange Pi GPIO17 (Pin 11)
4. Connect your lights to the relay's output terminals (COM/NO/NC)

## Octoprint Configuration

### Step 1: First Boot and Access

1. Boot the Orange Pi with the flashed image
2. Connect to `Octoprint-Setup` WiFi (password: `octoprint`)
3. Configure your WiFi at http://10.41.0.1
4. After reboot, access Octoprint at http://device-ip:5000

### Step 2: Initial Octoprint Setup

When you first access Octoprint, you'll see the setup wizard:

1. **Create Account:**
   - Username: (your choice)
   - Password: (strong password)

2. **Connectivity Check:** Enable or skip

3. **Anonymous Usage Tracking:** Your choice

4. **Online Connectivity:** Enable for plugin installation

5. **Plugin Blacklist:** Enable (recommended)

### Step 3: Printer Setup (Prusa MK3S)

1. **Printer Profile:**
   - Name: `Prusa MK3S`
   - Model: `Prusa i3 MK3S`
   - Form Factor: `Rectangular`
   - Build Volume:
     - Width (X): 250 mm
     - Depth (Y): 210 mm
     - Height (Z): 210 mm
   - Print bed:
     - Width: 250 mm
     - Depth: 210 mm
   - Axes:
     - X: 200 mm/min
     - Y: 200 mm/min
     - Z: 100 mm/min
   - E: 300 mm/min
   - Heated bed: ✓ Yes
   - Heated chamber: ✗ No

2. **Serial Connection:**
   - Settings → Serial Connection
   - Serial Port: `/dev/ttyACM0` or `AUTO`
   - Baudrate: `115200`
   - Click "Save"
   - Click "Connect"

3. **Temperature Tab:**
   - You should see temperature graphs appear
   - Tool (nozzle): ~20°C (room temp when cold)
   - Bed: ~20°C (room temp when cold)

### Step 4: Webcam Configuration (Logitech C920)

The webcam should work automatically, but you can optimize settings:

1. **Test Webcam Stream:**
   - Navigate to: http://device-ip:5000/?action=stream
   - You should see the camera feed

2. **Optimize Settings:**
   - Settings → Webcam & Timelapse
   - Stream URL: `/webcam/?action=stream`
   - Snapshot URL: `/webcam/?action=snapshot`
   - Flip horizontally: ✗ (adjust if needed)
   - Flip vertically: ✗ (adjust if needed)
   - Rotate 90°: ✗ (adjust if needed)

3. **Advanced C920 Settings (Optional):**

   Access the container to fine-tune:
   ```bash
   docker exec -it octoprint bash

   # Install v4l2-ctl
   apt-get update && apt-get install -y v4l-utils

   # Set resolution to 720p @ 30fps
   v4l2-ctl --device=/dev/video0 --set-fmt-video=width=1280,height=720,pixelformat=MJPG

   # Adjust camera settings
   v4l2-ctl --device=/dev/video0 --set-ctrl=focus_auto=0
   v4l2-ctl --device=/dev/video0 --set-ctrl=focus_absolute=25
   v4l2-ctl --device=/dev/video0 --set-ctrl=exposure_auto=1
   v4l2-ctl --device=/dev/video0 --set-ctrl=brightness=128
   v4l2-ctl --device=/dev/video0 --set-ctrl=contrast=128
   ```

### Step 5: Relay Control for Lights

Install and configure the PSU Control or Enclosure plugin to control your lights.

**Option A: PSU Control Plugin (Simple On/Off)**

1. **Install Plugin:**
   - Settings → Plugin Manager → Get More
   - Search: `PSU Control`
   - Click "Install"
   - Restart Octoprint

2. **Configure PSU Control:**
   - Settings → PSU Control
   - Switching Method: `GPIO`
   - On/Off GPIO Pin: `17`
   - Switching: `Active High` (relay activates on HIGH signal)
   - Auto On: ✓ Before print job starts
   - Auto Off: ✓ After print completes
   - Off Delay: 5 minutes (customize as needed)

3. **Test:**
   - In Octoprint interface, you'll see a power button
   - Click to toggle lights on/off
   - Should hear relay click

**Option B: Enclosure Plugin (Advanced Control)**

For more features (scheduling, sensors, multiple outputs):

1. **Install Plugin:**
   - Settings → Plugin Manager → Get More
   - Search: `Enclosure`
   - Install and restart

2. **Configure Output:**
   - Settings → Enclosure Plugin
   - Add Output:
     - Label: `Lights`
     - Type: `Regular GPIO`
     - GPIO Number: `17`
     - Active High: ✓ Yes
     - Default State: Off

3. **Configure Actions:**
   - Print Started: Turn lights ON
   - Print Done: Turn lights OFF (with delay)
   - Manual control via UI

**Relay Wiring Verification:**

```bash
# Access the container
docker exec -it octoprint bash

# Export GPIO 17
echo 17 > /sys/class/gpio/export
echo out > /sys/class/gpio/gpio17/direction

# Test ON
echo 1 > /sys/class/gpio/gpio17/value
# Lights should turn ON, relay clicks

# Test OFF
echo 0 > /sys/class/gpio/gpio17/value
# Lights should turn OFF, relay clicks

# Cleanup
echo 17 > /sys/class/gpio/unexport
```

## Recommended Plugins for Your Setup

### Essential Plugins

1. **DisplayLayerProgress**
   - Shows layer progress, time estimates
   - Great for monitoring prints

2. **Octolapse**
   - Creates stabilized timelapses
   - Perfect for the C920's capabilities

3. **Bed Level Visualizer**
   - Visualize mesh bed leveling data
   - Useful for MK3S mesh bed leveling

4. **Prusa Slicer Thumbnails**
   - Shows preview thumbnails from PrusaSlicer

5. **The Spaghetti Detective**
   - AI-powered failure detection
   - Uses your C920 webcam

### Prusa-Specific Plugins

1. **Prusa Mesh Map**
   - Visualizes bed mesh from MK3S

2. **Prusa MMU Specific**
   - If you have MMU2S addon

## Slicer Configuration

### PrusaSlicer

1. **Add Octoprint Printer:**
   - Configuration → Printer Settings
   - Add physical printer
   - Name: `Prusa MK3S (Octoprint)`

2. **Configure Upload:**
   - Printer Settings → General
   - Host Type: `OctoPrint`
   - Hostname or IP: `http://device-ip:5000`
   - API Key:
     - Get from Octoprint: Settings → Application Keys → Generate
   - Upload path: `/`

3. **Test Upload:**
   - Slice a model
   - Click "Send to printer" (cloud icon)
   - Should upload to Octoprint

### Optimal Profiles for MK3S

Use the built-in Prusa MK3S profiles in PrusaSlicer:
- **Quality**: 0.15mm QUALITY
- **Speed**: 0.20mm SPEED
- **Draft**: 0.30mm DRAFT

### Revo Hotend Specific Settings

**Temperature Adjustments:**
- The Revo hotend may require slightly different temperatures
- Start with standard profiles and adjust ±5°C if needed
- Typical PLA: 210-220°C (vs 215°C stock)
- Typical PETG: 235-245°C
- Can go up to 300°C for high-temp materials

**First Layer Settings:**
- With nylon lock mod, bed is very stable
- First layer height: 0.20mm (standard)
- First layer width: 0.42mm (standard)
- First layer speed: 20-30 mm/s

**Retraction Settings:**
- Revo has slightly different retraction characteristics
- Start with: 0.8mm @ 35mm/s
- Tune based on stringing tests

## Workflow Example

Here's a typical printing workflow:

1. **Prepare Print:**
   - Slice in PrusaSlicer
   - Upload directly to Octoprint
   - Or upload .gcode file via web interface

2. **Pre-Print:**
   - Lights turn ON automatically (if configured)
   - Webcam shows print bed
   - Heat bed/nozzle from Octoprint or via gcode

3. **During Print:**
   - Monitor via webcam stream
   - Check progress in Octoprint
   - Receive notifications (if configured)

4. **Post-Print:**
   - Print completes
   - Lights turn OFF after delay
   - Bed/nozzle cooldown
   - Timelapse rendered

## Troubleshooting

### Printer Not Connecting

**Issue:** Octoprint can't find `/dev/ttyACM0`

**Solutions:**
1. Check USB connection
2. Verify device exists:
   ```bash
   ls -l /dev/ttyACM* /dev/ttyUSB*
   ```
3. Check container has access:
   ```bash
   docker exec octoprint ls -l /dev/ttyACM*
   ```
4. Restart container:
   ```bash
   docker restart octoprint
   ```

### Webcam Not Showing

**Issue:** Black screen or "Webcam stream not loaded"

**Solutions:**
1. Verify camera detected:
   ```bash
   ls -l /dev/video*
   ```
2. Check MJPG-Streamer logs:
   ```bash
   docker logs octoprint | grep mjpg
   ```
3. Test camera on host:
   ```bash
   apt-get install fswebcam
   fswebcam -d /dev/video0 test.jpg
   ```
4. Restart container:
   ```bash
   docker restart octoprint
   ```

### Relay Not Working

**Issue:** Lights don't turn on/off

**Solutions:**
1. Check GPIO is accessible:
   ```bash
   docker exec octoprint ls -l /dev/gpiomem
   ```
2. Test GPIO manually (see "Relay Wiring Verification" above)
3. Verify relay wiring:
   - VCC → 5V
   - GND → GND
   - Signal → GPIO17
4. Check relay type:
   - Active HIGH: Relay activates on 3.3V/5V signal
   - Active LOW: Relay activates on GND signal
   - Adjust "Active High" setting in plugin accordingly

### Print Quality Issues

**MK3S-specific tips:**
1. Run mesh bed leveling: `G80` in terminal
2. Check belt tension
3. Verify Live-Z calibration
4. Update firmware if needed

### Z-Alignment Issues (Nylon Lock Mod Specific)

**Common Issue:** With the nylon lock mod, Z-alignment is more critical because there's no spring compression to compensate for misalignment.

**Symptoms:**
- First layer inconsistent across bed
- One side too high/low
- Mesh shows significant tilt (>0.3mm difference corner to corner)
- X-axis not parallel to bed

**Diagnosis:**

1. **Check mesh bed leveling data:**
   ```gcode
   G80  ; Run mesh bed leveling
   G81  ; Display mesh data
   ```
   - Look for tilt patterns in the mesh
   - Ideal: <0.1mm variation across bed
   - Acceptable: <0.3mm
   - Problem: >0.3mm (indicates Z-axis misalignment)

2. **Visual inspection:**
   - Home all axes: `G28`
   - Move Z to 100mm: `G1 Z100`
   - Look at X-axis from front - should be parallel to bed
   - Both Z lead screws should be at same height

**Solutions:**

1. **Manual Z-axis alignment:**
   ```gcode
   M84  ; Disable steppers
   ```
   - Manually raise X-axis to top
   - Ensure both sides reach top evenly
   - Both Z rods should be fully extended
   - Gently push down to ensure coupling engagement
   - Power cycle printer

2. **Z-axis calibration procedure:**
   - Home all axes: `G28`
   - Disable steppers: `M84`
   - Manually turn both Z lead screws until X-axis is level
   - Use a caliper or ruler to measure distance from bed to X-axis on both sides
   - Should be equal within 0.5mm
   - Re-home and test

3. **Check Z-axis components:**
   - **Lead screw alignment:** Should be vertical, not bent
   - **Linear bearings:** Should move smoothly without binding
   - **Z motor couplers:** Should be tight and aligned
   - **Frame square:** Check with carpenter's square

4. **Nylock nut adjustment:**
   - If one corner consistently high/low
   - Disable steppers: `M84`
   - Adjust the specific nylock nut:
     - Tighten: Lowers that corner
     - Loosen: Raises that corner
   - Make small adjustments (1/4 turn at a time)
   - Run G80 to verify improvement

5. **Advanced: PINDA probe height:**
   - Ensure PINDA probe is at correct height (0.8-1mm above nozzle tip)
   - Incorrect height can cause mesh inconsistencies
   - Adjust PINDA bracket if needed

**Preventive Maintenance:**

- Check Z-axis alignment every 2-3 months
- Lubricate Z lead screws with PTFE lubricant
- Verify nylock nuts haven't loosened
- Keep Z linear bearings clean

**When to Re-align:**

- After moving the printer
- After any Z-axis maintenance
- If mesh shows sudden change in tilt
- After replacing any Z-axis components

**Emergency Z-alignment (Quick Method):**

If you need a quick print and Z is slightly off:

```gcode
; Add to start gcode
G28  ; Home all axes
G80  ; Mesh bed level
G81  ; Show mesh (check in terminal)
; Adjust Live-Z more aggressively on problem areas
; This is a workaround, not a fix!
```

**Recommended Tools:**

- Digital caliper (for measuring Z heights)
- Carpenter's square (for checking frame)
- Flashlight (for visual inspection)
- 7mm wrench (for nylock adjustments)

**Octoprint Plugin for Mesh Visualization:**

Install "Bed Level Visualizer" plugin to see mesh data graphically:
- Settings → Plugin Manager → Get More
- Search: "Bed Level Visualizer"
- Install and restart
- Run G80, then use plugin to visualize
- Helps identify which corner/axis is off

## Advanced Configuration

### Multiple Relays

Control multiple devices (lights, fan, heater):

1. Use additional GPIO pins:
   - GPIO 17: Lights
   - GPIO 27: Exhaust fan
   - GPIO 22: Enclosure heater

2. Configure in Enclosure plugin for each output

### Temperature/Humidity Sensor

Add DHT22 or BME280 sensor:

1. Connect to I2C or GPIO
2. Install Enclosure plugin
3. Add sensor input
4. Set temperature/humidity thresholds
5. Automate fan control based on conditions

### Custom GCODE Scripts

**Before print starts:**
```gcode
M117 Starting print...  ; Display message
; Lights already turned on by plugin
```

**After print completes:**
```gcode
M104 S0  ; Turn off nozzle
M140 S0  ; Turn off bed
M84     ; Disable motors
M117 Print complete!
```

Configure in Settings → GCODE Scripts

## Resources

- [Prusa MK3S Handbook](https://help.prusa3d.com/en/category/original-prusa-i3-mk3s-mk3s_156)
- [Octoprint Documentation](https://docs.octoprint.org/)
- [PrusaSlicer Handbook](https://help.prusa3d.com/en/category/prusaslicer_204)
- [Logitech C920 Linux Setup](https://wiki.archlinux.org/title/Webcam_setup)
- [Device Access Documentation](DEVICE_ACCESS.md)

## Support

If you encounter issues:
1. Check Octoprint logs: Settings → Logging
2. Check container logs: `docker logs octoprint`
3. Check system logs: `journalctl -u setup-containers`
4. Review device access: `ls -l /dev/tty* /dev/video* /dev/gpio*`

Happy printing! 🖨️
