#!/bin/bash -e

cd ${DIR}
rm -rf bela.img

echo "creating Bela SD image"

# create empty 4gb disk image
dd if=/dev/zero of=./bela.img bs=1M count=4000

# partition it
sudo sfdisk ${DIR}/bela.img < ${DIR}/bela.sfdisk

# mount it
LOOP=`losetup -f`
LOOP=`echo $LOOP | sed "s/\/dev\///"`
#sudo losetup /dev/$LOOP
# -s makes sure the operation is applied before continuing
sudo kpartx -s -av ${DIR}/bela.img
sudo mkfs.vfat /dev/mapper/loop0p1
sudo dosfslabel /dev/mapper/loop0p1 BELABOOT
sudo mkfs.ext4 /dev/mapper/loop0p2
sudo e2label /dev/mapper/loop0p2 BELAROOTFS

mkdir -p /mnt/bela/boot
mkdir -p /mnt/bela/root
sudo mount /dev/mapper/${LOOP}p1 /mnt/bela/boot
sudo mount /dev/mapper/${LOOP}p2 /mnt/bela/root

# complete and copy uboot environment
cp ${DIR}/boot/uEnv.txt ${DIR}/boot/uEnv.tmp
echo "uname_r=`cat ${DIR}/kernel/kernel_version`" >> ${DIR}/boot/uEnv.tmp
echo "dtb=am335x-bone-bela.dtb" >> ${DIR}/boot/uEnv.tmp
sudo cp -v ${DIR}/boot/uEnv.tmp /mnt/bela/boot/uEnv.txt
rm ${DIR}/boot/uEnv.tmp

# copy bootloader and dtb
sudo cp -v ${DIR}/boot/MLO /mnt/bela/boot/
sudo cp -v ${DIR}/boot/u-boot.img /mnt/bela/boot/
sudo cp -v ${DIR}/boot/am335x-bone-bela.dtb /mnt/bela/boot/
# copy rootfs
sudo cp -a ${DIR}/rootfs/* /mnt/bela/root/

# unmount
sudo umount /mnt/bela/boot
sudo umount /mnt/bela/root
sudo kpartx -d /dev/${LOOP}
sudo losetup -d /dev/${LOOP}

echo "bela.img created"
