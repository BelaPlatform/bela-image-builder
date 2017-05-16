#!/bin/bash -e
 
cd /sys/kernel/config/usb_gadget/
mkdir g && cd g
 
echo 0x1d6b > idVendor  # Linux Foundation
echo 0x0104 > idProduct # Multifunction Composite Gadget
echo 0x0100 > bcdDevice # v1.0.0
echo 0x0200 > bcdUSB    # USB 2.0
 
mkdir -p strings/0x409
echo "__bela__" > strings/0x409/serialnumber
echo "Augmented Instruments Ltd" > strings/0x409/manufacturer
echo "Bela" > strings/0x409/product
 
mkdir -p functions/rndis.usb0           # network
mkdir -p functions/mass_storage.0       # boot partition
mkdir -p functions/acm.usb0             # serial
mkdir -p functions/midi.usb0            # MIDI

# mount the boot partition and make it available as mass storage
mkdir -p /mnt/boot
mount /dev/mmcblk0p1 /mnt/boot
echo /dev/mmcblk0p1 > functions/mass_storage.0/lun.0/file

mkdir -p configs/c.1
echo 500 > configs/c.1/MaxPower
ln -s functions/rndis.usb0 configs/c.1/
ln -s functions/mass_storage.0 configs/c.1/
ln -s functions/acm.usb0   configs/c.1/
ln -s functions/midi.usb0 configs/c.1

udevadm settle -t 5 || :
ls /sys/class/udc/ > UDC

# hack to ensure dhcpd has a free lease
echo "" > /var/lib/dhcp/dhcpd.leases
