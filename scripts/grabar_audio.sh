#!/bin/bash

# Definir la ubicación temporal en /dev/shm para almacenar el archivo de audio
TEMP_AUDIO="/dev/shm/temp_audio.wav"

# Función para manejar la interrupción (Ctrl+C)
cleanup() {
    echo "Interrumpido, enviando el archivo para transcripción..."
    curl -s -X POST -F "audio=@${TEMP_AUDIO}" http://localhost:5000/transcribir | jq -r .texto
    # curl -s 127.0.0.1:8080/inference -H "Content-Type: multipart/form-data" -F "file=@${TEMP_AUDIO}" | jq -r .text
    # whisper.cpp -m ~/.local/share/models/ggml-large-v3-turbo-q8_0.bin -f $TEMP_AUDIO -nt --print-progress false --print-special false -l es 2>/dev/null

    rm -f "${TEMP_AUDIO}"  # Limpiar el archivo temporal
    exit 0
}

# Configurar la trampa para limpiar cuando se presione Ctrl+C
trap cleanup INT

# Comenzar a grabar audio
echo "Grabando... presiona Ctrl+C para detener y enviar para transcripción."
ffmpeg -loglevel quiet -f alsa -i default -ac 1 -ar 16000 -f wav "${TEMP_AUDIO}"

# Esta parte solo se ejecutará si el usuario interrumpe el proceso
cleanup

