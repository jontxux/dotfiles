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

    # Calcular datos extra
    local human_size
    human_size=$(calculate_total_size "${valid_files[@]}")

    # UI
    show_header "ELIMINACIÓN DE ARCHIVOS" "${#valid_files[@]}"
    show_file_list "${valid_files[@]}"
    printf "\n%bTamaño total: %s%b\n" "${BOLD}${CYAN}" "$human_size" "${RESET}"
    show_footer 50

    # Confirmación estandarizada
    if ! confirm "¿Eliminar permanentemente?" "n"; then
        print_error "Operación cancelada"
        wait_enter 0
    fi

    # Proceso de eliminación
    local errors=0
    for file in "${valid_files[@]}"; do
        if rm -rf -- "$file"; then
            print_success "Eliminado: $file"
        else
            print_error "Error al eliminar: $file"
            ((errors++))
        fi
    done

    echo ""
    if [ $errors -eq 0 ]; then
        print_success "Todos los archivos eliminados correctamente"
        lf -remote "send load" 2>/dev/null
    else
        print_warning "Completado con $errors error(es)"
    fi

    wait_enter
}

main "$@"
