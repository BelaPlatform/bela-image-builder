#! /bin/sh

echo "Enabling interface and functional clock of McASP..."
/root/Bela/resources/bin/devmem2 0x44E00034 w 0x30002 >> /dev/null
