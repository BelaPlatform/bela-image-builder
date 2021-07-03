#!/bin/bash -e

[ -z "$targetdir" ] && { echo "undefined variable: \$targetdir"; exit 1; }
[ -z "$DIR" ] && { echo "undefined variable: \$DIR"; exit 1; }

sudo cp -v ${DIR}/kernel/*.deb $targetdir/root/
sudo cp -v ${DIR}/kernel/kernel_version $targetdir/root/
sudo cp -r ${DIR}/downloads/Bela $targetdir/root/
sudo mkdir -p $targetdir/root/kernel-tools
sudo cp -r ${DIR}/downloads/ti-linux-kernel-dev/KERNEL/arch/arm/tools/* ${DIR}/rootfs/root/kernel-tools

sudo mkdir -p $targetdir/opt/Bela
sudo cp -v ${DIR}/downloads/setup_10.x $targetdir/opt/Bela/
sudo cp -r ${DIR}/downloads/prudebug $targetdir/opt/
sudo cp -r ${DIR}/downloads/checkinstall $targetdir/opt/
sudo cp -r ${DIR}/downloads/am335x_pru_package $targetdir/opt/
sudo cp -r ${DIR}/downloads/bb.org-overlays $targetdir/opt/
sudo cp -r ${DIR}/downloads/dtc $targetdir/opt/
sudo cp -r ${DIR}/downloads/BeagleBoard-DeviceTrees $targetdir/opt/
sudo cp -r ${DIR}/downloads/seasocks $targetdir/opt/
sudo cp -r ${DIR}/downloads/xenomai-3 $targetdir/opt/
sudo cp -r ${DIR}/downloads/rtdm_pruss_irq $targetdir/opt/
sudo cp -r ${DIR}/downloads/deb $targetdir/opt/
sudo cp -r ${DIR}/downloads/hvcc $targetdir/opt/

# get some missing folders from the kernel
KERNEL_DIR_HOST=${DIR}/downloads/ti-linux-kernel-dev/KERNEL
DESTDIR=$targetdir/usr/src/linux-headers-`cat ${DIR}/kernel/kernel_version`

MISSING_DIR=security/selinux/include
mkdir -p $DESTDIR/$MISSING_DIR
sudo cp -r $KERNEL_DIR_HOST/$MISSING_DIR/* $DESTDIR/$MISSING_DIR

MISSING_DIR=tools/include
mkdir -p $DESTDIR/$MISSING_DIR
sudo cp -r $KERNEL_DIR_HOST/$MISSING_DIR/* $DESTDIR/$MISSING_DIR

# install xenomai to rootfs
echo "~~~~ installing xenomai  ~~~~"
sudo make -C ${DIR}/downloads/xenomai-3-build install DESTDIR=$targetdir --no-print-directory

sudo cp -rv ${DIR}/misc/rootfs/* $targetdir/

