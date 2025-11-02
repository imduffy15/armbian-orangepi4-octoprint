FROM octoprint/octoprint:latest

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# Switch to root for installations
USER root

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential git curl wget \
    avrdude avr-libc gcc-avr \
    python3-dev python3-pip python3-setuptools python3-serial \
    libffi-dev libssl-dev libusb-1.0-0-dev \
    gpiod libgpiod-dev i2c-tools \
    swig \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Orange Pi GPIO libraries (skip lgpio due to compilation complexity, OPi.GPIO is sufficient)
RUN pip3 install --no-cache-dir OPi.GPIO gpiozero

# Install essential OctoPrint plugins with error handling
RUN pip3 install --no-cache-dir \
    "https://github.com/kantlivelong/OctoPrint-PSUControl/archive/master.zip" || true && \
    pip3 install --no-cache-dir \
    "https://github.com/vitormhenrique/OctoPrint-Enclosure/archive/master.zip" || true && \
    pip3 install --no-cache-dir \
    "https://github.com/OctoPrint/OctoPrint-FirmwareUpdater/archive/master.zip" || true && \
    pip3 install --no-cache-dir \
    "https://github.com/jneilliii/OctoPrint-BedLevelVisualizer/archive/master.zip" || true && \
    pip3 install --no-cache-dir \
    "https://github.com/eyal0/OctoPrint-PrintTimeGenius/archive/master.zip" || true && \
    pip3 install --no-cache-dir \
    "https://github.com/Sebazzz/OctoPrint-SimpleEmergencyStop/archive/master.zip" || true && \
    pip3 install --no-cache-dir \
    "https://github.com/StefanCohen/OctoPrint-Dashboard/archive/master.zip" || true && \
    pip3 install --no-cache-dir \
    "https://github.com/Salandora/OctoPrint-CustomControl/archive/master.zip" || true

# Install additional plugins with error handling
RUN pip3 install --no-cache-dir \
    "https://github.com/jneilliii/OctoPrint-BackupScheduler/archive/master.zip" || true && \
    echo "Plugin installation completed with error handling"

# Create hardware groups and octoprint user
RUN for group in gpio i2c spi video; do groupadd -f $group; done && \
    useradd -m -s /bin/bash octoprint && \
    usermod -a -G gpio,i2c,spi,video,dialout octoprint

# Copy configuration scripts
COPY gpio-setup.sh /usr/local/bin/gpio-setup.sh
COPY startup-script.sh /usr/local/bin/startup-script.sh
RUN chmod +x /usr/local/bin/*.sh

# Create avrdude config for MK3S
RUN echo 'programmer\n  id = "arduino";\n  type = "arduino";\n  connection_type = serial;\n;' > /etc/avrdude.conf.local

# Set up directories
RUN mkdir -p /octoprint/firmware && chown octoprint:octoprint /octoprint/firmware

# Switch back to octoprint user
USER octoprint
WORKDIR /octoprint

# Create optimized config
RUN mkdir -p ~/.octoprint && cat > ~/.octoprint/config.yaml << 'EOC'
webcam:
  stream: http://camera.octoprint.local/
  snapshot: http://camera.octoprint.local/snapshot
serial:
  port: /dev/ttyACM0
  baudrate: 115200
  autoconnect: true
temperature:
  profiles:
    - name: "PLA"
      extruder: 215
      bed: 60
    - name: "PETG"
      extruder: 230
      bed: 85
    - name: "ABS"
      extruder: 255
      bed: 100
server:
  host: 0.0.0.0
  port: 5000
plugins:
  psucontrol:
    switchingMethod: gpio
    gpioPin: 150
    invertedOutput: false
    onBeforeConnect: true
    offAfterDisconnect: true
  enclosure:
    gpio_pins:
      - pin: 33
        label: "Enclosure Light"
        active_high: true
        initial_state: false
      - pin: 50
        label: "Exhaust Fan"
        active_high: true
        initial_state: false
EOC

CMD ["/usr/local/bin/startup-script.sh"]
EXPOSE 5000
