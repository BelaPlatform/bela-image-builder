#!/bin/bash -e

# this script downloads, builds and compiles an image (including kernel, bootloader and rootfs) for Bela

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

DEPENDENCIES="debootstrap qemu-arm-static autoreconf libtool arm-linux-gnueabihf-ranlib kpartx"

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
targetdir_pre_chroot_backup=${DIR}/pre_chroot_backup/rootfs
export targetdir

usage(){
	echo "--no-downloads --no-kernel --no-rootfs --cached-fs --do-not-cache-fs --no-bootloader --no-build-xenomai"
}

# parse commandline options
unset NO_DOWNLOADS
unset NO_KERNEL
unset NO_ROOTFS
unset NO_BOOTLOADER
unset CACHED_FS
unset NO_BUILD_XENOMAI
unset DO_NOT_CACHE_FS
export CORES=$(getconf _NPROCESSORS_ONLN)

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
	--no-build-xenomai)
		NO_BUILD_XENOMAI=true
		;;
	--cached-fs)
		CACHED_FS=true
		;;
	--do-not-cache-fs)
		DO_NOT_CACHE_FS=true
		;;
	*)
		echo "Unknown option $1" >&2
		usage
		exit 1
	esac
	shift
done

# download / clone latest versions of things we need
if [ -f ${NO_DOWNLOADS} ] ; then
	${DIR}/scripts/downloads.sh
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

if [ -f ${NO_DOWNLOADS} ]; then
	# if we are doing downloads, and the kernel is ok then we have the cross compiler selected
	# so we build xenomai
	if [ -f ${NO_BUILD_XENOMAI} ] ; then
	# cross-compile xenomai
		echo "~~~~ cross-compiling xenomai  ~~~~"
		cd "${DIR}/downloads/xenomai-3"
		scripts/bootstrap
		./configure --with-core=cobalt --enable-smp --enable-pshared --host=arm-linux-gnueabihf --build=arm CFLAGS="-march=armv7-a -mfpu=vfp3"
		make -j${CORES}
	fi
fi

# build the rootfs
if [ -f ${NO_ROOTFS} ] ; then
	echo "~~~~ building debian stretch rootfs ~~~~"
	sudo rm -rf $targetdir
	if [ -z "${CACHED_FS}" ] ; then
		mkdir -p $targetdir
		mkdir $targetdir/root
		DEB_PACKAGES=`tr "\n" "," < ${DIR}/packages.txt | sed '$ s/.$//'`
		sudo debootstrap --arch=armhf --foreign --components=main,free,non-free --include=${DEB_PACKAGES} stretch $targetdir
		sudo cp /usr/bin/qemu-arm-static $targetdir/usr/bin/
		sudo cp /etc/resolv.conf $targetdir/etc
		sudo chroot $targetdir debootstrap/debootstrap --second-stage
		if [ "${DO_NOT_CACHE_FS}" != "true" ] ; then
			echo "Backing up the pre-chroot rootfs int o $targetdir_pre_chroot_backup"
			rm -rf $targetdir_pre_chroot_backup
			sudo cp -ar $targetdir $targetdir_pre_chroot_backup
		fi
	else
		echo "Using backup pre-chroot rootfs from $targetdir_pre_chroot_backup"
		sudo cp -ar $targetdir_pre_chroot_backup $targetdir
	fi
	${DIR}/scripts/pre-chroot.sh


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
	make -j${CORES} ARCH=arm CROSS_COMPILE=${CC} distclean
	make -j${CORES} ARCH=arm CROSS_COMPILE=${CC} am335x_evm_defconfig
	make -j${CORES} ARCH=arm CROSS_COMPILE=${CC}
	cp -v MLO ${DIR}/boot/
	cp -v u-boot.img ${DIR}/boot/
	git reset --hard
	git checkout master
	git branch -d tmp
	git clean -fd
fi

# create SD image
if [ -f ${NO_IMG} ] ; then
	${DIR}/scripts/create_img.sh
fi
