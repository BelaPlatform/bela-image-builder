#!/bin/bash -e


sudo cp -v ${DIR}/kernel/*.deb $targetdir/root/
sudo cp -v ${DIR}/kernel/kernel_version $targetdir/root/
sudo cp -r ${DIR}/downloads/Bela $targetdir/root/
sudo cp -R ${DIR}/downloads/clang+llvm-4.0.0-armv7a-linux-gnueabihf/* $targetdir/usr/local/

sudo mkdir -p $targetdir/opt/Bela
sudo cp -v ${DIR}/downloads/setup_7.x $targetdir/opt/Bela/
sudo cp -r ${DIR}/downloads/prudebug $targetdir/opt/
sudo cp -r ${DIR}/downloads/am335x_pru_package $targetdir/opt/
sudo cp -r ${DIR}/downloads/bb.org-overlays $targetdir/opt/
sudo cp -r ${DIR}/downloads/bb.org-dtc $targetdir/opt/
sudo cp -r ${DIR}/downloads/dtb-rebuilder $targetdir/opt/
sudo cp -r ${DIR}/downloads/boot-scripts $targetdir/opt/bb.org-scripts
sudo cp -r ${DIR}/downloads/xenomai-3 $targetdir/opt/

# install xenomai to rootfs
echo "~~~~ installing xenomai  ~~~~"
sudo make -C ${DIR}/downloads/xenomai-3 install DESTDIR=$targetdir --no-print-directory

# maybe should go in a post-chroot.sh?
sudo cp -rv ${DIR}/misc/rootfs/* $targetdir/
