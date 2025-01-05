#!/bin/bash -e
set -x

[ -z "$CORES" ] && CORES=1

#echo "~~~~ Updating the packages database ~~~~"
#apt-get update # this is actually done by the node install script below

#echo "~~~~ Installing python packages ~~~~"
#pip install wheel
#pip install enum
#pip install Jinja2

echo "~~~~ Installing node ~~~~"
# install node
/bin/bash /opt/Bela/setup_22.x
# some packages make deboostrap fail, so we install them here instead
PACKAGES="
nodejs
libmicrohttpd-dev
gdb
gettext
avahi-daemon
lsb-release
"

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

