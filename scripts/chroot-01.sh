#!/bin/bash -e
set -x
[ -z "$CORES" ] && CORES=1
export LANGUAGE="en_GB.UTF-8"
export LANG="en_GB.UTF-8"
export LC_ALL="en_GB.UTF-8"

echo "~~~~ Install .deb files ~~~~"
ls /opt/deb/*deb &> /dev/null && dpkg -i /opt/deb/*deb
rm -rf /opt/deb
ldconfig

echo "~~~~ installing bela kernel ~~~~"
# install the kernel
BELA_KERNEL_VERSION=`cat /root/kernel_version`
mv /root/kernel_version /opt/Bela/

echo ~~~~ image and firmware ~~~~
dpkg -i /root/linux-*image-${BELA_KERNEL_VERSION}*ross_armhf.deb

echo ~~~~ headers ~~~~
ls /root/
dpkg -i /root/linux-headers-${BELA_KERNEL_VERSION}*ross_armhf.deb
#echo ~~~~ libc ~~~~
#dpkg -i /root/linux-libc*ross_armhf.deb
echo "~~~~ depmod ~~~~"
depmod "${BELA_KERNEL_VERSION}" -a
rm -rf /root/linux-*.deb
#ensure #include <linux/version.h> returns the same value as `uname -r`. Workaround for https://github.com/RobertCNelson/ti-linux-kernel-dev/issues/38
cp /usr/src/linux-headers-${BELA_KERNEL_VERSION}/include/generated/uapi/linux/version.h /usr/include/linux/version.h

# rebuild kernel scripts and tools
cd "/lib/modules/${BELA_KERNEL_VERSION}/build"
echo "~~~~ Building kernel headers ~~~~"
mkdir -p arch/arm/tools
cp -r /root/kernel-tools/* arch/arm/tools
make headers_check -j${CORES}
make headers_install -j${CORES}
make scripts -j${CORES}
rm -rf /root/kernel-tools
