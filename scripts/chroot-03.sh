#!/bin/bash -eu
set -x
[ -z "$CORES" ] && CORES=1
export LANGUAGE="en_GB.UTF-8"
export LANG="en_GB.UTF-8"
export LC_ALL="en_GB.UTF-8"
BELA_KERNEL_VERSION=`cat /opt/Bela/kernel_version`

echo "~~~~ Installing Bela ~~~~"
codename=$(lsb_release -c | awk '{ printf $2 }')
ls /root/Bela/resources/$codename/deb/*deb &> /dev/null && dpkg -i /root/Bela/resources/$codename/deb/*deb
ldconfig
cd /root/Bela
for DIR in resources/tools/*; do
	[ -d "$DIR" ] && { make -j${CORES} -C "$DIR" install || exit 1; }
done

make nostartup
make idestartup

mkdir -p /root/Bela/projects
cp -rv /root/Bela/IDE/templates/basic /root/Bela/projects/
make -j${CORES} all PROJECT=basic AT=
make -j${CORES} lib librariesall
ldconfig

echo "~~~~ building doxygen docs ~~~~"
doxygen > /dev/null 2>&1

echo "~~~~ Setting up distcc shorthands ~~~~"
CLANG_VERSION=14
(
cat << HEREDOC
#!/bin/bash
clang-${CLANG_VERSION} $@
HEREDOC
) > /usr/local/bin/clang-${CLANG_VERSION}-arm
(
cat << HEREDOC
#!/bin/bash
clang++-${CLANG_VERSION} $@ -stdlib=libstdc++
HEREDOC
) > /usr/local/bin/clang++-${CLANG_VERSION}-arm
(
cat << HEREDOC
#!/bin/bash
export DISTCC_HOSTS=192.168.7.1
export DISTCC_VERBOSE=0
export DISTCC_FALLBACK=0
export DISTCC_BACKOFF_PERIOD=0
distcc clang-${CLANG_VERSION}-arm $@
HEREDOC
) > /usr/local/bin/distcc-clang
(
cat << HEREDOC
#!/bin/bash
export DISTCC_HOSTS=192.168.7.1
export DISTCC_VERBOSE=0
export DISTCC_FALLBACK=0
export DISTCC_BACKOFF_PERIOD=0
distcc clang++-${CLANG_VERSION}-arm $@
HEREDOC
) > /usr/local/bin/distcc-clang++
chmod +x /usr/local/bin/clang*-${CLANG_VERSION}-arm /usr/local/bin/distcc-clang*

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
systemctl disable rsyslog
systemctl disable syslog.socket

# don't do any network access in the chroot after this call
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# clean the package cache to free up space on the image
apt-get clean
