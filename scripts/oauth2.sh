#!/usr/bin/env bash

set -e

# Configuración de pass
PASS_CLIENT_ID="google-oauth/client_id"
PASS_CLIENT_SECRET="google-oauth/client_secret"
PASS_TOKENS="google-oauth/tokens"

redirect_uri="urn:ietf:wg:oauth:2.0:oob"
scope="https://mail.google.com/"
MARGIN=60  # Margen de seguridad en segundos (1 minuto)

get_client_id() {
    pass show "$PASS_CLIENT_ID"
}

get_client_secret() {
    pass show "$PASS_CLIENT_SECRET"
}

# Almacena tokens con timestamp
save_tokens() {
    tokens_json="$1"
    # Agregar timestamp de obtención (epoch)
    tokens_json=$(echo "$tokens_json" | jq --arg issued_at "$(date +%s)" '. + {issued_at: ($issued_at | tonumber)}')
    echo "$tokens_json" | pass insert -m "$PASS_TOKENS" -f >/dev/null
    echo "$tokens_json"
}

authorize() {
    id=$(get_client_id)
    secret=$(get_client_secret)

    auth_uri="https://accounts.google.com/o/oauth2/auth?client_id=$id&redirect_uri=$redirect_uri&scope=$scope&response_type=code"
    tkn_uri="https://accounts.google.com/o/oauth2/token"

    echo "Abre esta URL en tu navegador:"
    echo "$auth_uri"
    echo ""
    read -r -p "Código de autorización: " code

    data="code=$code&client_id=$id&client_secret=$secret&redirect_uri=$redirect_uri&grant_type=authorization_code"
    response=$(curl -s -X POST -d "$data" "$tkn_uri")

    # Guardar con timestamp
    tokens_json=$(save_tokens "$response")
    echo "✓ Tokens guardados en pass: $PASS_TOKENS"
}

# Verifica si el token ha expirado
is_token_expired() {
    tokens_json="$1"
    issued_at=$(echo "$tokens_json" | jq -r '.issued_at')
    expires_in=$(echo "$tokens_json" | jq -r '.expires_in')

    if [[ "$issued_at" == "null" || -z "$issued_at" ]]; then
        echo "true"
        return
    fi

    current_time=$(date +%s)
    expiration_time=$((issued_at + expires_in))

    if (( current_time > (expiration_time - MARGIN) )); then
        echo "true"
    else
        echo "false"
    fi
}

refresh() {
    id=$(get_client_id)
    secret=$(get_client_secret)

    # Obtener tokens existentes
    tokens_json=$(pass show "$PASS_TOKENS")

    # Verificar expiración
    if [[ $(is_token_expired "$tokens_json") == "false" ]]; then
        echo "$tokens_json" | jq -r '.access_token'
        return
    fi

    refresh_token=$(echo "$tokens_json" | jq -r '.refresh_token')
    tkn_uri="https://accounts.google.com/o/oauth2/token"

    response=$(curl -s -X POST -d \
        "client_id=$id&client_secret=$secret&refresh_token=$refresh_token&grant_type=refresh_token" \
        "$tkn_uri")

    # Combinar tokens (manteniendo refresh_token original)
    new_tokens=$(echo "$tokens_json" | jq --argjson new "$response" '. * $new')

    # Actualizar con nuevo timestamp
    updated_tokens=$(save_tokens "$new_tokens")

    echo "$updated_tokens" | jq -r '.access_token'
}

case "$1" in
    -a) authorize ;;
    -r) refresh ;;
    *)
        echo "Uso: ${0##*/} [-a|-r]"
        echo "  -a  Autorización inicial (obtener tokens)"
        echo "  -r  Refrescar access token"
        exit 1
        ;;
esac
