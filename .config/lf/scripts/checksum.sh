#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/liblf.sh"

main() {
    # 1. Cargar y validar
    load_files "$@"
    filter_valid_files
    validate_not_empty

    # 2. UI
    show_header "CALCULAR CHECKSUM" "${#VALID_FILES[@]}"
    show_file_list
    show_footer 50

    # 3. Menú
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

    # 4. Procesar
    print_info "Calculando checksums..."
    local all_success=true
    local result

    for file in "${VALID_FILES[@]}"; do
        # Usamos awk para obtener solo el hash
        result=$($checksum_cmd "$file" 2>/dev/null | awk '{print $1}')

        if [ $? -eq 0 ]; then
            printf "%b%s:%b %s\n" "${BOLD}${CYAN}" "$(basename "$file")" "${RESET}" "$result"
        else
            print_error "Fallo al calcular: $(basename "$file")"
            all_success=false
        fi
    done

    echo ""
    if [ "$all_success" = true ]; then
        print_success "Todos los checksums calculados con éxito"
    else
        print_warning "Hubo errores en algunos archivos"
    fi

    wait_enter
}

main "$@"
