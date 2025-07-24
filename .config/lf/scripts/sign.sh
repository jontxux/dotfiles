#!/bin/bash

# Argumentos: [ID de instancia lf] [archivo a firmar]
LF_ID="$1"
FILE="$2"

# Validación básica
[ -f "$FILE" ] || {
    echo "Error: Archivo no válido"
    exit 1
}

# Configuración de colores
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

# Verificar GPG
if ! command -v gpg &>/dev/null; then
    printf "%b%s%b\n" "${RED}${BOLD}" "${CROSS} Error: GPG no está instalado" "${RESET}"
    read -p "${BOLD}${MAGENTA}Presione Enter para continuar...${RESET}"
    exit 1
fi

# Interfaz de usuario
printf "%b%s%b\n" "${BOLD}${BLUE}╭── FIRMAR ARCHIVO ───${RESET}"
printf "%bArchivo seleccionado:%b\n" "${BOLD}" "${RESET}"
echo "  $FILE"
printf "%b%s%b\n" "${BOLD}${BLUE}╰──────────────────────${RESET}"

# Mostrar claves
printf "%bClaves GPG disponibles:%b\n" "${BOLD}" "${RESET}"
gpg --list-secret-keys --keyid-format LONG | awk '/uid/{print "  " $0}'

# Solicitar ID de clave
read -p "${BOLD}${MAGENTA}ID de clave GPG (dejar vacío para predeterminada): ${RESET}" key_id

# Confirmación
read -p "${BOLD}${MAGENTA}¿Firmar el archivo? [y/N]: ${RESET}" ans
if [ "$ans" != "y" ] && [ "$ans" != "Y" ]; then
    printf "%b%s%b\n" "${MAGENTA}" "${CROSS} Operación cancelada" "${RESET}"
    read -p "${BOLD}${MAGENTA}Presione Enter para continuar...${RESET}"
    exit 0
fi

# Construir comando
if [ -z "$key_id" ]; then
    cmd="gpg --detach-sign --armor \"$FILE\""
    output_file="$FILE.asc"
else
    cmd="gpg --detach-sign --armor -u \"$key_id\" \"$FILE\""
    output_file="$FILE.$key_id.asc"
fi

# Ejecutar
printf "%b%s%b\n" "${CYAN}⌛ Firmando archivo...${RESET}"
if eval "$cmd"; then
    printf "\r%b%-50s %b%s%b\n" "${GREEN}" "${CHECK} Éxito: " "${RESET}" "Firma creada: $output_file"
    [ -n "$LF_ID" ] && lf -remote "send $LF_ID load"
else
    printf "\r%b%-50s %b%s%b\n" "${RED}" "${CROSS} Error: " "${RESET}" "Fallo en la firma"
fi

read -p "${BOLD}${MAGENTA}Presione Enter para continuar...${RESET}"
