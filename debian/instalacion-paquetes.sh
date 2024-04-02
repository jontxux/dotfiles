#!/bin/bash

# Paquetes a instalar
paquetes=(
    "qutebrowser"
    "plocate"
    "fzf"
    "ripgrep"
    "lf"
    "chafa"
    "p7zip"
    "ntfs-3g"
    "parted"
    "python3-i3ipc"
    "udisks2"
    "xwayland"
    "os-prober"
    "poppler-utils"
    "ffmpegthumbnailer"
    "build-essential"
    "firefox-esr"
    "git"
    "sway"
    "waybar"
    "swayidle"
    "swaylock"
    "bat"
    "unrar"
    "lynx"
)

# Actualizar la lista de paquetes
sudo aptitude update

for paquete in "${paquetes[@]}"; do
    # Verificar si el paquete ya está instalado
    if dpkg -l | grep -qw "$paquete"; then
        echo "El paquete ya está instalado: $paquete"
    else
        echo "Instalando $paquete..."
        sudo aptitude install -y "$paquete"
    fi
done

echo "Todos los paquetes requeridos han sido procesados."
