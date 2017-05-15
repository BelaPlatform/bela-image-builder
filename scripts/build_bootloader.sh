#!/bin/bash -e
[ -z "$DIR" ] && DIR=$PWD
[ -z "$CORES" ] && CORES=$(getconf _NPROCESSORS_ONLN)
[ -z "$CC" ] && { echo "build_bootloader.sh: you should specify a cross compiler in \$CC" >& 2; exit 1; }

echo "~~~~ compiling bootloader ~~~~"
cd ${DIR}/downloads/u-boot
git checkout v2017.03 -b tmp
wget -c https://rcn-ee.com/repos/git/u-boot-patches/v2017.03/0001-am335x_evm-uEnv.txt-bootz-n-fixes.patch
wget -c https://rcn-ee.com/repos/git/u-boot-patches/v2017.03/0002-U-Boot-BeagleBone-Cape-Manager.patch
echo patch 1--------------------
patch -p1 < 0001-am335x_evm-uEnv.txt-bootz-n-fixes.patch
echo patch 2--------------------
patch -p1 < 0002-U-Boot-BeagleBone-Cape-Manager.patch
make -j${CORES} ARCH=arm CROSS_COMPILE=${CC} distclean
make -j${CORES} ARCH=arm CROSS_COMPILE=${CC} am335x_evm_defconfig
make -j${CORES} ARCH=arm CROSS_COMPILE=${CC}
cp -v MLO ${DIR}/boot/
cp -v u-boot.img ${DIR}/boot/
git reset --hard
git checkout master
git branch -d tmp
git clean -fd

