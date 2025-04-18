#!/bin/sh

# Script mejorado para montar dispositivos USB con soporte de permisos para usuarios regulares
# Versión 2.0 - Soporta FAT32, NTFS, exFAT, EXT4 y otros sistemas de archivos

# =============================================
# CONFIGURACIÓN
# =============================================
DEFAULT_DEVICE="/dev/sdb1"
MOUNT_POINT="${2:-/media/usb}"            # Directorio de montaje por defecto
SUDO_CMD=$(command -v sudo || command -v doas 2>/dev/null)  # Soporta sudo y doas
USER_ID=$(id -u)                          # ID del usuario actual
GROUP_ID=$(id -g)                         # ID del grupo actual

# =============================================
# FUNCIONES
# =============================================
show_help() {
    echo "Uso: $0 [dispositivo] [punto_de_montaje]"
    echo "Ejemplo: $0 /dev/sdc1 /mnt/usb-drive"
    echo ""
    echo "Características:"
    echo "  - Permisos de usuario completo en FAT32/NTFS/exFAT"
    echo "  - Montaje seguro para sistemas EXT4/BTRFS/XFS"
    echo "  - Detección automática del sistema de archivos"
    exit 0
}

check_privileges() {
    if [ ! -x "$SUDO_CMD" ]; then
        echo "Error: Se necesita sudo o doas para montar dispositivos"
        exit 1
    fi
    
    if ! $SUDO_CMD -v 2>/dev/null; then
        echo "Error: Privilegios insuficientes"
        exit 1
    fi
}

check_device() {
    if [ ! -b "$DEVICE" ]; then
        echo "Error: $DEVICE no existe o no es un dispositivo de bloque"
        exit 2
    fi
}

create_mountpoint() {
    if [ ! -d "$MOUNT_POINT" ]; then
        if ! mkdir -p "$MOUNT_POINT" 2>/dev/null; then
            echo "Error: No se pudo crear $MOUNT_POINT"
            exit 3
        fi
    fi

    if mountpoint -q "$MOUNT_POINT"; then
        echo "Error: $MOUNT_POINT ya está en uso"
        exit 4
    fi
}

detect_filesystem() {
    FS_TYPE=$(blkid -o value -s TYPE "$DEVICE" 2>/dev/null)
    
    if [ -z "$FS_TYPE" ]; then
        echo "Error: Sistema de archivos no reconocido en $DEVICE"
        exit 5
    fi
}

mount_device() {
    case "$FS_TYPE" in
        vfat|fat16|fat32)
            MOUNT_OPTIONS="uid=$USER_ID,gid=$GROUP_ID,umask=000,utf8"
            ;;
        ntfs)
            MOUNT_OPTIONS="windows_names,uid=$USER_ID,gid=$GROUP_ID,umask=000,allow_other"
            FS_TYPE="ntfs-3g"
            ;;
        ext[2-4]|btrfs|xfs)
            MOUNT_OPTIONS="uid=$USER_ID,gid=$GROUP_ID"
            ;;
        exfat)
            MOUNT_OPTIONS="uid=$USER_ID,gid=$GROUP_ID,umask=000"
            ;;
        *)
            echo "Error: Sistema de archivos $FS_TYPE no soportado"
            exit 6
            ;;
    esac

    # Comando de montaje principal
    if ! $SUDO_CMD mount -t "$FS_TYPE" -o "$MOUNT_OPTIONS" "$DEVICE" "$MOUNT_POINT"; then
        echo "Error: Falló el montaje de $DEVICE"
        exit 7
    fi

    # Ajuste final de permisos (para sistemas que preservan permisos)
    $SUDO_CMD chmod -R a+rwX "$MOUNT_POINT" 2>/dev/null
    $SUDO_CMD chown -R $USER_ID:$GROUP_ID "$MOUNT_POINT" 2>/dev/null

    echo "Montaje exitoso:"
    echo "- Dispositivo: $DEVICE"
    echo "- Tipo: $FS_TYPE"
    echo "- Punto de montaje: $MOUNT_POINT"
    echo "- Permisos: $(stat -c '%A' "$MOUNT_POINT")"
}

# =============================================
# EJECUCIÓN PRINCIPAL
# =============================================
[ "$1" = "-h" ] || [ "$1" = "--help" ] && show_help
DEVICE="${1:-$DEFAULT_DEVICE}"

check_privileges
check_device
create_mountpoint
detect_filesystem
mount_device

exit 0
