#!/bin/sh -e

# Stop the Bela program if currently running. Makes for a faster copy.
make -C /root/Bela stop || true

echo "default-on" > /sys/class/leds/beaglebone\:green\:usr1/trigger
echo "default-on" > /sys/class/leds/beaglebone\:green\:usr2/trigger
echo "default-on" > /sys/class/leds/beaglebone\:green\:usr3/trigger

sfdisk /dev/mmcblk1 < /opt/Bela/bela-emmc.sfdisk

mkfs.vfat /dev/mmcblk1p1
mkfs.ext4 -F /dev/mmcblk1p2

dosfslabel /dev/mmcblk1p1 BELABOOT
e2label /dev/mmcblk1p2 BELAROOTFS

mkdir -p /mnt/emmc_boot
mkdir -p /mnt/root

mount /dev/mmcblk1p1 /mnt/emmc_boot
mount /dev/mmcblk1p2 /mnt/root

echo "copying files, this may take a few minutes..."

cp /mnt/boot/MLO /mnt/emmc_boot
sync
cp /mnt/boot/u-boot.img /mnt/emmc_boot
sync
rsync -r --exclude=/mnt/boot/MLO,/mnt/boot/u-boot.img /mnt/boot/* /mnt/emmc_boot
cp -a /opt/Bela/uEnv-emmc.txt /mnt/emmc_boot/uEnv.txt
cp -a /bin/ /boot/ /dev/ /etc/ /home/ /lib/ /opt/ /root/ /sbin/ /srv/ /usr/ /var/ /mnt/root
mkdir -p /mnt/root/media /mnt/root/mnt /mnt/root/proc /mnt/root/run/ /mnt/root/sys /mnt/root/tmp
cp -a /opt/Bela/fstab-emmc /mnt/root/etc/fstab
echo "/dev/mmcblk1" > /mnt/root/opt/Bela/rootfs_dev
rm /mnt/root/etc/systemd/system/default.target.wants/bela_flash_emmc.service || true
sync

umount /mnt/emmc_boot
umount /mnt/root

echo "Done!"

echo "mmc0" > /sys/class/leds/beaglebone\:green\:usr1/trigger
echo "none" > /sys/class/leds/beaglebone\:green\:usr2/trigger
echo "mmc1" > /sys/class/leds/beaglebone\:green\:usr3/trigger
