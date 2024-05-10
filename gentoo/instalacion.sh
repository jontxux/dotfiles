#!/bin/bash

# Comprobar si el script se está ejecutando como superusuario
if [ "$(id -u)" -ne 0 ]; then
  echo "Este script debe ser ejecutado como superusuario o con sudo."
  exit 1
fi

# Definir particiones
DISK="/dev/nvme0n1"
SWAP_PART="${DISK}p2"
ROOT_PART="${DISK}p1"

# Formatear las particiones
echo "Formateando particiones..."
mkswap $SWAP_PART
mkfs.ext4 $ROOT_PART

# Activar swap
echo "Activando swap..."
swapon $SWAP_PART

# Montar el sistema de archivos root
echo "Montando el sistema de archivos root..."
mount $ROOT_PART /mnt/gentoo

# Montar los sistemas de archivos necesarios
for i in /proc /sys /dev /run; do
    mkdir -p /mnt/gentoo/$i
    mount --rbind $i /mnt/gentoo$i
    mount --make-rslave /mnt/gentoo$i
done

# Descargar y descomprimir el Stage 3
echo "Descargando y descomprimiendo Stage 3..."
cd /mnt/gentoo
wget -P /mnt/gentoo https://distfiles.gentoo.org/releases/amd64/autobuilds/20240428T163427Z/stage3-amd64-openrc-20240428T163427Z.tar.xz
tar xpJf stage3-amd64-openrc-20240428T163427Z.tar.xz --xattrs-include='*.*' --numeric-owner

# Copiar archivos personalizados
echo "Copiando archivos de configuración personalizados..."
CONFIG_DIR="/home/jb/dotfiles/gentoo"

cp -v "${CONFIG_DIR}/hostname" /mnt/gentoo/etc/conf.d/hostname
cp -v "${CONFIG_DIR}/hosts" /mnt/gentoo/etc/hosts
cp -v "${CONFIG_DIR}/keymaps" /mnt/gentoo/etc/conf.d/keymaps
cp -v "${CONFIG_DIR}/locale.gen" /mnt/gentoo/etc/locale.gen
cp -v "${CONFIG_DIR}/make.conf" /mnt/gentoo/etc/portage/make.conf
cp -v "${CONFIG_DIR}/timezone" /mnt/gentoo/etc/timezone
mkdir -p /mnt/gentoo/etc/portage/package.use
cp -v "${CONFIG_DIR}/package.use/*" /mnt/gentoo/etc/portage/package.use/
cp -v "${CONFIG_DIR}/../doas/doas.conf" /mnt/gentoo/etc/doas.conf

# Copiar resolv.conf
echo "Copiando configuración DNS..."
cp -L /etc/resolv.conf /mnt/gentoo/etc/resolv.conf

# Obtener UUIDs para las particiones
UUID_SWAP=$(blkid -s UUID -o value $SWAP_PART)
UUID_ROOT=$(blkid -s UUID -o value $ROOT_PART)

# Generar fstab utilizando UUIDs
echo "Generando fstab..."
cat << EOF > /mnt/gentoo/etc/fstab
UUID=$UUID_ROOT    /       ext4    defaults,noatime  0 1
UUID=$UUID_SWAP    none    swap    sw                0 0
tmpfs              /tmp    tmpfs   nodev,nosuid      0 0
EOF

# Crear un script con todos los comandos a ejecutar en el chroot
echo "Creando script para chroot..."
cat << 'EOF' > /mnt/gentoo/root/chroot_commands.sh
#!/bin/bash

# Cargar el entorno de perfil
source /etc/profile

# Configurar el locale
locale-gen

# Actualizar el entorno
env-update && source /etc/profile

# Configurar Portage
emerge-webrsync

# Instalar el sistema base
emerge --verbose --update --deep --newuse @world

# Instalar el kernel y el generador
emerge gentoo-sources
emerge genkernel
genkernel all

# Crear usuario
passwd
useradd -m -G users,wheel,audio,video,usb,portage -s /bin/bash jb
passwd jb

# Instalar Sway y sus dependencias
emerge --ask dev-libs/wayland
emerge --ask gui-libs/wlroots
emerge --ask sys-apps/dbus
emerge --ask gui-wm/sway
emerge --ask gui-apps/foot
emerge --ask app-misc/jq
emerge --ask net-misc/yt-dlp
emerge --ask app-editors/vim
emerge --ask gui-apps/grim
emerge --ask gui-apps/slurp
emerge --ask dev-vcs/git
emerge --ask media-sound/alsa-utils
emerge --ask app-admin/doas

sed -i 's|nano|vim|g' /etc/profile
source /etc/profile

git clone --recurse-submodules https://github.com/jontxux/dotfiles.git

su jb -c 'ln -sfn /home/jb/dotfiles/sway/ /home/jb/.config/'
su jb -c 'ln -sfn /home/jb/dotfiles/yt-dlp/ /home/jb/.config/'
su jb -c 'ln -sfn /home/jb/dotfiles/foot/ /home/jb/.config/'
su jb -c 'ln -sfn /home/jb/dotfiles/vim/ /home/jb/.vim'
su jb -c 'ln -sfn /home/jb/dotfiles/git/gitconfig /home/jb/.gitconfig'
ln -sfn /home/jb/dotfiles/diff-so-fancy/diff-so-fancy /usr/local/bin/

export LANG=es_ES.UTF-8
emerge --ask x11-misc/xdg-user-dirs
xdg-user-dirs-update

gpasswd -a jb seat
rc-update add seatd default

# Eliminar este script al finalizar
rm -- "$0"

EOF

# Asegurar permisos de ejecución para el script
chmod +x /mnt/gentoo/root/chroot_commands.sh

# Ejecutar el script dentro del chroot
echo "Ejecutando script dentro del chroot..."
chroot /mnt/gentoo /bin/bash /root/chroot_commands.sh
