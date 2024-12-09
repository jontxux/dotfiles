#!/bin/bash

# Archivo de configuración
CONFIG_FILE="$HOME/.telegram_config"

# Comprobar si el archivo de configuración existe
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: No se encontró el archivo de configuración en $CONFIG_FILE"
    echo "Crea un archivo .telegram_config en tu directorio HOME con el siguiente formato:"
    echo "TELEGRAM_BOT_TOKEN=tu_bot_token"
    echo "TELEGRAM_CHAT_ID=tu_chat_id"
    exit 1
fi

# Cargar configuración
source "$CONFIG_FILE"

# Validar que TELEGRAM_BOT_TOKEN y TELEGRAM_CHAT_ID estén configurados
if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
    echo "Error: TELEGRAM_BOT_TOKEN o TELEGRAM_CHAT_ID no están configurados en $CONFIG_FILE"
    exit 1
fi

# URL base de la API de Telegram
URL="https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage"

# Leer mensaje desde parámetros o pipe
if [ -n "$1" ]; then
    # Si se pasa un parámetro, usarlo como mensaje
    MENSAJE="$1"
elif [ -p /dev/stdin ]; then
    # Si no hay parámetro pero hay datos en el pipe, leerlos
    MENSAJE=$(cat -)
else
    # Si no se proporciona mensaje, mostrar error
    echo "Error: Debes proporcionar un mensaje."
    echo "Uso: $0 'mensaje' o echo 'mensaje' | $0"
    exit 1
fi

# Validar si el mensaje está vacío
if [ -z "$MENSAJE" ]; then
    echo "Error: No se puede enviar un mensaje vacío."
    exit 1
fi

# Enviar mensaje
curl -s -X POST "$URL" -d chat_id="$TELEGRAM_CHAT_ID" -d text="$MENSAJE" > /dev/null

# Comprobar el resultado
if [ $? -eq 0 ]; then
    echo "Mensaje enviado correctamente."
else
    echo "Error al enviar el mensaje."
fi
