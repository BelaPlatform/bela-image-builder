#!/bin/bash -e

CORES=$(getconf _NPROCESSORS_ONLN)

echo "~~~~ Updating the packages database ~~~~"
apt-get update

#uncomment till set+x to debug ldconfig
#set +e
#set -x 
#grep xenomai /etc/ld.so.cache
echo "Finish installing xenomai"
libtool --finish /usr/xenomai/lib
#grep xenomai /etc/ld.so.cache
echo "/usr/xenomai/lib" > /etc/ld.so.conf.d/xenomai.conf
echo "/root/Bela/lib" > /etc/ld.so.conf.d/bela.conf
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


echo "~~~~ Install .deb files ~~~~"
cd /opt/deb
dpkg -i *deb
rm -rf /opt/deb
dpkg -i /root/Bela/resources/stretch/deb/*deb
ldconfig

echo "~~~~ installing bela kernel ~~~~"
# install the kernel
BELA_KERNEL_VERSION=`cat /root/kernel_version`
mv /root/kernel_version /opt/Bela/

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
rm -rf /root/*.deb

# install kernel headers
cd "/lib/modules/${BELA_KERNEL_VERSION}/build"
echo "~~~~ Building kernel headers ~~~~"
make headers_check
make headers_install
make scripts

# install misc utilities
cd "/opt/am335x_pru_package/"
echo "~~~~ Building PRU utils ~~~~"
make -j${CORES}
make install

# install kernel module
cd "/opt/rtdm_pruss_irq"
echo "~~~~ Building kernel module ~~~~"
make all UNAME=${BELA_KERNEL_VERSION}
make install UNAME=${BELA_KERNEL_VERSION}
make clean UNAME=${BELA_KERNEL_VERSION}

# install seasocks (websocket library)
cd /opt/seasocks
echo "~~~~ Building Seasocks ~~~~"
mkdir build
cd build
cmake .. -DDEFLATE_SUPPORT=OFF -DUNITTESTS=OFF
make seasocks seasocks_so
/usr/bin/cmake -P cmake_install.cmake
cd /root
rm -rf /opt/seasocks/build
ldconfig
echo "~~~~ Setting-up clang ~~~~"
# Make 3.9 default
update-alternatives --install /usr/bin/clang++ clang++ `which clang++-3.9` 100
update-alternatives --install /usr/bin/clang clang `which clang-3.9` 100

echo "~~~~ Installing Bela ~~~~"
# install bela
cd /root/Bela
make -C resources/tools/bela-cape-btn install
make nostartup
make idestartup
mkdir -p /root/Bela/projects
cp -rv /root/Bela/IDE/templates/basic /root/Bela/projects/
make -j${CORES} all PROJECT=basic AT=
make -j${CORES} lib
ldconfig

cp -v /root/Bela/resources/stretch/dtb/BELA-00A0.dtbo /lib/firmware/
echo "~~~~ building doxygen docs ~~~~"
doxygen > /dev/null 2>&1

# install node
/bin/bash /opt/Bela/setup_7.x
apt-get install -y nodejs

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

cd /opt/dtb-rebuilder
echo "~~~~ Building Bela dtb ~~~~"
make clean
make src/arm/am335x-bone-bela.dtb
cp -v src/arm/am335x-bone-bela.dtb /opt/Bela/
make src/arm/am335x-bone-bela-black-wireless.dtb
cp -v src/arm/am335x-bone-bela-black-wireless.dtb /opt/Bela/
make clean

# clear root password
passwd -d root

# set hostname
echo bela > /etc/hostname

# systemd configuration
systemctl enable bela_gadget
systemctl enable bela_button
systemctl enable serial-getty@ttyGS0.service
systemctl enable ssh_shutdown
systemctl enable dhclient_shutdown
systemctl enable bela_shutdown

# don't do any network access in the chroot after this call
echo "nameserver 8.8.8.8" > /etc/resolv.conf
