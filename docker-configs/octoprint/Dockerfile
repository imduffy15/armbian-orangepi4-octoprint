# Custom OctoPrint Image for Orange Pi 4 LTS with Prusa MK3S
# Prebaked with all plugins, tools, and configurations
FROM octoprint/octoprint:latest

LABEL maintainer="Orange Pi OctoPrint for MK3S"
LABEL description="Custom OctoPrint image with prebaked plugins for Orange Pi 4 LTS and Prusa MK3S"

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# Switch to root for system installations
USER root

# Install system dependencies
RUN apt-get update && apt-get install -y \
    # Build tools
    build-essential \
    git \
    curl \
    wget \
    # Hardware tools
    avrdude \
    avr-libc \
    gcc-avr \
    # Python development
    python3-dev \
    python3-pip \
    python3-setuptools \
    python3-serial \
    # System libraries
    libffi-dev \
    libssl-dev \
    libusb-1.0-0-dev \
    # GPIO and hardware access
    gpiod \
    libgpiod-dev \
    i2c-tools \
    # Cleanup
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Orange Pi GPIO libraries
RUN pip3 install --no-cache-dir \
    OPi.GPIO \
    gpiozero \
    lgpio \
    adafruit-circuitpython-busdevice \
    adafruit-circuitpython-register

# Create necessary directories
RUN mkdir -p \
    /opt/octoprint/plugins \
    /opt/octoprint/firmware \
    /opt/octoprint/configs \
    /usr/local/bin/octoprint-scripts

# Install OctoPrint plugins optimized for MK3S
RUN pip3 install --no-cache-dir \
    # Orange Pi GPIO support
    "https://github.com/ckjdelux/OctoPrint-OPiGpioControl/archive/master.zip" \
    # Firmware management
    "https://github.com/OctoPrint/OctoPrint-FirmwareUpdater/archive/master.zip" \
    # Bed leveling and calibration
    "https://github.com/jneilliii/OctoPrint-BedLevelVisualizer/archive/master.zip" \
    "https://github.com/FormerLurker/OctoPrint-ABLEXPERT/archive/master.zip" \
    "https://github.com/PrusaOwners/OctoPrint-PrusaMeshMap/archive/master.zip" \
    # Power and relay control
    "https://github.com/kantlivelong/OctoPrint-PSUControl/archive/master.zip" \
    "https://github.com/vitormhenrique/OctoPrint-Enclosure/archive/master.zip" \
    "https://github.com/bokunimbus/OctoPrint-OctoRelay/archive/master.zip" \
    # Print quality and monitoring
    "https://github.com/TheSpaghettiDetective/OctoPrint-TheSpaghettiDetective/archive/master.zip" \
    "https://github.com/eyal0/OctoPrint-PrintTimeGenius/archive/master.zip" \
    "https://github.com/tjjfvi/OctoPrint-LayerDisplay/archive/master.zip" \
    # File management
    "https://github.com/Salandora/OctoPrint-FileManager/archive/master.zip" \
    "https://github.com/jneilliii/OctoPrint-BackupScheduler/archive/master.zip" \
    # Prusa specific
    "https://github.com/lordofhyphens/OctoPrint-PrusaSlicerThumbnails/archive/master.zip" \
    "https://github.com/3dprintscotland/OctoPrint_PrusaMMU/archive/master.zip" \
    # UI enhancements
    "https://github.com/StefanCohen/OctoPrint-Dashboard/archive/master.zip" \
    "https://github.com/OctoPrint/OctoPrint-GCODE-System-Commands/archive/master.zip" \
    "https://github.com/Salandora/OctoPrint-CustomControl/archive/master.zip" \
    # Safety and monitoring
    "https://github.com/Sebazzz/OctoPrint-SimpleEmergencyStop/archive/master.zip" \
    "https://github.com/OllisGit/OctoPrint-CostEstimation/archive/master.zip" \
    # Notifications
    "https://github.com/fabianonline/OctoPrint-Telegram/archive/master.zip" \
    "https://github.com/anoved/OctoPrint-EmailNotifier/archive/master.zip" \
    # Performance monitoring
    "https://github.com/Renaud11232/OctoPrint-Resource-Monitor/archive/master.zip" \
    "https://github.com/dattas/OctoPrint-DetailedProgress/archive/master.zip" \
    # Webcam integration
    "https://github.com/mikedmor/OctoPrint_MultiCam/archive/master.zip"

# Handle potential installation failures gracefully
RUN pip3 install --no-cache-dir \
    "https://github.com/prusa3d/Prusa-Connect-Local/archive/master.zip" || echo "Prusa Connect Local installation failed - continuing..." && \
    pip3 install --no-cache-dir \
    "https://github.com/jneilliii/OctoPrint-UltimakerFormatPackage/archive/master.zip" || echo "Ultimaker Format Package installation failed - continuing..."

# Copy configuration files
COPY configs/avrdude.conf.local /etc/avrdude.conf.local
COPY configs/octoprint-config.yaml /opt/octoprint/configs/config.yaml
COPY configs/mk3s-profiles.yaml /opt/octoprint/configs/mk3s-profiles.yaml

# Copy scripts
COPY scripts/gpio-setup.sh /usr/local/bin/gpio-setup.sh
COPY scripts/startup-script.sh /usr/local/bin/startup-script.sh

# Create hardware groups
RUN groupadd -f gpio && \
    groupadd -f i2c && \
    groupadd -f spi && \
    groupadd -f video

# Add octoprint user to hardware groups
RUN usermod -a -G gpio,i2c,spi,video,dialout octoprint

# Set up GPIO permissions script
RUN chmod +x /usr/local/bin/gpio-setup.sh && \
    chmod +x /usr/local/bin/startup-script.sh

# Create avrdude configuration for MK3S
RUN cat > /etc/avrdude.conf.local << 'EOF'
# MK3S specific avrdude configuration
# ATmega32u4 configuration for Prusa MK3S
programmer
  id    = "arduino";
  desc  = "Arduino";
  type  = "arduino";
  connection_type = serial;
;

part
  id               = "m32u4";
  desc             = "ATmega32u4";
  signature        = 0x1e 0x95 0x87;
  has_jtag         = yes;
  has_debugwire    = no;
  has_pdi          = no;
  has_tpi          = no;
  has_updi         = no;
  allowfullpagebitstream = no;
;
EOF

# Set up firmware directory with proper permissions
RUN mkdir -p /octoprint/firmware && \
    chown octoprint:octoprint /octoprint/firmware && \
    chmod 755 /octoprint/firmware

# Create default plugin configurations
RUN mkdir -p /octoprint/.octoprint/data && \
    chown -R octoprint:octoprint /octoprint/.octoprint

# Switch back to octoprint user
USER octoprint

# Set working directory
WORKDIR /octoprint

# Create default OctoPrint configuration optimized for MK3S and Orange Pi
RUN mkdir -p ~/.octoprint && \
    cat > ~/.octoprint/config.yaml << 'EOF'
# OctoPrint configuration for Orange Pi 4 LTS + Prusa MK3S
webcam:
  stream: http://camera.octoprint.local/
  snapshot: http://camera.octoprint.local/snapshot
  ffmpeg: /usr/bin/ffmpeg

serial:
  port: /dev/ttyACM0
  baudrate: 115200
  autoconnect: true
  timeout:
    detection: 5.0
    connection: 10.0
    communication: 30.0

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
  _disabled: []
  
  firmwareupdater:
    avrdude_path: /usr/bin/avrdude
    avrdude_conf: /etc/avrdude.conf
    
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
        
  resource_monitor:
    enabled: true
    interval: 30
EOF

# Create custom controls for MK3S
RUN cat > ~/.octoprint/data/customControls.yaml << 'EOF'
controls:
  - name: "MK3S Controls"
    layout: vertical
    children:
      - name: "Filament"
        layout: horizontal
        children:
          - name: "Load Filament"
            command: "M701"
            confirm: "This will heat the nozzle to load filament. Continue?"
          - name: "Unload Filament"
            command: "M702"
            confirm: "This will heat the nozzle to unload filament. Continue?"
      - name: "Preheating"
        layout: horizontal
        children:
          - name: "Preheat PLA"
            commands:
              - "M104 S215"
              - "M140 S60"
          - name: "Preheat PETG"
            commands:
              - "M104 S230"
              - "M140 S85"
          - name: "Preheat ABS"
            commands:
              - "M104 S255"
              - "M140 S100"
          - name: "Cooldown"
            commands:
              - "M104 S0"
              - "M140 S0"
      - name: "Calibration"
        layout: horizontal
        children:
          - name: "Mesh Bed Leveling"
            command: "G80"
            confirm: "Start mesh bed leveling? This may take several minutes."
          - name: "Load Settings"
            command: "M501"
          - name: "Save Settings"
            command: "M500"
      - name: "Maintenance"
        layout: horizontal
        children:
          - name: "Home All"
            command: "G28"
          - name: "Disable Steppers"
            command: "M84"
          - name: "Restart Printer"
            command: "M999"
            confirm: "Restart the printer firmware?"
EOF

# Copy startup script and set permissions
COPY --chown=octoprint:octoprint scripts/startup-script.sh /home/octoprint/startup-script.sh
RUN chmod +x /home/octoprint/startup-script.sh

# Set the default command to run the startup script
CMD ["/home/octoprint/startup-script.sh"]

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:5000/ || exit 1

# Expose port
EXPOSE 5000

# Labels for metadata
LABEL version="1.0"
LABEL description="Custom OctoPrint for Orange Pi 4 LTS with Prusa MK3S support"
LABEL plugins="gpio,firmware,bed-leveling,power-control,monitoring,prusa-specific"