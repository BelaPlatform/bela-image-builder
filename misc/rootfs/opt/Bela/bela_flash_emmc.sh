#!/bin/sh -e

sfdisk /dev/mmcblk1 < /opt/Bela/bela.sfdisk

mkfs.vfat /dev/mmcblk1p1
mkfs.ext4 /dev/mmcblk1p2

dosfslabel /dev/mmcblk1p1 BELABOOT
e2label /dev/mmcblk1p2 BELAROOTFS

mkdir -p /mnt/emmc_boot
mkdir -p /mnt/root

mount /dev/mmcblk1p1 /mnt/emmc_boot
mount /dev/mmcblk1p2 /mnt/root

cp -av /mnt/boot/MLO /mnt/boot/u-boot.img /mnt/boot/*.dtb /mnt/boot/uEnv.txt /mnt/emmc_boot
cp -av /bin/ /boot/ /dev/ /etc/ /home/ /lib/ /opt/ /root/ /sbin/ /srv/ /usr/ /var/ /mnt/root
mkdir -p /mnt/root/media /mnt/root/mnt /mnt/root/proc /mnt/root/run/ /mnt/root/sys /mnt/root/tmp
cp -av /opt/Bela/fstab-emmc /mnt/root/etc/fstab
sync

umount /mnt/emmc_boot
umount /mnt/root
