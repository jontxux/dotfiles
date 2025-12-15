# Editor por defecto
export EDITOR="vim"
export VISUAL="vim"

# Configuración de idioma y localización
export LANG="es_ES.UTF-8"
export LC_ALL="es_ES.UTF-8"

# Configurar gpg-agent como SSH agent
unset SSH_AGENT_PID
if [ "${gnupg_SSH_AUTH_SOCK_by:-0}" -ne $$ ]; then
  export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
fi

# Configurar TTY correcto para pinentry
export GPG_TTY=$(tty)
gpg-connect-agent updatestartuptty /bye >/dev/null

# Configuración para Qt6
export QT_QPA_PLATFORMTHEME=qt6ct

if test -z "${XDG_RUNTIME_DIR}"; then
  export XDG_RUNTIME_DIR=/tmp/"${UID}"-runtime-dir
    if ! test -d "${XDG_RUNTIME_DIR}"; then
        mkdir "${XDG_RUNTIME_DIR}"
        chmod 0700 "${XDG_RUNTIME_DIR}"
    fi
fi

# Añadir $HOME/bin al PATH si el directorio existe
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# Añadir $HOME/.local/bin al PATH si el directorio existe
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

# Añadir /home/jb/.local/lib al LD_LIBRARY_PATH
if [ -d "$HOME/.local/lib" ] ; then
    export LD_LIBRARY_PATH="$HOME/.local/lib:$LD_LIBRARY_PATH"
fi

# Configuración automática para módulos Perl locales
if [ -d "$HOME/perl5/lib/perl5" ]; then
    eval "$(perl -I$HOME/perl5/lib/perl5 -Mlocal::lib 2>/dev/null)"
    export PATH="$HOME/perl5/bin:$PATH"
fi

# Añadir /sbin y /usr/sbin al PATH
PATH=$PATH:/sbin:/usr/sbin

# Configuración de Guix
# Priorizar el Guix instalado en el perfil de usuario (~/.config/guix/current)
if [ -d "$HOME/.config/guix/current" ]; then
    export GUIX_PROFILE="$HOME/.config/guix/current"
    . "$GUIX_PROFILE/etc/profile"
fi

# Cargar el perfil de Guix Home (tiene prioridad sobre el perfil manual)
if [ -d "$HOME/.guix-home/profile" ]; then
    export GUIX_PROFILE="$HOME/.guix-home/profile"
    . "$GUIX_PROFILE/etc/profile"
fi

# Configurar locales de Guix si están instaladas
if [ -d "$HOME/.guix-home/profile/lib/locale" ]; then
    export GUIX_LOCPATH="$HOME/.guix-home/profile/lib/locale"
fi

# Exportar PATH
export PATH
export MOZ_ENABLE_WAYLAND=1

# Añadir rutas de iconos y datos necesarias para GTK/Firefox en Wayland
export XDG_DATA_DIRS="/usr/share:/usr/local/share:$HOME/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share"
export XDG_CURRENT_DESKTOP=sway

# Iniciar sway en la primera terminal virtual si no está en Wayland
if [ -z "${WAYLAND_DISPLAY}" ] && [ "$(tty | grep -o '[0-9]*$')" -eq 1 ]; then
  echo "Iniciando sway..."
  exec dbus-run-session sway
fi
