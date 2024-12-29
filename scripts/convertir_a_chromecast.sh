#!/bin/bash

# Verificar si FFmpeg está instalado
if ! command -v ffmpeg &> /dev/null
then
    echo "FFmpeg no está instalado. Por favor, instálalo para usar este script."
    exit
fi

# Verificar si se proporcionó un archivo de entrada
if [ $# -eq 0 ]; then
    echo "Uso: $0 <archivo_de_entrada>"
    exit 1
fi

# Archivo de entrada
input_file="$1"

# Archivo de salida (agrega el sufijo _chromecast_vaapi.mp4)
output_file="${input_file%.*}_chromecast_vaapi.mp4"

# Conversión a formato compatible con Chromecast usando VAAPI
echo "Convirtiendo $input_file a formato Chromecast con VAAPI..."
ffmpeg -hwaccel vaapi -vaapi_device /dev/dri/renderD128 \
    -i "$input_file" \
    -vf 'format=nv12,hwupload' \
    -c:v h264_vaapi -profile:v constrained_baseline -level 4.0 -b:v 5M \
    -c:a aac -b:a 192k \
    -movflags +faststart \
    "$output_file"

# Verificar si la conversión fue exitosa
if [ $? -eq 0 ]; then
    echo "Conversión completada: $output_file"
else
    echo "Hubo un error durante la conversión."
fi
