#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/liblf.sh"

main() {
    require_command "gpg"

    local lf_id="$1"
    local file="$2"

    if [ ! -f "$file" ]; then
        print_error "Archivo no válido"
        wait_enter 1
    fi

    show_header "FIRMAR ARCHIVO"
    printf "  %s\n" "$file"
    show_footer 50

    printf "%bClaves secretas disponibles:%b\n" "${BOLD}" "${RESET}"
    gpg --list-secret-keys --keyid-format LONG 2>/dev/null | awk '
        /^sec/ {
            if (key_id) printf "  %s - %s\n", key_id, uid
            key_id = $2; sub(/.*\//, "", key_id); uid = ""
        }
        /^uid/ {
            uid = substr($0, index($0, "]") + 2)
            if (uid == "") uid = substr($0, 5)
        }
        END { if (key_id) printf "  %s - %s\n", key_id, uid }
    '

    local key_id
    key_id=$(prompt_text "ID de clave (vacío = predeterminada)" "")

    if ! confirm "¿Firmar el archivo?"; then
        print_error "Operación cancelada"
        wait_enter
    fi

    local cmd output_file
    if [ -z "$key_id" ]; then
        cmd="gpg --detach-sign --armor \"$file\""
        output_file="$file.asc"
    else
        cmd="gpg --detach-sign --armor -u \"$key_id\" \"$file\""
        output_file="$file.$key_id.asc"
    fi

    if run_with_progress "Firmando" bash -c "$cmd"; then
        print_success "Firma creada: $output_file"
        [ -n "$lf_id" ] && lf -remote "send $lf_id load" 2>/dev/null
    fi

    wait_enter
}

main "$@"
