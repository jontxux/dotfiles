# ===== CONFIGURACIÓN BÁSICA =====

# Solo ejecutar en shells interactivos
case $- in
    *i*) ;;
    *) return;;
esac

# ===== CONFIGURACIÓN DEL HISTORIAL =====
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

# Opciones del historial
setopt append_history           # Añadir en lugar de sobrescribir
setopt share_history            # Compartir historial entre sesiones
setopt hist_ignore_all_dups     # Ignorar duplicados en todo el historial
setopt hist_ignore_dups         # Ignorar duplicados sucesivos
setopt hist_find_no_dups        # No mostrar duplicados al buscar
setopt hist_reduce_blanks       # Eliminar espacios en blanco redundantes
setopt hist_verify              # Editar antes de ejecutar
setopt extended_history         # Guardar timestamps
setopt hist_ignore_space        # Ignorar comandos que empiezan con espacio

# ===== CONFIGURACIÓN DE TECLADO Y MODO VI =====
bindkey -v
export KEYTIMEOUT=1

# Configuración de teclas
bindkey -M viins '^H' backward-delete-char
bindkey -M viins '^?' backward-delete-char
bindkey -M vicmd '^H' backward-delete-char
bindkey -M vicmd '^?' backward-delete-char
bindkey -M viins '^[[3~' delete-char
bindkey '^[[3~' delete-char

# Editar línea de comandos
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^v' edit-command-line
bindkey -M vicmd 'v' edit-command-line

# Búsqueda en historial
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search
bindkey -M vicmd 'k' up-line-or-beginning-search
bindkey -M vicmd 'j' down-line-or-beginning-search

# Cursor para diferentes modos vi
function zle-keymap-select {
    case "${KEYMAP}" in
        vicmd|block) echo -ne '\e[2 q' ;;     # Bloque en modo comando
        main|viins|''|beam) echo -ne '\e[6 q' # Subrayado en modo inserción
    esac
    zle reset-prompt
}
zle -N zle-keymap-select

function zle-line-init {
    ultimo_error="$?"
    zle -K viins
    echo -ne '\e[6 q'
    zle reset-prompt
}
zle -N zle-line-init

function zle-line-finish {
    echo -ne '\e[2 q'
}
zle -N zle-line-finish

# ===== AUTOCOMPLETADO =====
fpath=(~/.local/share/zsh/site-functions $fpath)
autoload -U compinit
compinit

# Estilos de autocompletado
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zmodload zsh/complist
_comp_options+=(globdots)  # Incluir archivos ocultos

# ===== PLUGINS Y HERRAMIENTAS EXTERNAS =====

# Syntax highlighting
if [[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
    source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    # Configuración de colores (índices Gruvbox)
    ZSH_HIGHLIGHT_STYLES[command]='fg=10'
    ZSH_HIGHLIGHT_STYLES[alias]='fg=10'
    ZSH_HIGHLIGHT_STYLES[builtin]='fg=10'
    ZSH_HIGHLIGHT_STYLES[function]='fg=10'
    ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=9'
fi

# FZF (Fuzzy Finder)
if command -v fzf &> /dev/null; then
    local fzf_key_bindings=(
        "/usr/share/fzf/key-bindings.zsh"
        "/usr/local/share/fzf/key-bindings.zsh"
        "${HOME}/.fzf/shell/key-bindings.zsh"
        "/usr/share/doc/fzf/examples/key-bindings.zsh"
    )

    for file in "${fzf_key_bindings[@]}"; do
        if [[ -f "$file" ]]; then
            source "$file"
            break
        fi
    done

    export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
fi

# Zoxide
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init zsh)"
fi

# ===== ARCHIVOS EXTERNOS =====

# Aliases
[[ -r ~/.aliases ]] && source ~/.aliases

# Configuración de colores
[[ -f ~/dotfiles/scripts/colores.sh ]] && source ~/dotfiles/scripts/colores.sh

# ===== CONFIGURACIÓN DEL PROMPT =====

# Colores según Gruvbox (índices 0-15)
USER_PROMPT='%B%F{2}%n%f%b'        # bright_green (b8bb26)
CWD_PROMPT='%B%F{12}%~%f%b'         # bright_blue (83a598)

# Función para el símbolo de prompt ($/#)
function prompt_status {
    local underline=""
    if [[ -n $(jobs | sed -n '$=') ]]; then
        underline="%U"  # Subrayado si hay jobs en segundo plano
    fi

    local color=2
    if [[ "$ultimo_error" -ne 0 ]]; then
        color=1  # Cambiar a rojo en caso de error
    fi

    printf '%s' "${underline}%F{${color}}%(!.#.$)%f%u"
}

# Función para modo de teclado VI
function prompt_keymap {
    local icono_modo="▶"
    [[ "$KEYMAP" = 'vicmd' ]] && icono_modo="■"
    printf '%%F{15}%s%%f' "$icono_modo"  # Color bright7 (fbf1c7)
}

# Función para rama Git
function prompt_git {
    local nombre_rama=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [[ -n "$nombre_rama" ]]; then
        if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
            printf '%%F{1}%s%%f ' "$nombre_rama"  # bright_red (fb4934) si hay cambios
        else
            printf '%%F{2}%s%%f ' "$nombre_rama"  # bright_green (b8bb26) si está limpio
        fi
    fi
}

# Capturar último código de error antes de cada prompt
function precmd {
    ultimo_error=$?
}

setopt prompt_subst
PROMPT='${USER_PROMPT} ${CWD_PROMPT} $(prompt_status) $(prompt_git)$(prompt_keymap) '
PROMPT_EOL_MARK=''
