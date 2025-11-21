#!/usr/bin/env bash
# liblf.sh - Librería común para scripts de lf (versión mejorada)

# Importar librería de estilos
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "$SCRIPT_DIR/libstyle.sh"

# ============================================================================
# FUNCIONES DE ENTRADA/SALIDA
# ============================================================================

# Esperar entrada del usuario
wait_enter() {
    read -p "${BOLD}${MAGENTA}Presione Enter para continuar...${RESET}" </dev/tty
    lf -remote "send load" 2>/dev/null
    exit "${1:-0}"
}

# Solicitar confirmación
confirm() {
    local prompt="$1"
    local default="${2:-n}"  # y o n
    local suffix="[y/N]"

    [[ "$default" == "y" ]] && suffix="[Y/n]"

    read -p "${BOLD}${MAGENTA}${prompt} ${suffix}: ${RESET}" -r ans </dev/tty

    if [[ "$default" == "y" ]]; then
        [[ "$ans" != "n" && "$ans" != "N" ]]
    else
        [[ "$ans" == "y" || "$ans" == "Y" ]]
    fi
}

# Solicitar entrada de texto
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
# FUNCIONES DE VALIDACIÓN
# ============================================================================

# Procesar argumentos y detectar saltos de línea
process_arguments() {
    local files=("$@")
    if [ ${#files[@]} -eq 1 ] && [[ "${files[0]}" == *$'\n'* ]]; then
        IFS=$'\n' read -d '' -r -a files <<< "${files[0]}"
    fi
    echo "${files[@]}"
}

# Validar existencia de archivos
validate_files() {
    local files=("$@")
    local valid_files=()

    for file in "${files[@]}"; do
        if [ -e "$file" ]; then
            valid_files+=("$file")
        else
            print_error "Archivo no existe: $file"
        fi
    done

    echo "${valid_files[@]}"
}

# Validar que exista al menos un archivo
validate_not_empty() {
    local -n arr=$1
    if [ ${#arr[@]} -eq 0 ]; then
        print_error "No se proporcionó ningún archivo"
        wait_enter 1
    fi
}

# Validar que un comando esté instalado
require_command() {
    local cmd="$1"
    if ! command -v "$cmd" &>/dev/null; then
        print_error "Comando requerido no está instalado: $cmd"
        wait_enter 1
    fi
}

# ============================================================================
# FUNCIONES DE VISUALIZACIÓN
# ============================================================================

# Mostrar encabezado
show_header() {
    local title="$1"
    local count="${2:-0}"
    clear
    printf "%b╭── %s %s──%b\n" "${BOLD}${BLUE}" "$title" "$([ $count -gt 0 ] && echo "($count) " || echo "")" "${RESET}"
    printf "%bArchivos seleccionados:%b\n" "${BOLD}" "${RESET}"
}

# Mostrar pie de página
show_footer() {
    local width="${1:-70}"
    local dashes=$((width - 1))
    local line=""
    for ((i = 0; i < dashes; i++)); do
        line="${line}─"
    done
    printf "%b╰%s%b\n" "${BOLD}${BLUE}" "$line" "${RESET}"
}

# Mostrar lista de archivos con índices
show_file_list() {
    local files=("$@")
    for ((i = 0; i < ${#files[@]}; i++)); do
        printf "  %2d) %s\n" $((i + 1)) "${files[i]}"
    done
}

# Mostrar tabla de dos columnas
show_two_column() {
    local label="$1"
    local value="$2"
    local col_width=30
    printf "%b%-${col_width}s:%b %s\n" "${BOLD}${CYAN}" "$label" "${RESET}" "$value"
}

# ============================================================================
# FUNCIONES DE CÁLCULO Y UTILIDAD
# ============================================================================

# Calcular tamaño total de archivos
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

# Contar archivos y directorios
count_items() {
    local files=("$@")
    local files_count=0
    local dirs_count=0

    for item in "${files[@]}"; do
        if [ -d "$item" ]; then
            ((dirs_count++))
        else
            ((files_count++))
        fi
    done

    echo "$files_count ficheros, $dirs_count directorios"
}

# Obtener extensión de archivo
get_extension() {
    local file="$1"
    echo "${file##*.}"
}

# Verificar si es archivo comprimido
is_compressed() {
    local file="$1"
    case "$file" in
        *.tar.bz2 | *.tbz2 | *.tar.gz | *.tgz | *.tar.xz | *.tar | \
        *.zip | *.rar | *.7z | *.bz2 | *.gz | *.Z)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# ============================================================================
# FUNCIONES DE MANEJO DE ERRORES
# ============================================================================

# Ejecutar comando con manejo de errores
run_command() {
    local cmd=("$@")

    if "${cmd[@]}" 2>/dev/null; then
        return 0
    else
        local error_msg
        error_msg=$("${cmd[@]}" 2>&1)
        print_error "Fallo en la ejecución"
        printf "%bDetalles:%b\n" "${BOLD}" "${RESET}"
        echo "$error_msg" | sed 's/^/  /'
        return 1
    fi
}

# Ejecutar con barra de progreso
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
