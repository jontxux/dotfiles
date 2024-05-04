#!/bin/sh

sudo mount /dev/nvme0n1p1 /mnt/gentoo
sudo mount -t proc /proc /mnt/gentoo/proc
sudo mount --rbind /sys /mnt/gentoo/sys
sudo mount --make-rslave /mnt/gentoo/sys
sudo mount --rbind /dev /mnt/gentoo/dev
sudo mount --make-rslave /mnt/gentoo/dev
sudo chroot /mnt/gentoo /bin/bash
