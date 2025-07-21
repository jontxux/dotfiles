#!/usr/bin/env bash

# Recibir archivo como parámetro
f="$1"

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

# Verificar si GPG está instalado
if ! command -v gpg &>/dev/null; then
    printf "%b%s%b\n" "${RED}${BOLD}" "${CROSS} Error: GPG no está instalado" "${RESET}"
    read -p "${BOLD}${MAGENTA}Presione Enter para continuar...${RESET}"
    exit 1
fi

# Encabezado
printf "%b%s%b\n" "${BOLD}${BLUE}╭── ENCRIPTAR ARCHIVO ───${RESET}"
printf "%bArchivo seleccionado:%b\n" "${BOLD}" "${RESET}"
echo "  $f"
printf "%b%s%b\n" "${BOLD}${BLUE}╰────────────────────────${RESET}"

# Mostrar claves públicas disponibles
printf "%bClaves públicas disponibles:%b\n" "${BOLD}" "${RESET}"
gpg --list-public-keys --keyid-format LONG | 
    awk '
        /^pub/ {
            if (key_id) printf "  %s - %s\n", key_id, uid
            key_id = $2
            sub(/.*\//, "", key_id)   # Extraer solo el ID corto
            uid = ""
        }
        /^uid/ {
            uid = substr($0, index($0, "]") + 2)
            if (uid == "") uid = substr($0, 5)
        }
        END {
            if (key_id) printf "  %s - %s\n", key_id, uid
        }
    '

# Solicitar ID de clave del destinatario
read -p "${BOLD}${MAGENTA}ID de clave (corto) o correo: ${RESET}" key_id

if [ -z "$key_id" ]; then
    printf "%b%s%b\n" "${RED}${BOLD}" "${CROSS} Error: Debe especificar un destinatario" "${RESET}"
    read -p "${BOLD}${MAGENTA}Presione Enter para continuar...${RESET}"
    exit 1
fi

# Confirmar encriptación
read -p "${BOLD}${MAGENTA}¿Encriptar el archivo? [y/N]: ${RESET}" ans
if [ "$ans" = "y" ]; then
    output_file="$f.gpg"
    printf "%b%s%b\n" "${CYAN}⌛ Encriptando archivo...${RESET}"
    
    if gpg --encrypt --armor -r "$key_id" -o "$output_file" "$f"; then
        printf "\r%b%-50s %b%s%b\n" "${GREEN}" "${CHECK} Éxito: " "${RESET}" "Archivo encriptado: $output_file"
        lf -remote "send load"
    else
        printf "\r%b%-50s %b%s%b\n" "${RED}" "${CROSS} Error: " "${RESET}" "Fallo en la encriptación"
    fi
else
    printf "%b%s%b\n" "${MAGENTA}" "${CROSS} Operación cancelada" "${RESET}"
fi

read -p "${BOLD}${MAGENTA}Presione Enter para continuar...${RESET}"
