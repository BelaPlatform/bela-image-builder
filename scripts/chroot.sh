#!/bin/bash -e

CORES=$(getconf _NPROCESSORS_ONLN)

#uncomment till set+x to debug ldconfig
#set +e
#set -x 
#grep xenomai /etc/ld.so.cache
echo "Finish installing xenomai"
libtool --finish /usr/xenomai/lib
#grep xenomai /etc/ld.so.cache
echo "/usr/xenomai/lib" > /etc/ld.so.conf.d/xenomai.conf
ldconfig
#grep xenomai /etc/ld.so.cache
#set -e
#set +x

echo "en_GB.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
dpkg-reconfigure --frontend=noninteractive locales
export LANGUAGE="en_GB.UTF-8"
export LANG="en_GB.UTF-8"
export LC_ALL="en_GB.UTF-8"

# install the kernel
BELA_KERNEL_VERSION=`cat /root/kernel_version`
mv /root/kernel_version /opt/Bela/

echo "~~~~ installing bela kernel ~~~~"
dpkg -i "/root/linux-image-${BELA_KERNEL_VERSION}_1cross_armhf.deb"
rm -rf "/root/linux-image-${BELA_KERNEL_VERSION}_1cross_armhf.deb"
echo "~~~~ firmware ~~~~"
dpkg -i "/root/linux-firmware-image-${BELA_KERNEL_VERSION}_1cross_armhf.deb"
rm -rf "/root/linux-firmware-image-${BELA_KERNEL_VERSION}_1cross_armhf.deb"
echo "~~~~ headers ~~~~"
dpkg -i "/root/linux-headers-${BELA_KERNEL_VERSION}_1cross_armhf.deb"
rm -rf "/root/linux-headers-${BELA_KERNEL_VERSION}_1cross_armhf.deb"
#echo "~~~~ libc ~~~~"
#dpkg -i "/root/linux-libc-dev_1cross_armhf.deb"
rm -rf "/root/linux-libc-dev_1cross_armhf.deb"
#echo "~~~~ depmod ~~~~"
#depmod "${BELA_KERNEL_VERSION}" -a


# install bela
cd /root/Bela
make nostartup
make idestartup
make -j${CORES} all PROJECT=basic AT=
cp -v /root/Bela/resources/BELA-00A0.dtbo /lib/firmware/
echo "~~~~ building doxygen docs ~~~~"
doxygen > /dev/null 2>&1

# install node
/bin/bash /opt/Bela/setup_7.x
apt-get install -y nodejs

# install misc utilities
cd "/opt/am335x_pru_package/"
echo "~~~~ Building PRU utils ~~~~"
make -j${CORES}
make install

cd "/opt/prudebug"
echo "~~~~ Building prudebug ~~~~"
make -j${CORES}
cp -v ./prudebug /usr/bin/

cd /opt/bb.org-dtc
echo "~~~~ Building bb.org-dtc ~~~~"
make clean
make -j${CORES} PREFIX=/usr/local CC=gcc CROSS_COMPILE= all
make PREFIX=/usr/local/ install
ln -sf /usr/local/bin/dtc /usr/bin/dtc
echo "dtc: `/usr/bin/dtc --version`"
make clean

cd /opt/bb.org-overlays
echo "~~~~ Building bb.org-overlays ~~~~"
make clean
make -j${CORES}
make install
cp -v ./tools/beaglebone-universal-io/config-pin /usr/local/bin/
make clean

# clear root password
passwd -d root

# add bela user
adduser bela --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password
echo "bela:a" | chpasswd
#chown root:root /usr/bin/sudo
#chmod 4755 /usr/bin/sudo
chown bela /home/bela
chown root:root /etc/sudoers.d/bela

# set hostname
echo bela > /etc/hostname

# systemd configuration
systemctl enable bela_gadget
systemctl enable bela_init
systemctl enable serial-getty@ttyGS0.service
systemctl enable ssh_shutdown

# don't do any network access in the chroot after this call
echo "nameserver 8.8.8.8" > /etc/resolv.conf
