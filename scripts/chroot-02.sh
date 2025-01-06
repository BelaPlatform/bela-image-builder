#!/bin/bash -eu
set -x
[ -z "$CORES" ] && CORES=1
export LANGUAGE="en_GB.UTF-8"
export LANG="en_GB.UTF-8"
export LC_ALL="en_GB.UTF-8"
BELA_KERNEL_VERSION=`cat /opt/Bela/kernel_version`

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
cmake .. -DDEFLATE_SUPPORT=OFF -DUNITTESTS=OFF -DSEASOCKS_SHARED=ON
make -j${CORES} seasocks
/usr/bin/cmake -P cmake_install.cmake
cd /root
rm -rf /opt/seasocks/build
ldconfig

cd "/opt/prudebug"
echo "~~~~ Building prudebug ~~~~"
make -j${CORES}
cp -v ./prudebug /usr/bin/

cd /opt/bb.org-overlays
echo "~~~~ Building bb.org-overlays ~~~~"
make clean
make -j${CORES}
make install
cp -v ./tools/beaglebone-universal-io/config-pin /usr/local/bin/
make clean

cd /opt/BeagleBoard-DeviceTrees
echo "~~~~ Building Bela dtb ~~~~"
make clean
make -j${CORES} KERNEL_VERSION=${BELA_KERNEL_VERSION}
make install
make clean

