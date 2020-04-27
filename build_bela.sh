#!/bin/bash -e

# this script downloads, builds and compiles an image (including kernel, bootloader and rootfs) for Bela

DEPENDENCIES="debootstrap qemu-arm-static autoreconf libtool arm-linux-gnueabihf-ranlib kpartx setuidgid wget bison flex pkg-config"

for a in $DEPENDENCIES; do
	which $a > /dev/null ||\
	{
		echo "Dependency check failed: you should install \`$a' before continuing"
		exit 1
	}
done

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Using full path as it is required by `make install` for xenomai-3
DIR=`pwd`/$(dirname "$0")
export DIR
targetdir=${DIR}/rootfs
targetdir_pre_chroot_backup=${DIR}/pre_chroot_backup
export targetdir

usage(){
	echo "--no-downloads --no-kernel --fast-kernel --no-rootfs --cached-fs --do-not-cache-fs --no-bootloader --no-build-xenomai --emmc-flasher --clean"
}

clean_all()
{
	rm -rf rootfs pre_chroot_backup downloads
	git clean -fx
}

# parse commandline options
unset NO_DOWNLOADS
unset NO_KERNEL
unset FAST_KERNEL
unset NO_ROOTFS
unset NO_BOOTLOADER
unset CACHED_FS
unset NO_BUILD_XENOMAI
unset DO_NOT_CACHE_FS
unset EMMC_FLASHER
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
	--fast-kernel)
		FAST_KERNEL=true
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
	--clean)
		clean_all
		;;
	--emmc-flasher)
		EMMC_FLASHER=true
		;;
	*)
		echo "Unknown option $1" >&2
		usage
		exit 1
	esac
	shift
done

export UNSU="setuidgid $SUDO_USER"
# download / clone latest versions of things we need
if [ -f ${NO_DOWNLOADS} ] ; then
	$UNSU ${DIR}/scripts/downloads.sh
fi

# compile the kernel
if [ -f ${NO_KERNEL} ] ; then
	export FAST_KERNEL
	$UNSU ${DIR}/scripts/build_kernel.sh
fi

# grab the kernel's cross-compiler
. ${DIR}/downloads/ti-linux-kernel-dev/.CC
PATH=$PATH:`dirname $CC`
CC=${CC}
export CC PATH

if [ -f ${NO_BUILD_XENOMAI} ] ; then
	$UNSU ${DIR}/scripts/build_xenomai.sh
fi

# build the rootfs
if [ -f ${NO_ROOTFS} ] ; then
	echo "~~~~ building debian bullseye rootfs ~~~~"
	rm -rf $targetdir
	if [ -z "${CACHED_FS}" ] ; then
		mkdir -p $targetdir
		mkdir $targetdir/root
		DEB_PACKAGES=`tr "\n" "," < ${DIR}/packages.txt | sed '$ s/.$//'`
		sudo debootstrap --arch=armhf --foreign --components=main,free,non-free --include=${DEB_PACKAGES} bullseye $targetdir
		sudo cp /usr/bin/qemu-arm-static $targetdir/usr/bin/
		sudo cp /etc/resolv.conf $targetdir/etc
		sudo chroot $targetdir debootstrap/debootstrap --second-stage
		if [ "${DO_NOT_CACHE_FS}" != "true" ] ; then
			echo "Backing up the pre-chroot rootfs into $targetdir_pre_chroot_backup"
			rm -rf $targetdir_pre_chroot_backup
			mkdir -p $targetdir_pre_chroot_backup
			sudo cp -ar $targetdir $targetdir_pre_chroot_backup
		fi
	else
		echo "Using backup pre-chroot rootfs from $targetdir_pre_chroot_backup"
		sudo cp -ar $targetdir_pre_chroot_backup/rootfs $targetdir
	fi
	${DIR}/scripts/pre-chroot.sh


	sudo cp -v ${DIR}/scripts/chroot.sh $targetdir/
	sudo CORES=$CORES chroot $targetdir/ /chroot.sh
	sudo mkdir -p $targetdir/sys
	sudo mkdir -p $targetdir/proc
	sudo rm $targetdir/usr/bin/qemu-arm-static
	sudo rm $targetdir/chroot.sh
fi

# compile and patch u-boot
if [ -f ${NO_BOOTLOADER} ] ; then
	$UNSU ${DIR}/scripts/build_bootloader.sh
fi

if [ -n "${EMMC_FLASHER}" ] ; then
	sudo cp /usr/bin/qemu-arm-static $targetdir/usr/bin/
	sudo cp -v ${DIR}/scripts/emmc-flasher-chroot.sh $targetdir/
	sudo chroot $targetdir/ /emmc-flasher-chroot.sh
	sudo rm $targetdir/emmc-flasher-chroot.sh
	sudo rm $targetdir/usr/bin/qemu-arm-static
fi

# something (at least `pip install` does it) may have found a way to create
#   /home/$SUDO_USER . Let's undo that
sudo rm -rf $targetdir/home/$SUDO_USER

# create SD image
if [ -f ${NO_IMG} ] ; then
	${DIR}/scripts/create_img.sh
fi
