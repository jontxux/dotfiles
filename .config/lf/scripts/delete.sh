#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/liblf.sh"

main() {
    # 1. Cargar y validar
    load_files "$@"
    filter_valid_files
    validate_not_empty

    # 2. Calcular datos extra
    # Nota: calculate_total_size debe esperar argumentos, se los pasamos expandidos
    local human_size
    human_size=$(calculate_total_size "${VALID_FILES[@]}")

    # 3. UI
    show_header "ELIMINACIÓN DE ARCHIVOS" "${#VALID_FILES[@]}"
    show_file_list
    printf "\n%bTamaño total: %s%b\n" "${BOLD}${CYAN}" "$human_size" "${RESET}"
    show_footer 50

    # 4. Confirmación
    if ! confirm "¿Eliminar permanentemente?" "y"; then
        print_error "Operación cancelada"
        wait_enter 0
    fi

    # 5. Proceso
    local errors=0
    for file in "${VALID_FILES[@]}"; do
        if rm -rf -- "$file"; then
            print_success "Eliminado: $(basename "$file")"
        else
            print_error "Error al eliminar: $(basename "$file")"
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
