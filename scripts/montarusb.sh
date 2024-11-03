#!/bin/sh

# Asignar variables
DEVICE=${1:-/dev/sdb1}  # Usa /dev/sdb1 por defecto si no se proporciona un argumento
MOUNT_POINT="/media/usb"

# Crear punto de montaje si no existe
if [ ! -d "$MOUNT_POINT" ]; then
  mkdir -p "$MOUNT_POINT"
fi

# Detectar el sistema de archivos
FS_TYPE=$(lsblk -no FSTYPE "$DEVICE")

# Montar según el sistema de archivos
case "$FS_TYPE" in
  vfat)
    doas mount -t vfat -o uid=$(id -u),gid=$(id -g),umask=022 "$DEVICE" "$MOUNT_POINT"
    ;;
  ntfs)
    doas mount -t ntfs-3g "$DEVICE" "$MOUNT_POINT"
    ;;
  ext4)
    doas mount -t ext4 "$DEVICE" "$MOUNT_POINT"
    ;;
  *)
    echo "Sistema de archivos $FS_TYPE no soportado automáticamente. Intenta montar manualmente."
    exit 1
    ;;
esac

echo "Dispositivo $DEVICE montado en $MOUNT_POINT"

