#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/liblf.sh"

main() {
    require_command "gpg"

    # 1. Cargar y validar (Usa globales de liblf para evitar errores)
    load_files "$@"
    filter_valid_files
    validate_not_empty

    # 2. UI Header
    show_header "ENCRIPTAR ARCHIVO(S)" "${#VALID_FILES[@]}"
    show_file_list
    show_footer 50

    # 3. Mostrar claves (Igual que en sign.sh pero públicas)
    show_gpg_keys "public"
    echo ""

    # Calculamos una clave por defecto (la primera de la lista) para facilitar el Enter
    local default_key
    default_key=$(gpg --list-public-keys --keyid-format LONG 2>/dev/null | awk '/^pub/ { sub(/.*\//, "", $2); print $2; exit }')

    # 4. Solicitar destinatario
    local key_id
    local prompt_msg="ID destinatario"

    if [ -n "$default_key" ]; then
        key_id=$(prompt_text "$prompt_msg (Enter = $default_key)" "$default_key")
    else
        key_id=$(prompt_text "$prompt_msg")
    fi

    if [ -z "$key_id" ]; then
        print_error "Debe especificar un destinatario"
        wait_enter 1
    fi

    # 5. Confirmación (Enter = SI, igual que sign.sh)
    echo ""
    if ! confirm "¿Encriptar para '$key_id'?" "y"; then
        print_error "Operación cancelada"
        wait_enter 0
    fi

    # 6. Procesar
    local success_count=0
    for file in "${VALID_FILES[@]}"; do
        local output_file="$file.gpg"

        if gpg --encrypt --armor -r "$key_id" -o "$output_file" "$file" 2>/dev/null; then
            print_success "Encriptado: $(basename "$output_file")"
            ((success_count++))
        else
            print_error "Fallo al encriptar: $(basename "$file")"
        fi
    done

    if [ "$success_count" -gt 0 ]; then
        lf -remote "send load" 2>/dev/null
    fi

    wait_enter
}

main "$@"
