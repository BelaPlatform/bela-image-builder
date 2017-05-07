#!/bin/bash -e

sudo mkdir -p $targetdir/opt/Bela

sudo cp -v ${DIR}/kernel/*.deb $targetdir/root/
sudo cp -v ${DIR}/kernel/kernel_version $targetdir/root/

sudo cp -r ${DIR}/downloads/Bela $targetdir/root/

sudo cp -R ${DIR}/downloads/clang+llvm-4.0.0-armv7a-linux-gnueabihf/* $targetdir/usr/local/
sudo cp -v ${DIR}/downloads/setup_7.x $targetdir/opt/Bela/
sudo cp -r ${DIR}/downloads/prudebug $targetdir/opt/
sudo cp -r ${DIR}/downloads/am335x_pru_package $targetdir/opt/
sudo cp -r ${DIR}/downloads/bb.org-overlays $targetdir/opt/
sudo cp -r ${DIR}/downloads/bb.org-dtc $targetdir/opt/

sudo cp -v ${DIR}/systemd/bela_gadget.sh $targetdir/opt/Bela/
sudo cp -v ${DIR}/systemd/bela_init.sh $targetdir/opt/Bela/

sudo cp -v ${DIR}/systemd/bela_gadget.service $targetdir/lib/systemd/system/
sudo cp -v ${DIR}/systemd/bela_init.service $targetdir/lib/systemd/system/
sudo cp -v ${DIR}/systemd/bela_ide.service $targetdir/lib/systemd/system/

# maybe should go in a post-chroot.sh?
sudo cp -v ${DIR}/misc/interfaces $targetdir/etc/network/
sudo cp -v ${DIR}/misc/isc-dhcp-server $targetdir/etc/default/
sudo cp -v ${DIR}/misc/dhcpd.conf $targetdir/etc/dhcp/
sudo cp -v ${DIR}/misc/sudoers.d $targetdir/etc/sudoers.d/bela
