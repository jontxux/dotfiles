#!/bin/bash

# Definir la ubicación temporal en /dev/shm para almacenar el archivo de audio y texto
TEMP_AUDIO="/dev/shm/temp_audio.wav"
TEMP_TEXT="/dev/shm/temp_text.txt"

# Definir un mensaje del sistema en español
SYSTEM_MESSAGE="Actúa como un asistente de texto avanzado. Tu tarea es tomar el texto proporcionado, que ha sido generado mediante una transcripción automática (posiblemente con errores), y corregirlo. Además de corregir errores gramaticales, ortográficos y de puntuación, también debes contextualizar y mejorar la claridad del mensaje. Asegúrate de que el texto final sea coherente, fácil de entender y adecuado para la situación o propósito previsto. Si el contexto no está claro, realiza las mejores suposiciones posibles para que el mensaje tenga sentido y mantenga un tono apropiado."

# Función para manejar la interrupción (Ctrl+C)
cleanup() {
    echo "Interrumpido, enviando el archivo para transcripción..."
    transcribed_text=$(/opt/whisper.cpp/main -m /opt/whisper.cpp/models/ggml-base.bin -f $TEMP_AUDIO -nt --print-progress false --print-special false -l es 2>/dev/null)
    
    # Verificar si se obtuvo texto transcrito
    if [ -z "$transcribed_text" ]; then
        echo "No se recibió texto transcrito. Verifica que el servicio de transcripción está funcionando correctamente."
        rm -f "${TEMP_AUDIO}"
        exit 1
    else
        echo "Texto transcrito recibido: $transcribed_text"
    fi
    
    # Guardar el texto transcrito en un archivo temporal
    echo "$transcribed_text" > "$TEMP_TEXT"
    
    echo "Enviando el texto para formateo con Ollama..."
    
    # Crear el payload de la petición a Ollama
    REQUEST_PAYLOAD=$(jq -n \
        --arg system "$SYSTEM_MESSAGE" \
        --arg prompt "Formatea y mejora el siguiente texto en español: $(<${TEMP_TEXT})" \
        '{model: "llama3.1", system: $system, prompt: $prompt, stream: false}')
    
    echo $REQUEST_PAYLOAD
    # Realizar la petición y capturar la respuesta
    formatted_text=$(curl -s http://localhost:11434/api/generate -d "$REQUEST_PAYLOAD" | jq -r '.response')
    
    echo "Texto formateado:"
    echo "$formatted_text"
    
    # rm -f "${TEMP_AUDIO}" "${TEMP_TEXT}"  # Limpiar los archivos temporales
    rm -f "${TEMP_AUDIO}"
    exit 0
}

# Configurar la trampa para limpiar cuando se presione Ctrl+C
trap cleanup INT

# Comenzar a grabar audio
echo "Grabando... presiona Ctrl+C para detener y enviar para transcripción."
ffmpeg -loglevel quiet -f alsa -i default -ac 1 -ar 16000 -f wav "${TEMP_AUDIO}"

# Esta parte solo se ejecutará si el usuario interrumpe el proceso
cleanup
