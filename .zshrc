# ===== MODO VI =====
export KEYTIMEOUT=1

# ===== API KEYS =====
export DEEPSEEK_API_KEY=$(pass apis/deepseek)

bindkey -M viins '^H' backward-delete-char
bindkey -M viins '^?' backward-delete-char
bindkey -M vicmd '^H' backward-delete-char
bindkey -M vicmd '^?' backward-delete-char
bindkey -M viins '^[[3~' delete-char
bindkey '^[[3~' delete-char

autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^v' edit-command-line
bindkey -M vicmd 'v' edit-command-line

autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search
bindkey -M vicmd 'k' up-line-or-beginning-search
bindkey -M vicmd 'j' down-line-or-beginning-search

# ===== CURSOR =====
function zle-keymap-select {
    case "${KEYMAP}" in
        vicmd|block) echo -ne '\e[2 q' ;;
        main|viins|''|beam) echo -ne '\e[6 q'
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
    echo -ne '\e[6 q'
}
zle -N zle-line-finish

# ===== AUTOCOMPLETADO =====
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zmodload zsh/complist
_comp_options+=(globdots)

# ===== PROMPT =====
USER_PROMPT='%B%F{2}%n%f%b'
CWD_PROMPT='%B%F{12}%~%f%b'

function prompt_status {
    local underline=""
    if [[ -n $(jobs | sed -n '$=') ]]; then
        underline="%U"
    fi

    local color=2
    if [[ "$ultimo_error" -ne 0 ]]; then
        color=1
    fi

    printf '%s' "${underline}%F{${color}}%(!.#.$)%f%u"
}

function prompt_keymap {
    local icono_modo="▶"
    [[ "$KEYMAP" = 'vicmd' ]] && icono_modo="■"
    printf '%%F{15}%s%%f' "$icono_modo"
}

function prompt_git {
    local nombre_rama=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [[ -n "$nombre_rama" ]]; then
        if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
            printf '%%F{1}%s%%f ' "$nombre_rama"
        else
            printf '%%F{2}%s%%f ' "$nombre_rama"
        fi
    fi
}

function precmd {
    ultimo_error=$?
    echo -ne '\e[6 q'
}

setopt prompt_subst
PROMPT='$USER_PROMPT $CWD_PROMPT $(prompt_status) $(prompt_git)$(prompt_keymap) '
PROMPT_EOL_MARK=""

# ===== ARCHIVOS EXTERNOS =====
[[ -r ~/.aliases ]] && source ~/.aliases
