#!/bin/bash -xe
[ -z "$DIR" ] && { echo "undefined variable: \$DIR"; exit 1; }
[ -z "$CORES" ] && CORES=$(getconf _NPROCESSORS_ONLN)

echo "~~~~ compiling bootloader ~~~~"
cd $DIR/downloads/Bootloader-Builder
./build.sh
cp -v deploy/am335x_evm/MLO $DIR/boot/
cp -v deploy/am335x_evm/u-boot.img $DIR/boot/
