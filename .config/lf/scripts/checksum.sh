#!/usr/bin/env bash

# Recibir archivos como parámetros
files="$1"

# Si solo hay un parámetro y contiene saltos de línea, dividirlo
if [ ${#files[@]} -eq 1 ] && [[ "${files[0]}" == *$'\n'* ]]; then
    IFS=$'\n' read -d '' -r -a files <<< "${files[0]}"
fi

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

# Validar que existan archivos
if [ ${#files[@]} -eq 0 ]; then
    printf "%b%s %b%s%b\n" "${RED}${BOLD}" "${CROSS}" "${RESET}" "Error: No hay archivos para procesar"
    read -p "${BOLD}${MAGENTA}Presione Enter para continuar...${RESET}"
    exit 1
fi

# Encabezado
printf "%b%s%b\n" "${BOLD}${BLUE}╭── CALCULAR CHECKSUM ──${RESET}"
printf "%bArchivos seleccionados:%b\n" "${BOLD}" "${RESET}"
for file in "${files[@]}"; do
    printf "  %s\n" "$file"
done
printf "%b%s%b\n" "${BOLD}${BLUE}╰────────────────────────${RESET}"

# Selección de algoritmo
printf "\nSeleccione algoritmo:\n"
printf "1) MD5\n"
printf "2) SHA256\n"
printf "3) SHA1\n"
read -p "${BOLD}${MAGENTA}Opción: ${RESET}" algo

case $algo in
    1) checksum="md5sum" ;;
    2) checksum="sha256sum" ;;
    3) checksum="sha1sum" ;;
    *)
        printf "\n%b%s %b%s%b\n" "${RED}${BOLD}" "${CROSS}" "${RESET}" "Error: Opción inválida"
        read -p "${BOLD}${MAGENTA}Presione Enter para continuar...${RESET}"
        exit 1
        ;;
esac

# Procesar archivos
printf "\n%b%s%b\n" "${CYAN}⌛ Calculando checksums...${RESET}"
all_success=true
for file in "${files[@]}"; do
    if [ ! -e "$file" ]; then
        printf "\n%b%s %b%s%b\n" "${RED}${BOLD}" "${CROSS}" "${RESET}" "Error: Archivo no encontrado: $file"
        all_success=false
        continue
    fi
    
    result=$($checksum "$file" 2>/dev/null | awk '{print $1}')
    if [ $? -eq 0 ]; then
        printf "\n%b%s%b\n" "${BOLD}${CYAN}$file:${RESET}"
        printf "%s\n" "$result"
    else
        printf "\n%b%s %b%s%b\n" "${RED}${BOLD}" "${CROSS}" "${RESET}" "Error: Fallo al calcular $file"
        all_success=false
    fi
done

# Mensaje final
if [ "$all_success" = true ]; then
    printf "\n%b%s %b%s%b\n" "${GREEN}${BOLD}" "${CHECK}" "${RESET}" "Todos los checksums calculados con éxito"
else
    printf "\n%b%s %b%s%b\n" "${RED}${BOLD}" "${CROSS}" "${RESET}" "Hubo errores en algunos archivos"
fi

# Actualizar interfaz y salir
read -p "${BOLD}${MAGENTA}Presione Enter para continuar...${RESET}"
lf -remote "send load"
exit 0
