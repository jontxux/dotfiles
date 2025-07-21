#!/usr/bin/env bash

# Recibir archivo como parámetro
fx="$1"

# Configuración de estilos
BOLD=$(tput bold)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
GREEN=$(tput setaf 2)
RED=$(tput setaf 1)
RESET=$(tput sgr0)
CHECK=$'\u2713'  # ✓
CROSS=$'\u2717'  # ✗

clear
set -f

# Validar que se haya proporcionado un archivo
if [ -z "$fx" ]; then
    printf "%b%s %b%s%b\n" "${RED}${BOLD}" "${CROSS}" "${RESET}" "Error: No se proporcionó ningún archivo"
    read -p "${BOLD}${MAGENTA}Presione Enter para continuar...${RESET}"
    exit 1
fi

# Validar que el archivo exista
if [ ! -e "$fx" ]; then
    printf "%b%s %b%s%b\n" "${RED}${BOLD}" "${CROSS}" "${RESET}" "Error: El archivo no existe: $fx"
    read -p "${BOLD}${MAGENTA}Presione Enter para continuar...${RESET}"
    exit 1
fi

# Encabezado
printf "%b%s%b\n" "${BOLD}${BLUE}╭── COMPRIMIR ARCHIVOS ──${RESET}"
printf "%bArchivo seleccionado:%b\n" "${BOLD}" "${RESET}"
echo "  $fx"
printf "%b%s%b\n" "${BOLD}${BLUE}╰──────────────────────────${RESET}"

# Solicitar nombre del comprimido
read -p "${BOLD}${MAGENTA}Nombre del archivo comprimido: ${RESET}" nombre_comprimido

if [ -z "$nombre_comprimido" ]; then
    printf "\n%b%s %b%s%b\n" "${RED}${BOLD}" "${CROSS}" "${RESET}" "Error: Nombre no proporcionado"
    read -p "${BOLD}${MAGENTA}Presione Enter para continuar...${RESET}"
    exit 1
fi

# Convertir a ruta relativa
current_dir=$(pwd)
relative_file=$(realpath --relative-to="$current_dir" "$fx")

# Determinar comando según extensión
case "$nombre_comprimido" in
    *.zip)      cmd=(zip -j "$nombre_comprimido" "$relative_file") ;;
    *.tar.gz|*.tgz) cmd=(tar -czvf "$nombre_comprimido" "$relative_file") ;;
    *.tar.xz)   cmd=(tar -cJvf "$nombre_comprimido" "$relative_file") ;;
    *.tar.bz2|*.tbz2) cmd=(tar -cjvf "$nombre_comprimido" "$relative_file") ;;
    *.7z)       cmd=(7z a "$nombre_comprimido" "$relative_file") ;;
    *.rar)      cmd=(rar a "$nombre_comprimido" "$relative_file") ;;
    *)
        printf "\n%b%s %b%s%b\n" "${RED}${BOLD}" "${CROSS}" "${RESET}" "Error: Extensión no soportada"
        printf "%bFormatos válidos: .zip, .tar.gz, .tgz, .tar.xz, .tar.bz2, .tbz2, .7z, .rar%b\n" "${CYAN}" "${RESET}"
        read -p "${BOLD}${MAGENTA}Presione Enter para continuar...${RESET}"
        exit 1
        ;;
esac

# Ejecutar compresión
printf "\n%b%s%b\n" "${CYAN}⌛ Comprimiendo archivo...${RESET}"
if "${cmd[@]}" 2>/dev/null; then
    printf "\r%b%s %b%s%b\n" "${GREEN}${BOLD}" "${CHECK}" "${RESET}" "Éxito: Archivo creado: $nombre_comprimido"
else
    error_msg=$("${cmd[@]}" 2>&1)
    printf "\r%b%s %b%s%b\n" "${RED}${BOLD}" "${CROSS}" "${RESET}" "Error: Fallo en la compresión"
    printf "\n%bDetalles:%b\n" "${BOLD}" "${RESET}"
    echo "$error_msg" | sed 's/^/  /'
fi

# Actualizar interfaz y salir
read -p "${BOLD}${MAGENTA}Presione Enter para continuar...${RESET}"
lf -remote "send load"
exit 0
