#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/liblf.sh"

main() {
    require_command "gpg"

    # 1. Cargar y validar archivos (Usa variables globales para seguridad)
    load_files "$@"
    filter_valid_files
    validate_not_empty

    # 2. UI
    show_header "FIRMAR ARCHIVO(S)" "${#VALID_FILES[@]}"
    show_file_list
    show_footer 50

    show_gpg_keys "secret"
    echo ""

    # 3. Solicitar clave
    local key_id
    key_id=$(prompt_text "ID de clave para firmar (Enter = Default)")

    # 4. Confirmación (Enter = SI)
    echo ""
    if ! confirm "¿Firmar archivos?" "y"; then
        print_error "Operación cancelada"
        wait_enter 0
    fi

    # 5. Procesar
    local cmd_base="gpg --detach-sign --armor"
    if [ -n "$key_id" ]; then
        cmd_base="$cmd_base -u \"$key_id\""
    fi

    local success_count=0
    for file in "${VALID_FILES[@]}"; do
        local output_file
        if [ -z "$key_id" ]; then
            output_file="$file.asc"
        else
            output_file="$file.$key_id.asc"
        fi

        if eval $cmd_base --output "\"$output_file\"" "\"$file\"" 2>/dev/null; then
            print_success "Firmado: $(basename "$output_file")"
            ((success_count++))
        else
            print_error "Fallo al firmar: $(basename "$file")"
        fi
    done

    if [ "$success_count" -gt 0 ]; then
        lf -remote "send load" 2>/dev/null
    fi

    wait_enter
}

main "$@"
