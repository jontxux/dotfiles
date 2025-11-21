#!/usr/bin/env bash
# liblf.sh - Librería común para scripts de lf

# Importar librería de estilos
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "$SCRIPT_DIR/libstyle.sh"

# ============================================================================
# GESTIÓN DE VARIABLES GLOBALES (Para evitar errores de espacios)
# ============================================================================
declare -a FILES
declare -a VALID_FILES

# Cargar argumentos en array global FILES
load_files() {
    FILES=()
    # Si lf pasa una lista separada por saltos de línea en un solo argumento
    if [ $# -eq 1 ] && [[ "$1" == *$'\n'* ]]; then
        IFS=$'\n' read -d '' -r -a FILES <<< "$1"
    else
        FILES=("$@")
    fi
}

# Filtrar archivos existentes en array global VALID_FILES
filter_valid_files() {
    VALID_FILES=()
    for file in "${FILES[@]}"; do
        if [ -e "$file" ]; then
            VALID_FILES+=("$file")
        else
            print_error "El archivo no existe: $file" >&2
        fi
    done
}

# ============================================================================
# FUNCIONES DE ENTRADA/SALIDA
# ============================================================================

wait_enter() {
    read -p "${BOLD}${MAGENTA}Presione Enter para continuar...${RESET}" </dev/tty
    lf -remote "send load" 2>/dev/null
    exit "${1:-0}"
}

confirm() {
    local prompt="$1"
    local default="${2:-n}" # y o n
    local suffix="[y/N]"

    [[ "$default" == "y" ]] && suffix="[Y/n]"

    read -p "${BOLD}${MAGENTA}${prompt} ${suffix}: ${RESET}" -r ans </dev/tty

    if [[ -z "$ans" ]]; then
        ans="$default"
    fi

    if [[ "$default" == "y" ]]; then
        [[ "$ans" != "n" && "$ans" != "N" ]]
    else
        [[ "$ans" == "y" || "$ans" == "Y" ]]
    fi
}

prompt_text() {
    local prompt="$1"
    local default="${2:-}"
    local result

    if [ -n "$default" ]; then
        read -p "${BOLD}${MAGENTA}${prompt} [${default}]: ${RESET}" -r result </dev/tty
        echo "${result:-$default}"
    else
        read -p "${BOLD}${MAGENTA}${prompt}: ${RESET}" -r result </dev/tty
        echo "$result"
    fi
}

# ============================================================================
# VALIDACIONES Y UTILIDADES
# ============================================================================

validate_not_empty() {
    if [ ${#VALID_FILES[@]} -eq 0 ]; then
        print_error "No hay archivos válidos para procesar"
        wait_enter 1
    fi
}

require_command() {
    local cmd="$1"
    if ! command -v "$cmd" &>/dev/null; then
        print_error "Comando requerido no instalado: $cmd"
        wait_enter 1
    fi
}

calculate_total_size() {
    local files=("$@")
    local total_size=0

    for file in "${files[@]}"; do
        if [ -e "$file" ]; then
            local size
            size=$(du -sb "$file" 2>/dev/null | cut -f1)
            total_size=$((total_size + size))
        fi
    done

    numfmt --to=iec "$total_size" 2>/dev/null || echo "$total_size bytes"
}

# ============================================================================
# VISUALIZACIÓN
# ============================================================================

show_header() {
    local title="$1"
    local count="${2:-0}"
    clear
    printf "%b╭── %s %s──%b\n" "${BOLD}${BLUE}" "$title" "$([ $count -gt 0 ] && echo "($count) " || echo "")" "${RESET}"
    printf "%bArchivos seleccionados:%b\n" "${BOLD}" "${RESET}"
}

show_footer() {
    local width="${1:-70}"
    local dashes=$((width - 1))
    local line=""
    for ((i = 0; i < dashes; i++)); do line="${line}─"; done
    printf "%b╰%s%b\n" "${BOLD}${BLUE}" "$line" "${RESET}"
}

show_file_list() {
    local files=("${VALID_FILES[@]}") # Usa la global si no se pasan argumentos
    if [ $# -gt 0 ]; then files=("$@"); fi

    for ((i = 0; i < ${#files[@]}; i++)); do
        printf "  %2d) %s\n" $((i + 1)) "${files[i]}"
    done
}

# ============================================================================
# FUNCIONES DE EJECUCIÓN Y GPG
# ============================================================================

run_with_progress() {
    local description="$1"
    shift
    local cmd=("$@")

    print_progress "$description"
    if "${cmd[@]}" 2>/dev/null; then
        printf "\r%b%-60s%b\n" "${GREEN}${CHECK} " "$description completado" "${RESET}"
        return 0
    else
        printf "\r%b%-60s%b\n" "${RED}${CROSS} " "Error en $description" "${RESET}"
        return 1
    fi
}

show_gpg_keys() {
    local key_type="$1" # "public" o "secret"
    local title_suffix="públicas"
    [[ "$key_type" == "secret" ]] && title_suffix="secretas"

    printf "%bClaves %s disponibles:%b\n" "${BOLD}" "$title_suffix" "${RESET}"

    gpg --list-"${key_type}"-keys --keyid-format LONG 2>/dev/null | awk '
        /^(pub|sec)/ {
            if (key_id) printf "  %s - %s\n", key_id, uid
            key_id = $2; sub(/.*\//, "", key_id); uid = ""
        }
        /^uid/ {
            uid = substr($0, index($0, "]") + 2)
            if (uid == "") uid = substr($0, 5)
        }
        END { if (key_id) printf "  %s - %s\n", key_id, uid }
    '
}
