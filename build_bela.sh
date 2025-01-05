#!/bin/bash -e

# this script downloads, builds and compiles an image (including kernel, bootloader and rootfs) for Bela

DEPENDENCIES="debootstrap qemu-arm-static autoreconf libtool arm-linux-gnueabihf-ranlib kpartx setuidgid wget bison flex pkg-config arm-linux-gnueabihf-gcc"
# set up qemu appropriately
update-binfmts --install arm /usr/bin/qemu-arm-static --magic '\x7fELF\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x28\x00' --mask '\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff'

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
export targetdir

usage(){
	echo "--no-downloads --no-kernel --fast-kernel --no-rootfs --cached-fs <first-stage> --do-not-cache-fs --no-bootloader --no-build-xenomai --emmc-flasher --clean"
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
unset NO_BUILD_XENOMAI
unset DO_NOT_CACHE_FS
unset EMMC_FLASHER
export CORES=$(getconf _NPROCESSORS_ONLN)
CACHED_FS=-100000

[ -f $DIR/config ] && . $DIR/config || {
	echo Error: \`$DIR/config\` was not found. Use \`$DIR/config.template\` as a starting point. >&2
	exit 1;
}

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
		CACHED_FS=$2
		shift
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

export UNSU="runuser -u $SUDO_USER --"
# download / clone latest versions of things we need
if [ -f ${NO_DOWNLOADS} ] ; then
	$UNSU ${DIR}/scripts/downloads.sh
fi

# compile the kernel
if [ -f ${NO_KERNEL} ] ; then
	export FAST_KERNEL
	$UNSU ${DIR}/scripts/build_kernel.sh
fi

# this is normally from `config`
export CC

if [ -f ${NO_BUILD_XENOMAI} ] ; then
	$UNSU ${DIR}/scripts/build_xenomai.sh
fi

# compile and patch u-boot
if [ -f ${NO_BOOTLOADER} ] ; then
	$UNSU ${DIR}/scripts/build_bootloader.sh
fi

function backup_path(){
	echo ${DIR}/rootfs_backup_$1
}

function backup_rootfs (){
	local stage=$1
	local path=$(backup_path $stage)
	echo "Backing up the rootfs at stage $stage into $path"
	rm -rf $path
	mkdir -p $path
	sudo cp -ar $targetdir $path
}
function use_backup_rootfs () {
	local stage=$1
	echo "Using backup rootfs for stage $stage"
	sudo cp -ar $(backup_path $stage)/rootfs $targetdir
}

# build the rootfs
if [ -f ${NO_ROOTFS} ] ; then
	echo "~~~~ building debian rootfs ~~~~"
	stage=-2
	rm -rf $targetdir
	if [ $CACHED_FS -lt $stage ]; then
		mkdir -p $targetdir
		mkdir $targetdir/root
		DEB_PACKAGES=`tr "\n" "," < ${DIR}/packages.txt | sed '$ s/.$//'`
		sudo debootstrap --arch=armhf --foreign --components=main,free,non-free,non-free-firmware --include=${DEB_PACKAGES} bookworm $targetdir
		sudo cp /usr/bin/qemu-arm-static $targetdir/usr/bin/
		sudo cp /etc/resolv.conf $targetdir/etc
		sudo chroot $targetdir debootstrap/debootstrap --second-stage
		backup_rootfs $stage
	elif [ $CACHED_FS -eq $stage ]; then
		use_backup_rootfs $stage
	fi

	stage=-1
	if [ $CACHED_FS -lt $stage ]; then
		${DIR}/scripts/pre-chroot.sh
		sudo mkdir -p $targetdir/sys
		sudo mkdir -p $targetdir/proc
		backup_rootfs $stage
	elif [ $CACHED_FS -eq $stage ]; then
		use_backup_rootfs $stage
	fi

	for a in scripts/chroot-*.sh; do
		stage=$(echo $a | sed "s/.*chroot-\([0-9]\+\)\.sh/\1/")
		echo STAGE IS $stage
		if [ $CACHED_FS -lt $stage ]; then
			sudo cp -v ${DIR}/$a $targetdir/
			sudo CORES=$CORES chroot $targetdir/ ./$(basename $a)
			backup_rootfs $stage
		elif [ $CACHED_FS -eq $stage ]; then
			use_backup_rootfs $stage
		fi
	done
fi
sudo rm -rf $targetdir/chroot-*.sh

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
