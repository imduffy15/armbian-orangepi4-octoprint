#!/bin/bash
# GPIO Setup Script for OctoPrint Container - Orange Pi 4 LTS Compatible

echo "Setting up Orange Pi 4 LTS GPIO access for OctoPrint..."

# Create necessary groups if they don't exist
for group in gpio i2c spi video; do
    if ! getent group $group > /dev/null 2>&1; then
        groupadd $group
        echo "Created group: $group"
    fi
done

# Add octoprint user to necessary groups
usermod -a -G gpio,i2c,spi,video,dialout octoprint
echo "Added octoprint user to hardware access groups"

# Set permissions for GPIO devices
if [ -e /dev/gpiomem ]; then
    chown root:gpio /dev/gpiomem
    chmod g+rw /dev/gpiomem
    echo "GPIO memory access configured"
fi

# Set permissions for GPIO character devices
for gpiochip in /dev/gpiochip*; do
    if [ -e "$gpiochip" ]; then
        chown root:gpio "$gpiochip"
        chmod g+rw "$gpiochip"
        echo "Configured $gpiochip"
    fi
done

# Set permissions for GPIO sysfs (legacy support)
if [ -d /sys/class/gpio ]; then
    chown -R root:gpio /sys/class/gpio
    chmod -R g+w /sys/class/gpio
    echo "GPIO sysfs access configured"
fi

# Orange Pi 4 LTS GPIO pin mapping for relay control
# Using physical pin numbers that correspond to commonly used relay pins
# Physical Pin -> GPIO Number mapping for Orange Pi 4 LTS:
# Pin 3  -> GPIO64  (I2C2_SDA)  - Can be used as GPIO
# Pin 5  -> GPIO65  (I2C2_SCL)  - Can be used as GPIO  
# Pin 7  -> GPIO150 (GPIO4_C6)  - General purpose GPIO
# Pin 11 -> GPIO33  (GPIO1_A1)  - General purpose GPIO
# Pin 12 -> GPIO50  (GPIO1_C2)  - General purpose GPIO
# Pin 13 -> GPIO35  (GPIO1_A3)  - General purpose GPIO
# Pin 15 -> GPIO92  (GPIO2_D4)  - General purpose GPIO
# Pin 16 -> GPIO54  (GPIO1_C6)  - General purpose GPIO
# Pin 18 -> GPIO55  (GPIO1_C7)  - General purpose GPIO
# Pin 22 -> GPIO56  (GPIO1_D0)  - General purpose GPIO

RELAY_PINS="150 33 50 35 92 54 55 56"

echo "Configuring GPIO pins for relay control..."
for pin in $RELAY_PINS; do
    if [ ! -d "/sys/class/gpio/gpio$pin" ]; then
        echo $pin > /sys/class/gpio/export 2>/dev/null || true
        sleep 0.1  # Small delay for GPIO export
        if [ -d "/sys/class/gpio/gpio$pin" ]; then
            echo out > /sys/class/gpio/gpio$pin/direction 2>/dev/null || true
            echo 0 > /sys/class/gpio/gpio$pin/value 2>/dev/null || true
            chown -R root:gpio /sys/class/gpio/gpio$pin 2>/dev/null || true
            chmod -R g+w /sys/class/gpio/gpio$pin 2>/dev/null || true
            echo "Exported and configured GPIO$pin for relay control"
        fi
    else
        echo "GPIO$pin already exported"
    fi
done

# Set permissions for I2C devices (if present)
for i2c_dev in /dev/i2c-*; do
    if [ -e "$i2c_dev" ]; then
        chown root:i2c "$i2c_dev"
        chmod g+rw "$i2c_dev"
        echo "Configured $i2c_dev"
    fi
done

# Set permissions for SPI devices (if present) 
for spi_dev in /dev/spidev*; do
    if [ -e "$spi_dev" ]; then
        chown root:spi "$spi_dev"
        chmod g+rw "$spi_dev"
        echo "Configured $spi_dev"
    fi
done

echo "Orange Pi 4 LTS GPIO setup completed successfully"
echo "Available GPIO pins for relay control: $RELAY_PINS"