# Installing to eMMC on Orange Pi 4 LTS

The Orange Pi 4 LTS has onboard eMMC storage that provides faster and more reliable storage than SD cards. This guide shows you how to install the system to eMMC.

## Prerequisites

- Orange Pi 4 LTS with eMMC module installed
- MicroSD card with the flashed image
- SSH access or monitor/keyboard connected

## Installation Methods

### Method 1: Using Armbian's nand-sata-install (Recommended)

This is the easiest and safest method, provided by Armbian.

#### Steps:

1. **Boot from SD Card**
   - Flash the image to SD card
   - Boot the Orange Pi from the SD card
   - Complete the first boot setup (WiFi configuration, password change, etc.)

2. **Run the Installation Utility**
   ```bash
   sudo nand-sata-install
   ```

3. **Select Installation Option**
   - Choose option `2` - "Boot from eMMC - system on eMMC"
   - Confirm the operation (this will erase eMMC!)

4. **Wait for Installation**
   - The utility will copy the system to eMMC
   - This takes 5-10 minutes depending on the size

5. **Power Off and Remove SD Card**
   ```bash
   sudo poweroff
   ```
   - Remove the SD card
   - Power on the device

6. **Verify eMMC Boot**
   ```bash
   lsblk
   ```
   - Your root filesystem should be on `mmcblk1` or `mmcblk2` (eMMC)
   - SD card is typically `mmcblk0`

### Method 2: Manual Installation via Script

We provide a helper script for automated eMMC installation.

#### Steps:

1. **Boot from SD Card**
   ```bash
   # SSH into the device
   ssh root@<device-ip>
   ```

2. **Download the Installation Script**
   ```bash
   wget https://raw.githubusercontent.com/<your-repo>/main/scripts/install-to-emmc.sh
   chmod +x install-to-emmc.sh
   ```

3. **Run the Script**
   ```bash
   sudo ./install-to-emmc.sh
   ```

4. **Follow Prompts**
   - Review the warning
   - Type `yes` to confirm
   - Wait for installation to complete

5. **Reboot to eMMC**
   ```bash
   sudo reboot
   ```
   - Remove the SD card after shutdown

### Method 3: Advanced - Manual dd Method

**⚠️ Warning: This method is for advanced users only!**

1. **Boot from SD Card**

2. **Identify Devices**
   ```bash
   lsblk
   ```
   - SD card: usually `/dev/mmcblk0`
   - eMMC: usually `/dev/mmcblk1` or `/dev/mmcblk2`

3. **Backup eMMC (Optional but Recommended)**
   ```bash
   sudo dd if=/dev/mmcblk1 of=/tmp/emmc-backup.img bs=4M status=progress
   ```

4. **Clone SD to eMMC**
   ```bash
   sudo dd if=/dev/mmcblk0 of=/dev/mmcblk1 bs=4M status=progress conv=fsync
   ```

5. **Expand eMMC Partition**
   ```bash
   # Install parted if needed
   sudo apt-get install -y parted

   # Expand partition
   sudo parted /dev/mmcblk1 resizepart 1 100%
   sudo resize2fs /dev/mmcblk1p1
   ```

6. **Update Boot Configuration**
   ```bash
   # Mount eMMC
   sudo mkdir -p /mnt/emmc
   sudo mount /dev/mmcblk1p1 /mnt/emmc

   # Update boot.cmd or extlinux.conf if needed
   # This depends on the bootloader configuration

   # Unmount
   sudo umount /mnt/emmc
   ```

7. **Reboot Without SD Card**
   ```bash
   sudo poweroff
   # Remove SD card
   # Power on
   ```

## Verification

After booting from eMMC, verify the installation:

```bash
# Check root filesystem
df -h /
# Should show /dev/mmcblk1p1 or /dev/mmcblk2p1

# Check boot device
cat /proc/cmdline | grep root
# Should reference eMMC device

# Check all block devices
lsblk
```

Expected output:
```
NAME         MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
mmcblk1      179:0    0 14.6G  0 disk
└─mmcblk1p1  179:1    0 14.4G  0 part /
```

## Troubleshooting

### Device Won't Boot from eMMC

1. **Check Boot Order**
   - Some Orange Pi boards check SD card first
   - Make sure SD card is removed

2. **Verify eMMC is Detected**
   - Boot from SD card
   - Run: `lsblk` - eMMC should appear as mmcblk1 or mmcblk2

3. **Reinstall Bootloader**
   ```bash
   # Boot from SD card
   sudo nand-sata-install
   # Choose option to reinstall bootloader to eMMC
   ```

### eMMC Performance Issues

1. **Check eMMC Speed**
   ```bash
   sudo hdparm -t /dev/mmcblk1
   ```

2. **Verify eMMC Health**
   ```bash
   sudo smartctl -a /dev/mmcblk1
   ```

### Containers Not Starting After eMMC Install

The container setup service runs once. If you need to redeploy:

```bash
# Remove the completion flag
sudo rm /var/lib/setup-containers-done

# Restart the service
sudo systemctl restart setup-containers.service

# Or manually run setup scripts
sudo /usr/local/bin/setup-portainer.sh
sudo /usr/local/bin/setup-octoprint.sh
```

## Performance Comparison

| Storage | Read Speed | Write Speed | Durability | Cost |
|---------|-----------|-------------|------------|------|
| SD Card | ~40 MB/s  | ~20 MB/s    | Lower      | Low  |
| eMMC    | ~150 MB/s | ~70 MB/s    | Higher     | Built-in |

eMMC provides:
- ✅ 3-4x faster read/write speeds
- ✅ Better reliability for 24/7 operation
- ✅ Lower latency for container operations
- ✅ No wear on SD card slot

## Best Practices

1. **Always backup before eMMC installation**
   - Container data: `/opt/octoprint/data`
   - Docker volumes: `docker volume ls`

2. **Use SD card for initial testing**
   - Test your configuration on SD first
   - Once stable, move to eMMC

3. **Keep SD card as recovery option**
   - Flash a recovery image to SD
   - Keep it handy for emergencies

4. **Regular backups**
   ```bash
   # Backup Octoprint data
   tar -czf octoprint-backup-$(date +%Y%m%d).tar.gz /opt/octoprint/data

   # Backup Docker volumes
   docker run --rm -v portainer_data:/data -v $(pwd):/backup \
     alpine tar -czf /backup/portainer-backup.tar.gz -C /data .
   ```

## Recovery

If you need to recover from a failed eMMC installation:

1. Flash a new image to SD card
2. Boot from SD card
3. Mount the eMMC and recover data:
   ```bash
   sudo mkdir -p /mnt/emmc
   sudo mount /dev/mmcblk1p1 /mnt/emmc

   # Copy important data
   cp -r /mnt/emmc/opt/octoprint/data /tmp/octoprint-backup

   sudo umount /mnt/emmc
   ```
4. Re-run the eMMC installation

## Additional Resources

- [Armbian eMMC Documentation](https://docs.armbian.com/User-Guide_Getting-Started/#how-to-install-to-emmc-nand-sata-usb)
- [Orange Pi 4 LTS Wiki](http://www.orangepi.org/html/hardWare/computerAndMicrocontrollers/details/Orange-Pi-4-LTS.html)

## FAQ

**Q: Can I boot from SD and use eMMC for data storage?**
A: Yes! You can mount eMMC as `/opt` or create a separate data partition. This gives you flexibility to swap SD cards while keeping data persistent.

**Q: Will my containers/data transfer automatically?**
A: Yes, if you use Method 1 (nand-sata-install), everything is copied. The containers will be redeployed on first boot.

**Q: Can I switch back to SD card?**
A: Yes, just power off, insert the SD card, and boot. The bootloader typically checks SD card first.

**Q: How do I update the system after installing to eMMC?**
A: Normal updates work: `sudo apt update && sudo apt upgrade`

**Q: What happens if eMMC fails?**
A: Boot from SD card recovery image and restore from backups. eMMC failure is rare but possible.
