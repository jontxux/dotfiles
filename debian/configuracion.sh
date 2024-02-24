#!/bin/bash

echo "Comprobando si tienes acceso a sudo..."

# Comprobar si el usuario actual tiene acceso a sudo
if ! sudo -v &> /dev/null; then
    echo "Parece que no tienes acceso a sudo."
    echo "Si eres el administrador del sistema, instala sudo y otorga a tu usuario acceso a sudo."
    echo "Puedes hacerlo ejecutando 'apt-get install sudo' como root y luego 'usermod -aG sudo $USER' para añadir tu usuario al grupo sudo."
    exit 1
else
    echo "Acceso a sudo confirmado. Continuando con el script..."
fi

# Función para crear enlace simbólico
crear_enlace() {
    origen=$1
    destino=$2
    usar_sudo=$3  # Nuevo parámetro para decidir si usar sudo

    if [ -L "${destino}" ] || [ -e "${destino}" ]; then
        echo "El enlace o directorio ${destino} ya existe. Saltando..."
    else
        if [ "$usar_sudo" = "sudo" ]; then
            sudo ln -s "${origen}" "${destino}"
            echo "Enlace simbólico creado con sudo: ${destino} -> ${origen}"
        else
            ln -s "${origen}" "${destino}"
            echo "Enlace simbólico creado: ${destino} -> ${origen}"
        fi
    fi
}

# Actualizar los repositorios a testing
actualizar_repositorios() {
    echo "Actualizando /etc/apt/sources.list a Debian Testing..."
    sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup
    cat << EOF | sudo tee /etc/apt/sources.list
deb http://deb.debian.org/debian/ testing main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian/ testing main contrib non-free non-free-firmware

deb http://deb.debian.org/debian/ testing-updates main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian/ testing-updates main contrib non-free non-free-firmware

deb http://deb.debian.org/debian testing-proposed-updates main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian testing-proposed-updates main contrib non-free non-free-firmware

deb http://security.debian.org/ testing-security main contrib non-free non-free-firmware
deb-src http://security.debian.org/ testing-security main contrib non-free non-free-firmware
EOF
    sudo apt update
    echo "Repositorios actualizados a testing."
}

# Instalar paquetes
instalar_paquetes() {
    echo "Instalando paquetes básicos..."
    sudo apt install -y aptitude
    sudo aptitude update
    sudo aptitude install -y firefox-esr mpv ffmpeg yt-dlp qutebrowser xwayland telegram-desktop vim-gtk3 btop udisks2 slurp grim imagemagick pavucontrol swayimg
    echo "Paquetes instalados."
}

# Crear enlaces simbólicos
crear_enlaces() {
    echo "Creando enlaces simbólicos para la configuración..."
    mkdir -p ~/.config/sway
    mkdir -p ~/.config/qutebrowser
    mkdir -p ~/.oh-my-zsh/themes
    # Ejemplos de enlaces simbólicos; ajusta las rutas según sea necesario
    crear_enlace ~/dotfiles/sway/config ~/.config/sway/config
    crear_enlace ~/dotfiles/vim ~/.vim
    crear_enlace ~/dotfiles/git/gitconfig ~/.gitconfig
    crear_enlace ~/dotfiles/bash/bashrc ~/.bashrc
    crear_enlace ~/dotfiles/bash/profile ~/.profile
    crear_enlace ~/dotfiles/zsh/zshrc ~/.zshrc
    crear_enlace ~/dotfiles/zsh/zprofile ~/.zprofile
    crear_enlace ~/dotfiles/qutebrowser/config.py ~/.config/qutebrowser/config.py
    crear_enlace ~/dotfiles/yt-dlp/config ~/.config/yt-dlp/config
    crear_enlace ~/dotfiles/diff-so-fancy/diff-so-fancy /usr/local/bin/diff-so-fancy sudo
    echo "Enlaces simbólicos creados."
}

# Interacción con el usuario
echo "Bienvenido al script de configuración."
read -p "¿Quieres actualizar los repositorios a testing? (s/n): " respuesta
if [[ "$respuesta" =~ ^[Ss]$ ]]; then
    actualizar_repositorios
fi

read -p "¿Quieres instalar los paquetes necesarios ahora? (s/n): " respuesta
if [[ "$respuesta" =~ ^[Ss]$ ]]; then
    instalar_paquetes
fi

read -p "¿Quieres crear enlaces simbólicos para tu configuración? (s/n): " respuesta
if [[ "$respuesta" =~ ^[Ss]$ ]]; then
    crear_enlaces
fi

echo "Script finalizado."
