#!/bin/sh

doas mount /dev/nvme0n1p1 /mnt/gentoo
doas mount -t proc /proc /mnt/gentoo/proc
doas mount --rbind /sys /mnt/gentoo/sys
doas mount --make-rslave /mnt/gentoo/sys
doas mount --rbind /dev /mnt/gentoo/dev
doas mount --make-rslave /mnt/gentoo/dev
doas /sbin/chroot /mnt/gentoo /bin/bash
