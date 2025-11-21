#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/liblf.sh"

list_gpg_keys() {
    local key_type="$1"  # "public" o "secret"

    gpg --list-"${key_type}"-keys --keyid-format LONG 2>/dev/null | awk '
        /^(pub|sec)/ {
            if (key_id) printf "  %s - %s\n", key_id, uid
            key_id = $2
            sub(/.*\//, "", key_id)
            uid = ""
        }
        /^uid/ {
            uid = substr($0, index($0, "]") + 2)
            if (uid == "") uid = substr($0, 5)
        }
        END {
            if (key_id) printf "  %s - %s\n", key_id, uid
        }
    '
}

main() {
    require_command "gpg"

    local file="$1"
    if [ ! -f "$file" ]; then
        print_error "Archivo no válido"
        wait_enter 1
    fi

    show_header "ENCRIPTAR ARCHIVO"
    printf "  %s\n" "$file"
    show_footer 50

    printf "%bClaves públicas disponibles:%b\n" "${BOLD}" "${RESET}"
    list_gpg_keys "public"

    local key_id
    key_id=$(prompt_text "ID de clave (corto) o correo")

    if [ -z "$key_id" ]; then
        print_error "Debe especificar un destinatario"
        wait_enter 1
    fi

    if ! confirm "¿Encriptar el archivo?"; then
        print_error "Operación cancelada"
        wait_enter
    fi

    local output_file="$file.gpg"
    if run_with_progress "Encriptando" \
        gpg --encrypt --armor -r "$key_id" -o "$output_file" "$file"; then
        print_success "Archivo encriptado: $output_file"
        lf -remote "send load" 2>/dev/null
    fi

    wait_enter
}

main "$@"
