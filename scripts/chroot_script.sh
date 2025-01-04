#!/bin/bash

set -e

# Función para mostrar uso
usage() {
  echo "Uso: $0 /ruta/a/chroot [dispositivo]"
  exit 1
}

# Comprobar si el script se ejecuta como root
if [ "$EUID" -ne 0 ]; then
  echo "Este script debe ejecutarse como root."
  exit 1
fi

# Comprobar si se proporciona al menos una ruta
if [ -z "$1" ]; then
  usage
fi

CHROOT_DIR="$1"
DEVICE="$2"

# Comprobar si la ruta existe
if [ ! -d "$CHROOT_DIR" ]; then
  echo "Error: La ruta especificada no existe: $CHROOT_DIR"
  exit 1
fi

BASE_MOUNTED=false

# Comprobar si el directorio base está montado
if ! mountpoint -q "$CHROOT_DIR"; then
  echo "La ruta base $CHROOT_DIR no está montada."
  if [ -n "$DEVICE" ]; then
    if [ -b "$DEVICE" ]; then
      echo "Montando el dispositivo $DEVICE en $CHROOT_DIR..."
      mount "$DEVICE" "$CHROOT_DIR"
      echo "Partición $DEVICE montada en $CHROOT_DIR."
      BASE_MOUNTED=true
    else
      echo "Error: Dispositivo $DEVICE no válido."
      exit 1
    fi
  else
    read -p "¿Desea montar una partición en $CHROOT_DIR? (s/n): " confirm
    if [[ "$confirm" =~ ^[sS]$ ]]; then
      read -p "Introduzca el dispositivo a montar (ejemplo: /dev/nvme1n1p2): " device_input
      if [ -b "$device_input" ]; then
        mount "$device_input" "$CHROOT_DIR"
        echo "Partición $device_input montada en $CHROOT_DIR."
        BASE_MOUNTED=true
      else
        echo "Error: Dispositivo $device_input no válido."
        exit 1
      fi
    else
      echo "El directorio base no está montado. Abortando."
      exit 1
    fi
  fi
fi

# Comprobar si las subrutas necesarias están montadas
check_mounts() {
  for dir in /dev /proc /sys /run; do
    if mountpoint -q "$CHROOT_DIR$dir"; then
      echo "La ruta $CHROOT_DIR$dir ya está montada."
    else
      echo "La ruta $CHROOT_DIR$dir no está montada. Procediendo a montar."
      return 1
    fi
  done
  return 0
}

# Función para montar sistemas de archivos
mount_chroot() {
  echo "Montando sistemas de archivos en $CHROOT_DIR..."
  mount --rbind /dev "$CHROOT_DIR/dev"
  mount --rbind /proc "$CHROOT_DIR/proc"
  mount --rbind /sys "$CHROOT_DIR/sys"
  mount --rbind /run "$CHROOT_DIR/run"
  echo "Montaje completado."
}

# Función para desmontar sistemas de archivos
umount_chroot() {
  echo "Desmontando sistemas de archivos de $CHROOT_DIR..."
  umount -l "$CHROOT_DIR/dev" || true
  umount -l "$CHROOT_DIR/proc" || true
  umount -l "$CHROOT_DIR/sys" || true
  umount -l "$CHROOT_DIR/run" || true
  if [ "$BASE_MOUNTED" = true ]; then
    umount -l "$CHROOT_DIR" || true
    echo "Partición base desmontada de $CHROOT_DIR."
  fi
  echo "Desmontaje completado."
}

# Asegurarse de desmontar al salir
trap umount_chroot EXIT

# Verificar y montar si es necesario
if ! check_mounts; then
  mount_chroot
else
  echo "Todos los sistemas de archivos ya están montados."
fi

# Entrar al chroot
echo "Entrando en el chroot en $CHROOT_DIR..."
chroot "$CHROOT_DIR" /bin/bash

# Cuando el usuario salga del chroot, se ejecutará el trap para desmontar
