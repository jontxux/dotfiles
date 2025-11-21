#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/liblf.sh"

main() {
    # Procesar argumentos
    local files
    files=($(process_arguments "$@"))

    # Validar
    local valid_files
    valid_files=($(validate_files "${files[@]}"))
    validate_not_empty valid_files

    # UI
    show_header "CALCULAR CHECKSUM" "${#valid_files[@]}"
    show_file_list "${valid_files[@]}"
    show_footer 50

    # Menú de selección
    print_info "Seleccione algoritmo:"
    printf "  1) MD5\n  2) SHA256\n  3) SHA1\n\n"

    local algo
    algo=$(prompt_text "Opción")
    local checksum_cmd=""

    case $algo in
        1) checksum_cmd="md5sum" ;;
        2) checksum_cmd="sha256sum" ;;
        3) checksum_cmd="sha1sum" ;;
        *)
            print_error "Opción inválida"
            wait_enter 1
            ;;
    esac

    # Procesar
    print_info "Calculando checksums..."
    local all_success=true
    local result

    for file in "${valid_files[@]}"; do
        # Usamos awk para obtener solo el hash
        result=$($checksum_cmd "$file" 2>/dev/null | awk '{print $1}')

        if [ $? -eq 0 ]; then
            # Formato personalizado: Nombre archivo -> Hash
            printf "%b%s:%b %s\n" "${BOLD}${CYAN}" "$(basename "$file")" "${RESET}" "$result"
        else
            print_error "Fallo al calcular: $file"
            all_success=false
        fi
    done

    echo "" # Salto de línea estético
    if [ "$all_success" = true ]; then
        print_success "Todos los checksums calculados con éxito"
    else
        print_warning "Hubo errores en algunos archivos"
    fi

    wait_enter
}

main "$@"
