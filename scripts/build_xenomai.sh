#!/bin/bash -e
[ -z "$DIR" ] && DIR=$PWD
[ -z "$CORES" ] && CORES=$(getconf _NPROCESSORS_ONLN)
[ -z "$CC" ] && { echo "build_bootloader.sh: you should specify a cross compiler in \$CC" >& 2; exit 1; }


# cross-compile xenomai
CC=${CC}gcc
echo "~~~~ cross-compiling xenomai  ~~~~"
cd "${DIR}/downloads/xenomai-3"
scripts/bootstrap
./configure --with-core=cobalt --enable-smp --enable-pshared --host=arm-linux-gnueabihf --build=arm CFLAGS="-march=armv7-a -mfpu=vfp3"
make -j${CORES}
