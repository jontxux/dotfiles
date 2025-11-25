#!/usr/bin/env bash
# libstyle.sh - Librería centralizada de estilos y colores

# ============================================================================
# COLORES Y ESTILOS ANSI
# ============================================================================

declare -gx BOLD=$(tput bold)
declare -gx DIM=$(tput dim)
declare -gx RESET=$(tput sgr0)

# Colores de texto
declare -gx BLACK=$(tput setaf 0)
declare -gx RED=$(tput setaf 1)
declare -gx GREEN=$(tput setaf 2)
declare -gx YELLOW=$(tput setaf 3)
declare -gx BLUE=$(tput setaf 4)
declare -gx MAGENTA=$(tput setaf 5)
declare -gx CYAN=$(tput setaf 6)
declare -gx WHITE=$(tput setaf 7)

# Símbolos Unicode
declare -gx CHECK=$'\u2713'     # ✓
declare -gx CROSS=$'\u2717'     # ✗
declare -gx ARROW=$'\u27a0'     # ➠
declare -gx BULLET=$'\u2022'    # •
declare -gx HOURGLASS=$'\u231b' # ⌛

# ============================================================================
# FUNCIONES DE FORMATO
# ============================================================================

# Imprimir con color
print_color() {
    local color="$1"
    local text="$2"
    printf "%b%s%b\n" "${color}" "${text}" "${RESET}"
}

# Imprimir línea de progreso
print_progress() {
    local text="$1"
    printf "%b%s%b " "${CYAN}${HOURGLASS}" "${text}" "${RESET}"
}

# Imprimir éxito
print_success() {
    local text="$1"
    printf "%b%s %b%s%b\n" "${GREEN}${BOLD}" "${CHECK}" "${RESET}" "${text}"
}

# Imprimir error
print_error() {
    local text="$1"
    printf "%b%s %b%s%b\n" "${RED}${BOLD}" "${CROSS}" "${RESET}" "${text}"
}

# Imprimir advertencia
print_warning() {
    local text="$1"
    printf "%b%s %b%s%b\n" "${YELLOW}${BOLD}" "!" "${RESET}" "${text}"
}

# Imprimir información
print_info() {
    local text="$1"
    printf "%b%s %b%s%b\n" "${CYAN}${BOLD}" "i" "${RESET}" "${text}"
}

# Imprimir separador
print_separator() {
    local char="${1:─}"
    local width="${2:-80}"
    printf "%b" "${BLUE}${BOLD}"
    printf '%*s\n' "$width" | tr ' ' "$char"
    printf "%b" "${RESET}"
}
