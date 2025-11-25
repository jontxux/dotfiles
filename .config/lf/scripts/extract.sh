#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/liblf.sh"

get_extract_command() {
    local file="$1"
    local dest="$2"

    case "$file" in
        *.tar.bz2|*.tbz2)  echo "tar xjvf '$file' -C '$dest'" ;;
        *.tar.gz|*.tgz)    echo "tar xzvf '$file' -C '$dest'" ;;
        *.bz2)             echo "bunzip2 -kc '$file' > '$dest${file##*/}'" ;;
        *.rar)             echo "unrar x '$file' '$dest'" ;;
        *.gz)              echo "gunzip -c '$file' > '$dest${file##*/}'" ;;
        *.tar)             echo "tar xvf '$file' -C '$dest'" ;;
        *.zip)             echo "unzip -q '$file' -d '$dest'" ;;
        *.Z)               echo "uncompress -c '$file' > '$dest${file##*/}'" ;;
        *.7z)              echo "7z x -y '$file' -o'$dest'" ;;
        *.tar.xz)          echo "tar xvf '$file' -C '$dest'" ;;
        *)                 return 1 ;;
    esac
}

main() {
    # 1. Cargar y validar
    load_files "$@"
    filter_valid_files
    validate_not_empty

    # Tomamos el primer archivo válido (si seleccionaste varios, extrae el primero)
    local file="${VALID_FILES[0]}"

    # 2. UI
    show_header "EXTRAER ARCHIVO"
    printf "  %s\n" "$(basename "$file")"
    show_footer 50

    if ! confirm "¿Extraer archivo?" "y"; then
        print_error "Operación cancelada"
        wait_enter 0
    fi

    # 3. Solicitar destino
    local dest
    dest=$(prompt_text "Ruta destino" "./")
    dest="${dest%/}/"

    if [ ! -d "$dest" ]; then
        print_info "Creando directorio: $dest"
        mkdir -p "$dest" || { print_error "Error creando directorio"; wait_enter 1; }
    fi

    # 4. Obtener comando
    local cmd
    cmd=$(get_extract_command "$file" "$dest")
    if [ $? -ne 0 ]; then
        print_error "Formato no soportado: $(basename "$file")"
        wait_enter 1
    fi

    # 5. Ejecutar
    if run_with_progress "Extrayendo" bash -c "$cmd"; then
        print_success "Extracción completada"
        lf -remote "send load" 2>/dev/null
    fi

    wait_enter
}

main "$@"
