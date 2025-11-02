# Orange Pi 4 LTS Hardware Reference

## GPIO Pinout (40-pin header)

```
     3.3V  (1) (2)  5V
GPIO2_A3  (3) (4)  5V
GPIO2_A2  (5) (6)  GND
GPIO2_B2  (7) (8)  GPIO2_B1
      GND  (9)(10)  GPIO2_B0
GPIO2_A7 (11)(12)  GPIO2_A1
GPIO2_A6 (13)(14)  GND
GPIO2_A5 (15)(16)  GPIO2_A4
     3.3V (17)(18)  GPIO2_B3
GPIO1_C0 (19)(20)  GND
GPIO1_B7 (21)(22)  GPIO2_A0
GPIO1_C1 (23)(24)  GPIO1_C2
      GND (25)(26)  GPIO1_B6
GPIO2_B4 (27)(28)  GPIO2_B5
GPIO2_C1 (29)(30)  GND
GPIO2_C0 (31)(32)  GPIO2_C7
GPIO2_C2 (33)(34)  GND
GPIO1_A7 (35)(36)  GPIO1_B0
GPIO2_C6 (37)(38)  GPIO1_A6
      GND (39)(40)  GPIO1_A5
```

## Pin Functions

### Power Pins
- **Pin 1, 17**: 3.3V (max 50mA)
- **Pin 2, 4**: 5V (connected to main power input)
- **Pin 6, 9, 14, 20, 25, 30, 34, 39**: Ground

### GPIO Pins (3.3V logic level)
All GPIO pins operate at 3.3V logic levels. Maximum current per pin: 8mA

### Communication Interfaces

#### I2C
- **I2C0**: GPIO2_A2 (SDA, Pin 5), GPIO2_A3 (SCL, Pin 3)
- **I2C7**: GPIO2_B4 (SDA, Pin 27), GPIO2_B5 (SCL, Pin 28)

#### SPI
- **SPI1**: 
  - MOSI: GPIO1_C0 (Pin 19)
  - MISO: GPIO1_B7 (Pin 21)
  - SCLK: GPIO1_C1 (Pin 23)
  - CS0: GPIO1_C2 (Pin 24)

#### UART
- **UART2**: GPIO2_B1 (TX, Pin 8), GPIO2_B0 (RX, Pin 10)

#### PWM
- **PWM0**: GPIO2_A6 (Pin 13)
- **PWM1**: GPIO2_A5 (Pin 15)

## Device Connections for 3D Printing

### Common 3D Printer Connections

#### Stepper Motor Drivers
- Use GPIO pins for STEP, DIR, and ENABLE signals
- Recommended pins: GPIO2_A0-A7 for primary axes

#### Endstops/Limit Switches
- Connect between GPIO pin and GND
- Use internal pull-up resistors in software
- Recommended pins: GPIO1_A5-A7, GPIO1_B0

#### Heated Bed/Hotend Control
- Use PWM pins for temperature control
- PWM0 (Pin 13): Hotend heater
- PWM1 (Pin 15): Heated bed
- Connect through MOSFET/SSR modules

#### Temperature Sensors
- Thermistors via ADC (if available)
- Or use I2C temperature sensor modules

#### Fans
- PWM control for part cooling fan
- GPIO pins for always-on fans

### USB Connections
- **USB-A ports**: For webcam, USB storage
- **USB-C**: Power input and data (when used as device)

### Serial Connections
- **UART2 (Pins 8,10)**: Primary serial for 3D printer firmware
- **USB-Serial**: Alternative connection via USB-A port

## Relay Control Setup for OctoPrint

### Overview
The OctoPrint container is pre-configured with GPIO access to control relays for various printer functions like power supplies, heaters, lights, and fans.

### Supported GPIO Libraries
- **OPi.GPIO**: Orange Pi specific GPIO library (installed in container)
- **gpiozero**: High-level GPIO library (installed in container)
- **lgpio**: Modern GPIO library for better performance

### Required OctoPrint Plugin
**OctoPrint-OPiGpioControl**: Specifically designed for Orange Pi GPIO control
- Installation: `pip install https://github.com/ckjdelux/OctoPrint-OPiGpioControl/archive/master.zip`
- This plugin provides Orange Pi compatibility that standard plugins lack

### Recommended OctoPrint Plugins

#### 1. PSU Control Plugin
**Purpose**: Control main power supply via relay
**Installation**: Available in OctoPrint Plugin Manager
**Configuration**:
- Switch GPIO Pin: `2` (Physical Pin 3)
- Inverted Output: `False` (adjust based on relay module)
- Switching Method: `GPIO`
- On Before Connect: `True`
- Off After Disconnect: `True`

#### 2. Enclosure Plugin
**Purpose**: Control enclosure lighting, fans, heaters
**Installation**: Available in OctoPrint Plugin Manager
**Features**: Temperature monitoring, GPIO outputs, PWM control

#### 3. OctoRelay Plugin
**Purpose**: General-purpose relay control with web interface
**Installation**: Available in OctoPrint Plugin Manager
**Features**: Multiple relay support, scheduling, G-code integration

### GPIO Pin Assignments for Relays (Orange Pi 4 LTS)

| Function | GPIO Number | Physical Pin | BCM Equivalent | Notes |
|----------|-------------|--------------|----------------|-------|
| Main PSU | GPIO150 | Pin 7 | - | Primary power control |
| Heated Bed | GPIO33 | Pin 11 | - | Bed relay backup/safety |
| Hotend Power | GPIO50 | Pin 12 | - | Hotend relay backup |
| Enclosure Light | GPIO35 | Pin 13 | - | LED strip control |
| Exhaust Fan | GPIO92 | Pin 15 | - | Ventilation control |
| Chamber Heater | GPIO54 | Pin 16 | - | Enclosure heating |
| Part Cooling | GPIO55 | Pin 18 | - | Auxiliary fan control |
| Emergency Stop | GPIO56 | Pin 22 | - | Safety cutoff |

**Note**: Orange Pi 4 LTS uses different GPIO numbering than Raspberry Pi. The OPi.GPIO library handles the translation between physical pins and GPIO numbers automatically.

### Relay Module Connections

#### Basic 5V Relay Module Connection
```
Orange Pi 4 LTS          Relay Module
GPIO Pin (3.3V) ────────► IN (Signal)
5V (Pin 2/4)    ────────► VCC (Power)
GND (Pin 6)     ────────► GND (Ground)
```

#### Optocoupler Relay Module (Recommended)
```
Orange Pi 4 LTS          Optocoupler Relay
GPIO Pin (3.3V) ────────► Signal Input
5V (Pin 2/4)    ────────► VCC
GND (Pin 6)     ────────► GND

Optocoupler Relay        Load (PSU/Heater)
COM             ────────► Load Common
NO (Normally Open) ─────► Load Hot Wire
```

### Software Configuration

#### 1. Enable GPIO Access
The container automatically:
- Installs GPIO libraries (`RPi.GPIO`, `gpiozero`, `lgpio`)
- Exports GPIO pins for relay control
- Sets proper permissions for GPIO access
- Adds OctoPrint user to `gpio` group

#### 2. Plugin Configuration Examples

**PSU Control Plugin Settings:**
```yaml
# In OctoPrint Settings > PSU Control
switchingMethod: gpio
gpioPin: 2
invertedOutput: false
onBeforeConnect: true
offAfterDisconnect: true
powerOffWhenIdle: true
idleTimeout: 1800  # 30 minutes
```

**Enclosure Plugin Settings:**
```yaml
# GPIO Outputs configuration
gpio_pins:
  - pin: 17
    label: "Enclosure Light"
    active_high: true
    initial_state: false
  - pin: 18
    label: "Exhaust Fan"
    active_high: true
    initial_state: false
```

#### 3. G-code Integration

Add to OctoPrint G-code scripts:

**Before Print Start:**
```gcode
M80        ; Turn on PSU (PSU Control plugin)
; Custom commands for enclosure
```

**After Print End:**
```gcode
; Custom commands to turn off non-essential items
M81        ; Turn off PSU after delay (PSU Control plugin)
```

### Testing GPIO Control

#### Manual Testing via SSH
```bash
# Test GPIO pin (example: GPIO2)
echo 2 > /sys/class/gpio/export
echo out > /sys/class/gpio/gpio2/direction
echo 1 > /sys/class/gpio/gpio2/value  # Turn on relay
echo 0 > /sys/class/gpio/gpio2/value  # Turn off relay
```

#### Python Testing Script
```python
# Test script for relay control
import RPi.GPIO as GPIO
import time

# Setup
GPIO.setmode(GPIO.BCM)
relay_pin = 2
GPIO.setup(relay_pin, GPIO.OUT)

# Test relay
print("Turning relay ON")
GPIO.output(relay_pin, GPIO.HIGH)
time.sleep(2)

print("Turning relay OFF")
GPIO.output(relay_pin, GPIO.LOW)

GPIO.cleanup()
```

## Important Notes

### Voltage Levels
- **GPIO Logic Level**: 3.3V (NOT 5V tolerant)
- **Use level shifters** for 5V devices
- **Maximum GPIO current**: 8mA per pin

### Power Considerations
- **5V pins** connected directly to power input
- **3.3V pins** limited to 50mA total
- Use external power for motors, heaters, etc.

### RK3399 SoC Specific
- Dual Cortex-A72 + Quad Cortex-A53 CPU
- Mali-T860MP4 GPU
- Hardware video encoding/decoding
- Gigabit Ethernet
- WiFi 802.11ac + Bluetooth 5.0

## Safety Warnings

⚠️ **ELECTRICAL SAFETY - CRITICAL**: 
- **GPIO Voltage**: Never exceed 3.3V on GPIO pins (NOT 5V tolerant)
- **Current Limits**: Maximum 8mA per GPIO pin, use relays for high current loads
- **Mains Voltage**: Always use optocouplers/isolation for AC mains switching
- **Relay Ratings**: Ensure relay can handle the load current and voltage
- **Fusing**: Install appropriate fuses for all high-current circuits

⚠️ **RELAY CONTROL SAFETY**:
- **Optocoupler Isolation**: Use optocoupler relay modules for mains voltage
- **Flyback Diodes**: Ensure relay modules have flyback diodes for inductive loads
- **Emergency Stop**: Always include hardware emergency stop independent of software
- **Fail-Safe Design**: Relays should fail to OFF state on power loss
- **Double-Pole Switching**: Use double-pole relays for hot and neutral on AC loads

⚠️ **3D PRINTER SAFETY**:
- **Thermal Runaway**: Maintain hardware thermal protection independent of software
- **Power Loss Recovery**: Ensure safe shutdown on unexpected power loss
- **Fire Safety**: Install smoke detectors and fire suppression in printer area
- **Regular Inspection**: Check all connections and relay contacts periodically

⚠️ **INSTALLATION SAFETY**:
- **Qualified Personnel**: Have licensed electrician install mains voltage connections
- **Local Codes**: Follow local electrical codes and regulations
- **Testing**: Use multimeter to verify all connections before powering on
- **Documentation**: Keep wiring diagrams and maintain proper labeling

## Recommended Accessories for 3D Printing

- GPIO expansion board with level shifters
- RAMPS-style shield designed for SBC
- External stepper driver board
- Temperature control modules
- Power supply management board