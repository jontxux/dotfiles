#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

if [ "$1" == "add" ]; then
    TYPE=$(blkid -o value -s TYPE /dev/$2 2>/dev/null) || exit 1
    DIR="/media/usb"
    N=2
    while mountpoint -q "$DIR" 2>/dev/null; do 
        DIR="/media/usb$N"
        N=$((N+1))
    done
    OPTS="uid=1000,gid=1000,umask=0022"
    [ "$TYPE" == "ntfs" ] && OPTS="$OPTS,windows_names" && TYPE="ntfs-3g"
    systemd-mount --no-block --collect --options=$OPTS ${TYPE:+--type=$TYPE} /dev/$2 "$DIR"
    grep -q "$DIR" /proc/mounts || { rmdir "$DIR" 2>/dev/null; exit 1; }
elif [ "$1" == "remove" ]; then
    MP=$(awk -v d="/dev/$2" '$1==d {print $2}' /proc/mounts)
    [ -n "$MP" ] && systemd-umount "$MP" && rmdir "$MP" 2>/dev/null
fi
