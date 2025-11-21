#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/liblf.sh"

main() {
    local lf_id="$1"

    show_header "NUEVO ARCHIVO"
    local nombre
    nombre=$(prompt_text "Nombre del archivo")
    show_footer 50

    if [ -z "$nombre" ]; then
        print_error "Nombre no válido"
        wait_enter 1
    fi

    if [ -e "$nombre" ]; then
        print_error "El archivo ya existe"
        wait_enter 1
    fi

    if touch "$nombre"; then
        print_success "Archivo creado: $nombre"
        [ -n "$lf_id" ] && lf -remote "send $lf_id select \"$nombre\""
        lf -remote "send load" 2>/dev/null
    else
        print_error "No se pudo crear el archivo"
        wait_enter 1
    fi

    wait_enter
}

main "$@"
