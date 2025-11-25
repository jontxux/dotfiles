#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/liblf.sh"

main() {
    # 1. Cargar y validar
    load_files "$@"
    filter_valid_files
    validate_not_empty

    # 2. UI
    show_header "COMPRIMIR ARCHIVOS" "${#VALID_FILES[@]}"
    show_file_list
    show_footer 50

    # 3. Solicitar nombre
    local nombre_comprimido
    nombre_comprimido=$(prompt_text "Nombre del archivo comprimido")

    if [ -z "$nombre_comprimido" ]; then
        print_error "Nombre no proporcionado"
        wait_enter 1
    fi

    # 4. Rutas relativas
    local current_dir
    current_dir=$(pwd)
    local relative_files=()
    for file in "${VALID_FILES[@]}"; do
        relative_files+=("$(realpath --relative-to="$current_dir" "$file")")
    done

    # 5. Determinar comando
    local cmd=()
    case "$nombre_comprimido" in
        *.zip)            cmd=(zip -r "$nombre_comprimido" "${relative_files[@]}") ;;
        *.tar.gz|*.tgz)   cmd=(tar -czvf "$nombre_comprimido" "${relative_files[@]}") ;;
        *.tar.xz)         cmd=(tar -cJvf "$nombre_comprimido" "${relative_files[@]}") ;;
        *.tar.bz2|*.tbz2) cmd=(tar -cjvf "$nombre_comprimido" "${relative_files[@]}") ;;
        *.7z)             cmd=(7z a "$nombre_comprimido" "${relative_files[@]}") ;;
        *.rar)            cmd=(rar a "$nombre_comprimido" "${relative_files[@]}") ;;
        *)
            print_error "Extensión no soportada"
            print_info "Formatos: .zip, .tar.gz, .tgz, .tar.xz, .tar.bz2, .tbz2, .7z, .rar"
            wait_enter 1
            ;;
    esac

    # 6. Ejecutar
    if run_with_progress "Comprimiendo archivos" "${cmd[@]}"; then
        print_success "Archivo creado: $nombre_comprimido"
        lf -remote "send load" 2>/dev/null
    else
        print_error "Fallo en la compresión"
    fi

    wait_enter
}

main "$@"
