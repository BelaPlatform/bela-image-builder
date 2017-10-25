#!/bin/bash -e
[ -z "$DIR" ] && { echo "undefined variable: \$DIR"; exit 1; }
[ -z "$FAST_KERNEL" ] && FAST_KERNEL=no

echo "~~~~ compiling bela kernel  ~~~~"
cp -v ${DIR}/kernel/bela_defconfig ${DIR}/downloads/ti-linux-kernel-dev/patches/defconfig
cd ${DIR}/downloads/ti-linux-kernel-dev/
AUTO_BUILD=1
export AUTO_BUILD

if [ -d "KERNEL" -a "$FAST_KERNEL" = true ]; then
	# assume the kernel is already init'ed, so do the "quick" build
	echo Building kernel with tools/rebuild_deb.sh
	./tools/rebuild_deb.sh
else
	# init: download and patch the kernel and build it
	echo Building kernel with ./build_deb.sh
	./build_deb.sh
fi
cp -v ${DIR}/downloads/ti-linux-kernel-dev/deploy/*.deb ${DIR}/kernel/
cp -v ${DIR}/downloads/ti-linux-kernel-dev/kernel_version ${DIR}/kernel/

