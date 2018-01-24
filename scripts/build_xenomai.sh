#!/bin/bash -e
[ -z "$DIR" ] && { echo "undefined variable: \$DIR"; exit 1; }
[ -z "$CORES" ] && CORES=$(getconf _NPROCESSORS_ONLN)
[ -z "$CC" ] && { echo "build_xenomai.sh: you should specify a cross compiler in \$CC" >& 2; exit 1; }

XENO_BUILD=${DIR}/downloads/xenomai-3-build

# cross-compile xenomai
CC=${CC}gcc
echo "~~~~ cross-compiling xenomai  ~~~~"
cd "${DIR}/downloads/xenomai-3"
scripts/bootstrap
rm -rf $XENO_BUILD
mkdir -p $XENO_BUILD
cd $XENO_BUILD
../xenomai-3/configure --with-core=cobalt --enable-pshared --host=arm-linux-gnueabihf --build=arm CFLAGS="-march=armv7-a -mfpu=vfp3" --enable-dlopen-libs
make -j${CORES}
