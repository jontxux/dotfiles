#!/bin/sh

# Script mejorado para montar dispositivos USB con manejo de errores y soporte extendido

# Configuración
DEFAULT_DEVICE="/dev/sdb1"
MOUNT_POINT="${2:-/media/usb}"  # Permite especificar punto de montaje como segundo parámetro
SUDO_CMD=$(command -v sudo || command -v doas 2>/dev/null)  # Soporta tanto sudo como doas

# Mensaje de ayuda
show_help() {
    echo "Uso: $0 [dispositivo] [punto_de_montaje]"
    echo "Ejemplo: $0 /dev/sdc1 /mnt/usb-drive"
    echo ""
    echo "Argumentos:"
    echo "  dispositivo        Ruta del dispositivo (por defecto: $DEFAULT_DEVICE)"
    echo "  punto_de_montaje   Directorio de montaje (por defecto: $MOUNT_POINT)"
    exit 0
}

# Verificar privilegios
check_privileges() {
    if [ ! -x "$SUDO_CMD" ]; then
        echo "Error: Se necesita sudo o doas para montar dispositivos"
        exit 1
    fi
    
    if ! $SUDO_CMD -v 2>/dev/null; then
        echo "Error: No se tienen los privilegios necesarios"
        exit 1
    fi
}

# Verificar si el dispositivo existe
check_device() {
    if [ ! -b "$DEVICE" ]; then
        echo "Error: El dispositivo $DEVICE no existe o no es un bloque especial"
        exit 2
    fi
}

# Crear directorio de montaje
create_mountpoint() {
    if [ ! -d "$MOUNT_POINT" ]; then
        if ! mkdir -p "$MOUNT_POINT" 2>/dev/null; then
            echo "Error: No se pudo crear el directorio de montaje $MOUNT_POINT"
            exit 3
        fi
    fi

    if mountpoint -q "$MOUNT_POINT"; then
        echo "Error: $MOUNT_POINT ya está siendo usado como punto de montaje"
        exit 4
    fi
}

# Detectar sistema de archivos con múltiples métodos
detect_filesystem() {
    FS_TYPE=$(blkid -o value -s TYPE "$DEVICE" 2>/dev/null)
    
    if [ -z "$FS_TYPE" ]; then
        echo "Error: No se pudo detectar el sistema de archivos de $DEVICE"
        exit 5
    fi
}

# Montar dispositivo
mount_device() {
    case "$FS_TYPE" in
        vfat|fat16|fat32)
            MOUNT_OPTIONS="uid=$(id -u),gid=$(id -g),fmask=113,dmask=002,utf8"
            ;;
        ntfs)
            MOUNT_OPTIONS="windows_names,uid=$(id -u),gid=$(id -g)"
            FS_TYPE="ntfs-3g"
            ;;
        ext[2-4]|btrfs|xfs)
            MOUNT_OPTIONS="defaults"
            ;;
        exfat)
            MOUNT_OPTIONS="uid=$(id -u),gid=$(id -g)"
            ;;
        *)
            echo "Error: Sistema de archivos $FS_TYPE no soportado"
            echo "Intenta montar manualmente con:"
            echo "$SUDO_CMD mount -t <tipo> $DEVICE $MOUNT_POINT"
            exit 6
            ;;
    esac

    if ! $SUDO_CMD mount -t "$FS_TYPE" -o "$MOUNT_OPTIONS" "$DEVICE" "$MOUNT_POINT"; then
        echo "Error: Falló el montaje del dispositivo $DEVICE"
        exit 7
    fi

    echo "Dispositivo $DEVICE (tipo: $FS_TYPE) montado correctamente en $MOUNT_POINT"
}

# Main
[ "$1" = "-h" ] || [ "$1" = "--help" ] && show_help
DEVICE="${1:-$DEFAULT_DEVICE}"

check_privileges
check_device
create_mountpoint
detect_filesystem
mount_device

exit 0
