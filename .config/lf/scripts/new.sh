#!/bin/bash

# Obtener ID de lf
lf_id="$1"

# Generar códigos ANSI
BOLD=$(tput bold)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
GREEN=$(tput setaf 2)
RESET=$(tput sgr0)
CHECK=$'\u2713'  # ✓
CROSS=$'\u2717'  # ✗

clear
printf "%b%s%b\n" "${BOLD}${BLUE}╭── NUEVO ARCHIVO ────${RESET}"
read -p "${BOLD}${MAGENTA}Nombre del archivo: ${RESET}" nombre_archivo
printf "%b%s%b\n" "${BOLD}${BLUE}╰─────────────────────${RESET}"

if [ -z "$nombre_archivo" ]; then
    printf "\n%b%-50s %b%s%b\n" "${CYAN}" "${CROSS} Error: " "${RESET}" "Nombre no válido"
    read -p "${BOLD}${MAGENTA}Presione Enter para continuar...${RESET}"
    exit 1
fi

if [ -e "$nombre_archivo" ]; then
    printf "\n%b%-50s %b%s%b\n" "${CYAN}" "${CROSS} Error: " "${RESET}" "El archivo ya existe"
    read -p "${BOLD}${MAGENTA}Presione Enter para continuar...${RESET}"
    exit 1
fi

if touch "$nombre_archivo"; then
    printf "\n%b%-50s %b%s%b\n" "${GREEN}" "${CHECK} Éxito: " "${RESET}" "Archivo creado: $nombre_archivo"
    read -p "${BOLD}${MAGENTA}Presione Enter para continuar...${RESET}"
    # Enviar comandos a lf
    lf -remote "send $lf_id select \"$nombre_archivo\""
    lf -remote "send load"
else
    printf "\n%b%-50s %b%s%b\n" "${CYAN}" "${CROSS} Error: " "${RESET}" "No se pudo crear el archivo"
    read -p "${BOLD}${MAGENTA}Presione Enter para continuar...${RESET}"
    exit 1
fi
