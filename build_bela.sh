#!/bin/bash -e

# this script downloads, builds and compiles an image (including kernel, bootloader and rootfs) for Bela

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

DEPENDENCIES="debootstrap qemu-arm-static"

for a in $DEPENDENCIES; do
	which $a > /dev/null ||\
	{
		echo "Dependency check failed: you should install \`$a' before continuing"
		exit 1
	}
done

DIR=`pwd`
export DIR
targetdir=${DIR}/rootfs
export targetdir

usage(){
	echo "--no-downloads --no-kernel --no-rootfs --cached-fs=path --no-bootloader"
}

# parse commandline options
unset NO_DOWNLOADS
unset NO_KERNEL
unset NO_ROOTFS
unset NO_BOOTLOADER
unset CACHED_FS
while [ ! -z "$1" ] ; do
	case $1 in
	-h|--help)
		usage
		exit
		;;
	--no-downloads)
		NO_DOWNLOADS=true
		;;
	--no-kernel)
		NO_KERNEL=true
		;;
	--no-rootfs)
		NO_ROOTFS=true
		;;
	--no-bootloader)
		NO_BOOTLOADER=true
		;;
	--cached-fs)
		CACHED_FS=true
		sudo rm -rf rootfs
		sudo cp -ar c_rootfs rootfs
		;;
	esac
	shift
done

# download / clone latest versions of things we need
if [ -f ${NO_DOWNLOADS} ] ; then
	/bin/bash -e ${DIR}/scripts/downloads.sh
fi

# compile the kernel
if [ -f ${NO_KERNEL} ] ; then
	echo "~~~~ compiling bela kernel  ~~~~"
	cp -v ${DIR}/kernel/bela_defconfig ${DIR}/downloads/ti-linux-kernel-dev/patches/defconfig
	cd ${DIR}/downloads/ti-linux-kernel-dev/
	AUTO_BUILD=1
	export AUTO_BUILD
	/bin/bash build_deb.sh
	cp -v ${DIR}/downloads/ti-linux-kernel-dev/deploy/*.deb ${DIR}/kernel/
	cp -v ${DIR}/downloads/ti-linux-kernel-dev/kernel_version ${DIR}/kernel/
fi

# grab the kernel's cross-compiler
. ${DIR}/downloads/ti-linux-kernel-dev/.CC
PATH=$PATH:`dirname $CC`

# build the rootfs
if [ -f ${NO_ROOTFS} ] ; then
	echo "~~~~ building debian stretch rootfs ~~~~"
	if [ -f ${CACHED_FS} ] ; then
		sudo rm -rf $targetdir
		mkdir -p $targetdir
		DEB_PACKAGES=`tr "\n" "," < ${DIR}/packages.txt | sed '$ s/.$//'`
		sudo debootstrap --arch=armhf --foreign --include=${DEB_PACKAGES} stretch $targetdir
		sudo cp /usr/bin/qemu-arm-static $targetdir/usr/bin/
		sudo cp /etc/resolv.conf $targetdir/etc
		sudo chroot $targetdir debootstrap/debootstrap --second-stage
	fi
	/bin/bash ${DIR}/scripts/pre-chroot.sh

	# cross-compile xenomai
	echo "~~~~ cross-compiling xenomai  ~~~~"
	cd "${DIR}/downloads/xenomai-3"
	/bin/bash scripts/bootstrap
	./configure --with-core=cobalt --enable-smp --enable-pshared --host=arm-linux-gnueabihf --build=arm CFLAGS="-march=armv7-a -mfpu=vfp3"
	make
	sudo make DESTDIR=${targetdir} install

	sudo cp -v ${DIR}/scripts/chroot.sh $targetdir/
	sudo chroot $targetdir/ /chroot.sh 
	sudo mkdir -p $targetdir/sys
	sudo mkdir -p $targetdir/proc
	sudo rm $targetdir/usr/bin/qemu-arm-static
	sudo rm $targetdir/chroot.sh
fi

# compile and patch u-boot
if [ -f ${NO_BOOTLOADER} ] ; then
	echo "~~~~ compiling bootloader ~~~~"
	cd ${DIR}/downloads/u-boot
	git checkout v2017.03 -b tmp
	wget -c https://rcn-ee.com/repos/git/u-boot-patches/v2017.03/0001-am335x_evm-uEnv.txt-bootz-n-fixes.patch
	wget -c https://rcn-ee.com/repos/git/u-boot-patches/v2017.03/0002-U-Boot-BeagleBone-Cape-Manager.patch
	patch -p1 < 0001-am335x_evm-uEnv.txt-bootz-n-fixes.patch
	patch -p1 < 0002-U-Boot-BeagleBone-Cape-Manager.patch
	make ARCH=arm CROSS_COMPILE=${CC} distclean
	make ARCH=arm CROSS_COMPILE=${CC} am335x_evm_defconfig
	make ARCH=arm CROSS_COMPILE=${CC}
	cp -v MLO ${DIR}/boot/
	cp -v u-boot.img ${DIR}/boot/
	git reset --hard
	git checkout master
	git branch -d tmp
	git clean -fd
fi

# create SD image
if [ -f ${NO_IMG} ] ; then
	/bin/bash ${DIR}/scripts/create_img.sh
fi
