#!/bin/bash

# Poner tema oscuro
gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark
gsettings set org.gnome.desktop.interface color-scheme prefer-dark

# deshabilitar parpadeo cursor gnome-terminal
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$(gsettings get org.gnome.Terminal.ProfilesList default|tr -d \')/ cursor-blink-mode off

# fuente para gnome-terminal
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$(gsettings get org.gnome.Terminal.ProfilesList default|tr -d \')/ font 'DejaVuSansMono Nerd Font Mono 13'

# deshabilitar comfirmacion cierre gnome-terminal
gsettings set org.gnome.Terminal.Legacy.Settings confirm-close false


# Cerrar ventana con mas de un atajo
gsettings set org.gnome.desktop.wm.keybindings close "['<Alt>F4', '<Super><Shift>q']"

# botones minimizar maximizar cerrar
gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
