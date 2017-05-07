rm -rf rootfs
mkdir -p rootfs
sudo debootstrap --arch=armhf --foreign sid rootfs/
