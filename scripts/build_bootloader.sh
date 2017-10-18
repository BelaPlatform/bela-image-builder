#!/bin/bash -e
[ -z "$DIR" ] && DIR=$PWD
[ -z "$CORES" ] && CORES=$(getconf _NPROCESSORS_ONLN)
[ -z "$CC" ] && { echo "build_bootloader.sh: you should specify a cross compiler in \$CC" >& 2; exit 1; }

echo "~~~~ compiling bootloader ~~~~"
cd ${DIR}/downloads/u-boot
git checkout v2017.03
git branch -D tmp
git checkout v2017.03 -b tmp
git clean -f
cp -v ${DIR}/boot/bela_uboot_config.patch ./
cp -v ${DIR}/boot/bela_uboot_bootcmd.patch ./
git apply bela_uboot_config.patch
git apply bela_uboot_bootcmd.patch
make -j${CORES} ARCH=arm CROSS_COMPILE=${CC} distclean
make -j${CORES} ARCH=arm CROSS_COMPILE=${CC} am335x_evm_defconfig
make -j${CORES} ARCH=arm CROSS_COMPILE=${CC}
cp -v MLO ${DIR}/boot/
cp -v u-boot.img ${DIR}/boot/
git reset --hard
git checkout master
git branch -d tmp
git clean -fd

