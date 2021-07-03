#!/bin/bash -e

[ -z "$CORES" ] && CORES=1

#echo "~~~~ Updating the packages database ~~~~"
#apt-get update # this is actually done by the node install script below

#echo "~~~~ Installing python packages ~~~~"
#pip install wheel
#pip install enum
#pip install Jinja2

echo "~~~~ Installing node ~~~~"
# install node
/bin/bash /opt/Bela/setup_10.x
# for whatever reason, listing libmicrohttpd-dev in packages.txt fails, so we
# install it here instead
PACKAGES="nodejs libmicrohttpd-dev"
apt-get install -y $PACKAGES

echo "Finish installing xenomai"
libtool --finish /usr/xenomai/lib
# cleanup some un-parseable documentation. man entries are in doc/asciidoc
rm -rf /opt/xenomai-3/doc/prebuilt
rm -rf /opt/xenomai-3/doc/doxygen
# and the huge git repo
rm -rf /opt/xenomai-3/.git
echo "/usr/xenomai/lib" > /etc/ld.so.conf.d/xenomai.conf
echo "/root/Bela/lib" > /etc/ld.so.conf.d/bela.conf
ldconfig

echo "en_GB.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
dpkg-reconfigure --frontend=noninteractive locales
export LANGUAGE="en_GB.UTF-8"
export LANG="en_GB.UTF-8"
export LC_ALL="en_GB.UTF-8"


echo "~~~~ Install .deb files ~~~~"
ls /opt/deb/*deb &> /dev/null && dpkg -i /opt/deb/*deb
rm -rf /opt/deb
ls /root/Bela/resources/stretch/deb/*deb &> /dev/null && dpkg -i /root/Bela/resources/stretch/deb/*deb
ldconfig

echo "~~~~ installing bela kernel ~~~~"
# install the kernel
BELA_KERNEL_VERSION=`cat /root/kernel_version`
mv /root/kernel_version /opt/Bela/

echo ~~~~ image and firmware ~~~~
dpkg -i /root/linux-*image-${BELA_KERNEL_VERSION}*ross_armhf.deb
echo ~~~~ headers ~~~~
dpkg -i /root/linux-headers-${BELA_KERNEL_VERSION}*ross_armhf.deb
#echo ~~~~ libc ~~~~
#dpkg -i /root/linux-libc*ross_armhf.deb
#echo "~~~~ depmod ~~~~"
#depmod "${BELA_KERNEL_VERSION}" -a
rm -rf /root/linux-*.deb
#ensure #include <linux/version.h> returns the same value as `uname -r`. Workaround for https://github.com/RobertCNelson/ti-linux-kernel-dev/issues/38
cp /usr/src/linux-headers-${BELA_KERNEL_VERSION}/include/generated/uapi/linux/version.h /usr/include/linux/version.h

#  rebuild kernel scripts and tools
cd "/lib/modules/${BELA_KERNEL_VERSION}/build"
echo "~~~~ Building kernel headers ~~~~"
cp -r /root/kernel-tools/* arch/arm/tools/
make headers_check -j${CORES}
make headers_install -j${CORES}
make scripts -j${CORES}
rm -rf /root/kernel-tools

# install misc utilities
cd "/opt/am335x_pru_package/"
echo "~~~~ Building PRU utils ~~~~"
make -j${CORES}
make install

# install kernel module
cd "/opt/rtdm_pruss_irq"
echo "~~~~ Building kernel module ~~~~"
make all UNAME=${BELA_KERNEL_VERSION}
make install UNAME=${BELA_KERNEL_VERSION}
make clean UNAME=${BELA_KERNEL_VERSION}

# install seasocks (websocket library)
cd /opt/seasocks
echo "~~~~ Building Seasocks ~~~~"
mkdir build
cd build
cmake .. -DDEFLATE_SUPPORT=OFF -DUNITTESTS=OFF -DSEASOCKS_SHARED=ON
make -j${CORES} seasocks
/usr/bin/cmake -P cmake_install.cmake
cd /root
rm -rf /opt/seasocks/build
ldconfig

echo "~~~~ Installing Bela ~~~~"
cd /root/Bela
for DIR in resources/tools/*; do
	[ -d "$DIR" ] && { make -j${CORES} -C "$DIR" install || exit 1; }
done

make nostartup
make idestartup

mkdir -p /root/Bela/projects
cp -rv /root/Bela/IDE/templates/basic /root/Bela/projects/
make -j${CORES} all PROJECT=basic AT=
make -j${CORES} lib
make -j${CORES} -f Makefile.libraries all
ldconfig

echo "~~~~ building doxygen docs ~~~~"
doxygen > /dev/null 2>&1

cd "/opt/prudebug"
echo "~~~~ Building prudebug ~~~~"
make -j${CORES}
cp -v ./prudebug /usr/bin/

cd "/opt/checkinstall"
echo "~~~~ Building checkinstall ~~~~"
# checkinstall is already installed by deboostrap, but the
# package that ships with Stretch is buggy. We replace the
# library that comes with it with a patched one that we
# compile from source
make -j${CORES}
make install

cd /opt/dtc
echo "~~~~ Building dtc ~~~~"
make clean
make -j${CORES} PREFIX=/usr/local CC=gcc CROSS_COMPILE= EXTRA_CFLAGS=-Wno-sign-compare all
make PREFIX=/usr/local/ install
ln -sf /usr/local/bin/dtc /usr/bin/dtc
echo "dtc: `/usr/bin/dtc --version`"
make clean

cd /opt/bb.org-overlays
echo "~~~~ Building bb.org-overlays ~~~~"
make clean
make -j${CORES}
make install
cp -v ./tools/beaglebone-universal-io/config-pin /usr/local/bin/
make clean

cd /opt/BeagleBoard-DeviceTrees
echo "~~~~ Building device trees ~~~~"
make clean
make -j${CORES}
make install
make clean

echo "~~~~ Setting up distcc shorthands ~~~~"
(
cat << 'HEREDOC'
#!/bin/bash
clang-3.9 $@
HEREDOC
) > /usr/local/bin/clang-3.9-arm
(
cat << 'HEREDOC'
#!/bin/bash
clang++-3.9 $@ -stdlib=libstdc++
HEREDOC
) > /usr/local/bin/clang++-3.9-arm
(
cat << 'HEREDOC'
#!/bin/bash
export DISTCC_HOSTS=192.168.7.1
export DISTCC_VERBOSE=0
export DISTCC_FALLBACK=0 # does not work on distcc-3.1
export DISTCC_BACKOFF_PERIOD=0
distcc clang-3.9-arm $@
HEREDOC
) > /usr/local/bin/distcc-clang
(
cat << 'HEREDOC'
#!/bin/bash
export DISTCC_HOSTS=192.168.7.1
export DISTCC_VERBOSE=0
export DISTCC_FALLBACK=0 # does not work on distcc-3.1
export DISTCC_BACKOFF_PERIOD=0
distcc clang++-3.9-arm $@
HEREDOC
) > /usr/local/bin/distcc-clang++
chmod +x /usr/local/bin/clang*-3.9-arm /usr/local/bin/distcc-clang*

# clear root password
passwd -d root

# set hostname
echo bela > /etc/hostname

# systemd configuration
systemctl enable bela_gadget
systemctl enable bela_button
systemctl enable serial-getty@ttyGS0.service
systemctl enable ssh_shutdown
systemctl enable dhclient_shutdown
systemctl enable bela_shutdown

# don't do any network access in the chroot after this call
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# clean the package cache to free up space on the image
apt-get clean
