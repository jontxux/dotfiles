#!/bin/bash

# Función para crear un enlace simbólico; si se proporciona un tercer parámetro, se usa sudo
create_link() {
    local target=$1
    local link=$2
    local use_sudo=${3:-no}  # El tercer parámetro es opcional y por defecto es 'no'

    if [ -L "${link}" ] || [ -e "${link}" ]; then
        echo "El enlace o archivo ya existe: ${link}"
    else
        if [ "$use_sudo" == "si" ]; then
            sudo ln -s "${target}" "${link}"
        else
            ln -s "${target}" "${link}"
        fi
        echo "Enlace simbólico creado: ${link} -> ${target}"
    fi
}

# Definir los pares de destino y enlace simbólico
declare -A links=(
    ["/home/jb/dotfiles/zsh/zprofile"]="/home/jb/.zprofile"
    ["/home/jb/dotfiles/wofi"]="/home/jb/.config/wofi"
    ["/home/jb/dotfiles/lf"]="/home/jb/.config/lf"
    ["/home/jb/dotfiles/foot"]="/home/jb/.config/foot"
    ["/home/jb/dotfiles/vim"]="/home/jb/.vim"
    ["/home/jb/dotfiles/yt-dlp"]="/home/jb/.config/yt-dlp"
    ["/home/jb/dotfiles/zsh/zshrc"]="/home/jb/.zshrc"
    ["/home/jb/dotfiles/git/gitconfig"]="/home/jb/.gitconfig"
    ["/home/jb/dotfiles/sway"]="/home/jb/.config/sway"
    ["/home/jb/dotfiles/waybar"]="/home/jb/.config/waybar"
)


# Definir los pares de destino y enlace simbólico que requieren sudo
declare -A sudo_links=(
    ["/home/jb/dotfiles/sway/autotiling/autotiling/main.py"]="/usr/local/bin/autotiling"
    ["/home/jb/dotfiles/diff-so-fancy/diff-so-fancy"]="/usr/local/bin/diff-so-fancy"
)

# Iterar a través de cada par y crear el enlace si no existe
for target in "${!links[@]}"; do
    create_link "${target}" "${links[$target]}"
done

# Crear enlaces que requieren sudo
for target in "${!sudo_links[@]}"; do
    create_link "${target}" "${sudo_links[$target]}" "si"
done
