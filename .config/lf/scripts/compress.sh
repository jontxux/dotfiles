#!/usr/bin/env bash

# Recibir múltiples archivos como parámetros
files=("$@")

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

# Validar que se haya proporcionado al menos un archivo
if [ ${#files[@]} -eq 0 ]; then
    printf "%b%s %b%s%b\n" "${RED}${BOLD}" "${CROSS}" "${RESET}" "Error: No se proporcionó ningún archivo"
    read -p "${BOLD}${MAGENTA}Presione Enter para continuar...${RESET}"
    exit 1
fi

# Validar que los archivos existan
valid_files=()
for file in "${files[@]}"; do
    if [ ! -e "$file" ]; then
        printf "%b%s %b%s%b\n" "${RED}${BOLD}" "${CROSS}" "${RESET}" "Error: El archivo no existe: $file"
    else
        valid_files+=("$file")
    fi
done

# Si no hay archivos válidos, salir
if [ ${#valid_files[@]} -eq 0 ]; then
    read -p "${BOLD}${MAGENTA}Presione Enter para continuar...${RESET}"
    exit 1
fi

# Encabezado
printf "%b%s%b\n" "${BOLD}${BLUE}╭── COMPRIMIR ARCHIVOS ──${RESET}"
printf "%bArchivos seleccionados (%d):%b\n" "${BOLD}" "${#valid_files[@]}" "${RESET}"

# Mostrar lista de archivos
for ((i=0; i<${#valid_files[@]}; i++)); do
    printf "  %2d) %s\n" $((i+1)) "${valid_files[i]}"
done

printf "%b%s%b\n" "${BOLD}${BLUE}╰──────────────────────────${RESET}"

# Solicitar nombre del comprimido
read -p "${BOLD}${MAGENTA}Nombre del archivo comprimido: ${RESET}" nombre_comprimido

if [ -z "$nombre_comprimido" ]; then
    printf "\n%b%s %b%s%b\n" "${RED}${BOLD}" "${CROSS}" "${RESET}" "Error: Nombre no proporcionado"
    read -p "${BOLD}${MAGENTA}Presione Enter para continuar...${RESET}"
    exit 1
fi

# Convertir a rutas relativas
current_dir=$(pwd)
relative_files=()
for file in "${valid_files[@]}"; do
    relative_files+=("$(realpath --relative-to="$current_dir" "$file")")
done

# Determinar comando según extensión
case "$nombre_comprimido" in
    *.zip)      cmd=(zip -r "$nombre_comprimido" "${relative_files[@]}") ;;
    *.tar.gz|*.tgz) cmd=(tar -czvf "$nombre_comprimido" "${relative_files[@]}") ;;
    *.tar.xz)   cmd=(tar -cJvf "$nombre_comprimido" "${relative_files[@]}") ;;
    *.tar.bz2|*.tbz2) cmd=(tar -cjvf "$nombre_comprimido" "${relative_files[@]}") ;;
    *.7z)       cmd=(7z a "$nombre_comprimido" "${relative_files[@]}") ;;
    *.rar)      cmd=(rar a "$nombre_comprimido" "${relative_files[@]}") ;;
    *)
        printf "\n%b%s %b%s%b\n" "${RED}${BOLD}" "${CROSS}" "${RESET}" "Error: Extensión no soportada"
        printf "%bFormatos válidos: .zip, .tar.gz, .tgz, .tar.xz, .tar.bz2, .tbz2, .7z, .rar%b\n" "${CYAN}" "${RESET}"
        read -p "${BOLD}${MAGENTA}Presione Enter para continuar...${RESET}"
        exit 1
        ;;
esac

# Ejecutar compresión
printf "\n%b%s%b\n" "${CYAN}⌛ Comprimiendo archivos...${RESET}"
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
