# Guía de Instalación de Venom Linux (Imagen Etapa S6)

## Preparar las Particiones

### Sistemas EFI con GPT
En esta instalación se han utilizado las siguientes particiones:
- Formatear `/dev/nvme1n1p1` como vfat para `/boot`:
    ```bash
    mkfs.vfat /dev/nvme1n1p1
    ```
- Formatear `/dev/nvme1n1p2` como ext4 para la raíz `/`:
    ```bash
    mkfs.ext4 -L Venom /dev/nvme1n1p2
    ```

Montar las particiones:
```bash
mkdir -pv /mnt/venom
mkswap /dev/nvme1n1p3
mount /dev/nvme1n1p2 /mnt/venom
mkdir -pv /mnt/venom/boot/efi
mount /dev/nvme1n1p1 /mnt/venom/boot/efi
```

## Extraer la Imagen de Venom

Extraer la imagen de Venom al directorio montado:
```bash
tar xvJpf venomlinux-rootfs-<version>-x86_64.tar.xz -C /mnt/venom
```

## Entrar al Entorno chroot

Montar los sistemas de archivos necesarios usando `--rbind`:
```bash
mount --rbind /dev /mnt/venom/dev
mount --rbind /proc /mnt/venom/proc
mount --rbind /sys /mnt/venom/sys
mount --rbind /run /mnt/venom/run
cp -L /etc/resolv.conf /mnt/venom/etc/
chroot /mnt/venom /bin/bash
```

## Configuración del Sistema

1. Configurar el hostname, zona horaria, reloj, fuente, mapa de teclas y daemons:
    ```bash
    Para configurar el mapa de teclas y la zona horaria, se usaron comandos específicos:
    ```bash
    ln -sf /usr/share/zoneinfo/Europe/Madrid /etc/localtime
    hwclock --systohc
    loadkeys es
    ```
    Luego, editar `/etc/rc.conf` si es necesario:
    ```bash
    vim /etc/rc.conf
2. Configurar `/etc/fstab`:
    ```bash
    Ejecutar el siguiente comando para obtener los UUID de las particiones:
    ```bash
    blkid
    ```
    Luego, editar `/etc/fstab`:
    ```bash
    vim /etc/fstab
    Ejemplo de configuración de `/etc/fstab`:
    ```
    UUID=<UUID-de-nvme1n1p2>   /            ext4    defaults        0 1
UUID=<UUID-de-nvme1n1p1>   /boot/efi    vfat    defaults        0 2
UUID=<UUID-de-nvme1n1p3>   none         swap    sw              0 0
    ```
3. Configurar locales:
    ```bash
    vim /etc/locales
    genlocales
    ```
4. Configurar la contraseña de root:
    ```bash
    passwd
    ```
5. Crear un usuario:
    ```bash
    useradd -m -G users,wheel,audio,video -s /bin/bash <tu_usuario>
    passwd <tu_usuario>
    ```

## Instalación del Kernel

1. Sincronizar los repositorios:
    ```bash
    scratch sync
    ```
2. Actualizar el sistema:
    ```bash
    scratch sysup
    ```
3. Instalar el kernel:
    ```bash
    scratch install linux
    ```
   - Nota: Sustituir `linux` por `linux-lts` si deseas usar la versión LTS.

## Configuración del Gestor de Arranque (GRUB)

### EFI
1. Instalar el paquete `grub-efi` y configurar GRUB:
    ```bash
    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id="venomlinux"
    grub-mkconfig -o /boot/grub/grub.cfg
    ```

## Salir del Entorno chroot

Salir del entorno chroot:
```bash
exit
```

Desmontar las particiones montadas previamente:
```bash
umount -Rv /mnt/venom
```

## Reiniciar el Sistema

Reinicia la máquina, Venom Linux debería ser arrancable:
```bash
reboot
```

