#!/usr/bin/env bash

# Recibir archivo como parámetro
fx="$1"

# Configuración de estilos (se mantienen igual)
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

# Encabezado
printf "%b%s%b\n" "${BOLD}${BLUE}╭── EXTRAER ARCHIVO ───${RESET}"
printf "%bArchivo seleccionado:%b\n" "${BOLD}" "${RESET}"
echo "  $fx"
printf "%b%s%b\n" "${BOLD}${BLUE}╰──────────────────────${RESET}"

# Confirmación
read -p "${BOLD}${MAGENTA}¿Extraer archivo? [y/N]: ${RESET}" ans

if [ "$ans" = "y" ]; then
    # Directorio destino
    read -p "${BOLD}${MAGENTA}Ruta destino (dejar vacío para actual): ${RESET}" directorio_destino

    # Validación y formato del directorio
    directorio_destino="${directorio_destino:-./}"
    [[ "$directorio_destino" != */ ]] && directorio_destino+="/"

    # Crear directorio si no existe
    if [ ! -d "$directorio_destino" ]; then
        printf "%bCreando directorio: %s%b\n" "${CYAN}" "$directorio_destino" "${RESET}"
        mkdir -p "$directorio_destino" || {
            printf "%b%s %b%s%b\n" "${RED}${BOLD}" "${CROSS}" "${RESET}" "Error creando directorio"
            read -p "${BOLD}${MAGENTA}Presione Enter para continuar...${RESET}"
            exit 1
        }
    fi

    # Proceso de extracción
    printf "\n%b%s%b\n" "${CYAN}⌛ Extrayendo archivos...${RESET}"

    case "$fx" in
        *.tar.bz2|*.tbz2)  cmd="tar xjvf '${fx}' -C '${directorio_destino}'" ;;
        *.tar.gz|*.tgz)    cmd="tar xzvf '${fx}' -C '${directorio_destino}'" ;;
        *.bz2)             cmd="bunzip2 -kc '${fx}' > '${directorio_destino}${fx##*/}'" ;;
        *.rar)             cmd="unrar x '${fx}' '${directorio_destino}'" ;;
        *.gz)              cmd="gunzip -c '${fx}' > '${directorio_destino}${fx##*/}'" ;;
        *.tar)             cmd="tar xvf '${fx}' -C '${directorio_destino}'" ;;
        *.zip)             cmd="unzip -q '${fx}' -d '${directorio_destino}'" ;;
        *.Z)               cmd="uncompress -c '${fx}' > '${directorio_destino}${fx##*/}'" ;;
        *.7z)              cmd="7z x -y '${fx}' -o'${directorio_destino}'" ;;
        *.tar.xz)          cmd="tar xvf '${fx}' -C '${directorio_destino}'" ;;
        *)                 cmd="echo 'Formato no soportado'" ;;
    esac

    # Ejecutar y mostrar resultado
    if eval "$cmd"; then
        printf "\r%b%-50s %b%s%b\n" "${GREEN}" "${CHECK} Éxito: " "${RESET}" "Extracción completada"
        read -p "${BOLD}${MAGENTA}Presione Enter para continuar...${RESET}"
        lf -remote "send load"
    else
        printf "\r%b%-50s %b%s%b\n" "${RED}" "${CROSS} Error: " "${RESET}" "Fallo en la extracción"
        read -p "${BOLD}${MAGENTA}Presione Enter para continuar...${RESET}"
        exit 1
    fi
else
    printf "%b%s%b\n" "${MAGENTA}" "${CROSS} Operación cancelada" "${RESET}"
    sleep 1
    exit 0
fi
