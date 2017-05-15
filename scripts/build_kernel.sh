#!/bin/bash -e
[ -z "$DIR" ] && DIR=$PWD

echo "~~~~ compiling bela kernel  ~~~~"
cp -v ${DIR}/kernel/bela_defconfig ${DIR}/downloads/ti-linux-kernel-dev/patches/defconfig
cd ${DIR}/downloads/ti-linux-kernel-dev/
AUTO_BUILD=1
export AUTO_BUILD
./tools/rebuild_deb.sh
cp -v ${DIR}/downloads/ti-linux-kernel-dev/deploy/*.deb ${DIR}/kernel/
cp -v ${DIR}/downloads/ti-linux-kernel-dev/kernel_version ${DIR}/kernel/

