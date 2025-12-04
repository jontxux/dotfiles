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

    # Primero filtramos argumentos que sean sólo números (LF server id)
    local args=("$@")

    # Si no hay argumentos tras filtrar, dejamos FILES vacío
    if [ ${#args[@]} -eq 0 ]; then
        FILES=()
        return
    fi

    # Si LF pasa una lista en un solo argumento con saltos de línea, expandimos
    if [ ${#args[@]} -eq 1 ] && [[ "${args[0]}" == *$'\n'* ]]; then
        IFS=$'\n' read -d '' -r -a FILES <<< "${args[0]}"
    else
        FILES=("${args[@]}")
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

DEFAULT_BOX_WIDTH=${DEFAULT_BOX_WIDTH:-50}
FILE_LIST_INDENT="${FILE_LIST_INDENT:-  }"

show_header() {
    local title="$1"
    local count="${2:-0}"
    local width="${3:-$DEFAULT_BOX_WIDTH}"

    local title_text="$title"
    if [[ -n "$count" && "$count" -gt 0 ]]; then
        title_text="$title ($count)"
    fi

    clear

    # Construimos la parte inicial que irá tras el '╭'
    local prefix="── "
    local content="${prefix}${title_text}"
    local content_len=${#content}

    # Queremos que el contenido tras el '╭' mida exactamente (width - 1)
    local target=$(( width - 1 ))
    if [ "$content_len" -gt "$target" ]; then
        # Si el título es más largo que el objetivo, ampliamos el objetivo
        target=$content_len
        width=$(( target + 1 ))
    fi

    local pad=$(( target - content_len ))
    local dashes=""
    if [ "$pad" -gt 0 ]; then
        printf -v dashes '%*s' "$pad"
        dashes=${dashes// /─}
    fi

    content="${content}${dashes}"

    # Imprimimos la línea superior y la etiqueta de archivos con la indentación
    printf "%b╭%s%b\n" "${BOLD}${BLUE}" "$content" "${RESET}"
    printf "%s%bArchivos seleccionados:%b\n" "$FILE_LIST_INDENT" "${BOLD}" "${RESET}"

    # Guardar ancho actual para que show_footer lo use si no se pasa explicitamente
    export LAST_HEADER_WIDTH="$width"
}

show_footer() {
    local width="${1:-${LAST_HEADER_WIDTH:-$DEFAULT_BOX_WIDTH}}"
    local len=$(( width - 1 ))
    if [ "$len" -lt 0 ]; then len=0; fi

    local line=""
    if [ "$len" -gt 0 ]; then
        printf -v line '%*s' "$len"
        line=${line// /─}
    fi

    printf "%b╰%s%b\n" "${BOLD}${BLUE}" "$line" "${RESET}"
}

show_file_list() {
    local files=("${VALID_FILES[@]}")
    if [ $# -gt 0 ]; then files=("$@"); fi

    for ((i = 0; i < ${#files[@]}; i++)); do
        printf "%s%2d) %s\n" "$FILE_LIST_INDENT" $((i + 1)) "${files[i]}"
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
