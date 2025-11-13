# Si no se está ejecutando de forma interactiva, no hacer nada
case $- in
    *i*) ;;
    *) return;;
esac

# Configuración GPG: establecer la terminal actual para que la use GPG
export GPG_TTY=$TTY

# Aliases
[ -r ~/.aliases ] && . ~/.aliases

# Colores personalizados (LS_COLORS)
[ -f ~/dotfiles/scripts/colores.sh ] && source ~/dotfiles/scripts/colores.sh

# Historial
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

# Historial options
setopt append_history       # Añadir al historial en vez de sobrescribirlo
setopt share_history        # Compartir el historial entre todas las sesiones de zsh
setopt hist_ignore_all_dups # Ignorar duplicados en todo el historial
setopt hist_ignore_dups     # Ignorar duplicados sucesivos
setopt hist_find_no_dups    # No mostrar duplicados al buscar en el historial
setopt hist_reduce_blanks   # Eliminar espacios en blanco redundantes
setopt hist_verify          # Editar línea de historial antes de aceptar
setopt extended_history     # Almacenar timestamp del comando en el historial
setopt hist_ignore_space    # No guardar comandos que comiencen con un espacio

# Modo vi
bindkey -v
export KEYTIMEOUT=1

# Asignar la tecla Backspace para borrar el carácter anterior en todos los modos relevantes
bindkey -M viins '^H' backward-delete-char
bindkey -M viins '^?' backward-delete-char
bindkey -M vicmd '^H' backward-delete-char
bindkey -M vicmd '^?' backward-delete-char

# Asignar la tecla Delete para borrar el carácter adelante
bindkey -M viins '^[[3~' delete-char
bindkey '^[[3~' delete-char

# Función para editar la línea de comandos
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^v' edit-command-line
bindkey -M vicmd 'v' edit-command-line

# Cambio de forma del cursor para diferentes modos vi
function zle-keymap-select {
    case "${KEYMAP}" in
        vicmd | block) echo -ne '\e[2 q' ;;  # Cursor de bloque para modo comando
        main | viins | '' | beam) echo -ne '\e[6 q' ;;  # Cursor de subrayado para modo inserción
    esac
    zle reset-prompt  # Redibujar el prompt
}
zle -N zle-keymap-select

# Inicializar con el cursor en modo inserción
function zle-line-init {
    ultimo_error="$?"  # Capturar el estado de salida
    zle -K viins  # Iniciar con keymap de inserción
    echo -ne '\e[6 q'  # Cursor de subrayado
    zle reset-prompt  # Redibujar el prompt
}
zle -N zle-line-init

# Finalizar con el cursor en modo comando
function zle-line-finish {
    echo -ne '\e[2 q'  # Cursor de bloque
}
zle -N zle-line-finish

# Autocompletado básico
fpath=(~/.local/share/zsh/site-functions $fpath)
autoload -U compinit
compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zmodload zsh/complist
_comp_options+=(globdots)  # Incluir archivos ocultos

# Búsqueda en el historial
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search
bindkey -M vicmd 'k' up-line-or-beginning-search
bindkey -M vicmd 'j' down-line-or-beginning-search

# Plugins
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
# Definir estilos para zsh-syntax-highlighting (usando índices de color Gruvbox)
ZSH_HIGHLIGHT_STYLES[command]='fg=10'        # bright_green (b8bb26) para comandos válidos
ZSH_HIGHLIGHT_STYLES[alias]='fg=10'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=10'
ZSH_HIGHLIGHT_STYLES[function]='fg=10'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=9'   # bright_red (fb4934) para comandos inválidos

# Configuración para FZF (Fuzzy Finder)
if command -v fzf &> /dev/null; then
  # Verificar posibles ubicaciones del archivo de key-bindings
  local fzf_key_bindings=(
    "/usr/share/fzf/key-bindings.zsh"                # Linux estándar
    "/usr/local/share/fzf/key-bindings.zsh"          # macOS (Homebrew)
    "${HOME}/.fzf/shell/key-bindings.zsh"            # Instalación manual/git
    "/usr/share/doc/fzf/examples/key-bindings.zsh"   # Debian/Ubuntu
  )

  for file in "${fzf_key_bindings[@]}"; do
    if [[ -f "$file" ]]; then
      source "$file"
      break
    fi
  done

  # Configuración adicional (opcional)
  export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
fi

# Configurar colores según Gruvbox (índices 0-15)
USER_PROMPT='%B%F{2}%n%f%b'       # Nombre usuario (bright_green - b8bb26)
CWD_PROMPT='%B%F{12}%~%f%b'        # Directorio (bright_blue - 83a598)

# Función para el símbolo de prompt ($/#)
function prompt_status {
    local underline=""
    if [ -n "$(jobs | sed -n '$=')" ]; then
        underline="%U"  # Subrayado si hay jobs
    fi

    local color=2                   # Color base: regular2 (neutral_green - 98971a)
    if [ "$ultimo_error" -ne 0 ]; then
        color=1                     # Cambia a regular1 (neutral_red - cc241d) en error
    fi

    printf '%s' "${underline}%F{${color}}%(!.#.$)%f%u"
}

# Función para modo de teclado (VI)
function prompt_keymap {
    local icono_modo="▶"
    [ "$KEYMAP" = 'vicmd' ] && icono_modo="■"
    printf '%%F{15}%s%%f' "$icono_modo"  # Color bright7 (fbf1c7)
}

# Función para rama Git
function prompt_git {
    local nombre_rama=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [ -n "$nombre_rama" ]; then
        if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
            printf '%%F{1}%s%%f ' "$nombre_rama"  # bright_red (fb4934)
        else
            printf '%%F{2}%s%%f ' "$nombre_rama"  # bright_green (b8bb26)
        fi
    fi
}

# Capturar último código de error antes de cada prompt
precmd() {
    ultimo_error=$?
}

setopt prompt_subst
PROMPT='${USER_PROMPT} ${CWD_PROMPT} $(prompt_status) $(prompt_git)$(prompt_keymap) '

eval "$(zoxide init zsh)"
