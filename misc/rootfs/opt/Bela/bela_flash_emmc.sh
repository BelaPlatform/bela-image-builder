#!/bin/bash

set -ex

USR1=/sys/class/leds/beaglebone\:green\:usr1/trigger
USR2=/sys/class/leds/beaglebone\:green\:usr2/trigger
USR3=/sys/class/leds/beaglebone\:green\:usr3/trigger
SUCCESS=0
final_check()
{
	if [ $SUCCESS -eq 0 ]
	then
		while sleep 0.5
		do
			echo "default-on" > $USR1
			echo "default-on" > $USR2
			echo "default-on" > $USR3
			sleep 0.5
			echo "none" > $USR1
			echo "none" > $USR2
			echo "none" > $USR3
		done
		fi
}
trap final_check EXIT

# Stop the Bela program if currently running. Makes for a faster copy.
make --no-print-directory -C /root/Bela stop || true

echo "default-on" > $USR1
echo "default-on" > $USR2
echo "default-on" > $USR3

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

echo "mmc0" > $USR1
echo "none" > $USR2
echo "mmc1" > $USR3
SUCCESS=1
