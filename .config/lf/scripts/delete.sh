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

# Validar que se haya proporcionado al menos un archivo
if [ ${#files[@]} -eq 0 ]; then
    printf "%b%s %b%s%b\n" "${RED}${BOLD}" "${CROSS}" "${RESET}" "Error: No se proporcionó ningún archivo"
    read -p "${BOLD}${MAGENTA}Presione Enter para continuar...${RESET}" </dev/tty
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
    read -p "${BOLD}${MAGENTA}Presione Enter para continuar...${RESET}" </dev/tty
    exit 1
fi

# Calcular tamaño total
total_size=0
file_list=()
for file in "${valid_files[@]}"; do
    if [ -e "$file" ]; then
        size=$(du -sb "$file" 2>/dev/null | cut -f1)
        total_size=$((total_size + size))
        file_list+=("$file")
    fi
done
human_size=$(numfmt --to=iec $total_size)

# Encabezado
printf "%b%s%b\n" "${BOLD}${BLUE}╭── ELIMINACIÓN DE ARCHIVOS ──${RESET}"
printf "%bArchivos seleccionados (%d):%b\n" "${BOLD}" "${#file_list[@]}" "${RESET}"

# Mostrar lista de archivos
for ((i=0; i<${#file_list[@]}; i++)); do
    printf "  %2d) %s\n" $((i+1)) "${file_list[i]}"
done

printf "\n%bTamaño total: %s%b\n" "${BOLD}${CYAN}" "$human_size" "${RESET}"
printf "%b%s%b\n" "${BOLD}${BLUE}╰─────────────────────────────${RESET}"

# Confirmación
read -p "${BOLD}${MAGENTA}¿Eliminar permanentemente? [y/N]:${RESET} " ans </dev/tty

if [[ "$ans" = "y" || "$ans" = "Y" ]]; then
    errors=0
    for file in "${file_list[@]}"; do
        printf "%bEliminando %s...%b" "${MAGENTA}" "$file" "${RESET}"
        if rm -rf -- "$file"; then
            printf "\r%b%-50s %b%s%b\n" "${GREEN}" "${CHECK} $file" "${RESET}" "OK"
        else
            printf "\r%b%-50s %b%s%b\n" "${RED}" "${CROSS} $file" "${RESET}" "ERROR"
            ((errors++))
        fi
    done

    if [ $errors -eq 0 ]; then
        status="${GREEN}Todos los archivos eliminados correctamente${RESET}"
    else
        status="${RED}Completado con $errors error(es)${RESET}"
    fi

    printf "\n%b%s%b\n" "${BOLD}" "Resultado: $status" "${RESET}"
else
    printf "%b%s %b%s%b\n" "${BOLD}${MAGENTA}" "${CROSS}" "${RESET}" "Operación cancelada"
fi

# Actualizar interfaz y salir
read -p "${BOLD}${MAGENTA}Presione Enter para continuar...${RESET}" </dev/tty
lf -remote "send load"
exit 0
