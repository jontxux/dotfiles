#!/bin/bash
# Script para entrar en Gentoo con chroot (usando UUID)
# Uso: ./gentoo-chroot.sh [enter|exit]

GENTOO_ROOT="/mnt/gentoo"
GENTOO_UUID="fc3a17e6-b7e4-445e-9699-265f4513ab3b"

mount_gentoo() {
    echo "Montando Gentoo en $GENTOO_ROOT..."
    
    # Crea el directorio si no existe
    doas mkdir -p "$GENTOO_ROOT"
    
    # Monta la partición principal si no está montada
    if ! mountpoint -q "$GENTOO_ROOT"; then
        doas mount UUID="$GENTOO_UUID" "$GENTOO_ROOT" || {
            echo "Error: No se pudo montar UUID=$GENTOO_UUID"
            exit 1
        }
    fi
    
    # Monta los sistemas de archivos necesarios
    doas mount --types proc /proc "$GENTOO_ROOT/proc" 2>/dev/null
    doas mount --rbind /sys "$GENTOO_ROOT/sys" 2>/dev/null
    doas mount --make-rslave "$GENTOO_ROOT/sys" 2>/dev/null
    doas mount --rbind /dev "$GENTOO_ROOT/dev" 2>/dev/null
    doas mount --make-rslave "$GENTOO_ROOT/dev" 2>/dev/null
    doas mount --bind /run "$GENTOO_ROOT/run" 2>/dev/null
    doas mount --make-slave "$GENTOO_ROOT/run" 2>/dev/null
    
    # Copia resolv.conf para tener DNS
    doas cp -L /etc/resolv.conf "$GENTOO_ROOT/etc/" 2>/dev/null
    
    echo "✓ Gentoo montado correctamente"
}

unmount_gentoo() {
    echo "Desmontando Gentoo..."
    # Desmonta todo recursivamente
    doas umount -l "$GENTOO_ROOT/dev" 2>/dev/null
    doas umount -l "$GENTOO_ROOT/proc" 2>/dev/null
    doas umount -l "$GENTOO_ROOT/sys" 2>/dev/null
    doas umount -l "$GENTOO_ROOT/run" 2>/dev/null
    doas umount -l "$GENTOO_ROOT" 2>/dev/null
    echo "✓ Gentoo desmontado"
}

enter_chroot() {
    mount_gentoo
    echo "Entrando en Gentoo chroot..."
    echo "Para salir escribe: exit"
    echo ""
    doas chroot "$GENTOO_ROOT" /bin/bash -c "source /etc/profile && exec /bin/bash"
}

case "$1" in
    enter|"")
        enter_chroot
        ;;
    exit|umount)
        unmount_gentoo
        ;;
    *)
        echo "Uso: $0 [enter|exit]"
        echo "  enter  - Monta y entra en chroot (por defecto)"
        echo "  exit   - Desmonta Gentoo"
        exit 1
        ;;
esac
