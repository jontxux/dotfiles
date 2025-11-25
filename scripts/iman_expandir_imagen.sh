#!/bin/bash

# Verificar si se ha proporcionado un archivo de imagen como argumento
if [ -z "$1" ]; then
  echo "Uso: $0 <imagen>"
  exit 1
fi

# Nombre del archivo de entrada
input_image="$1"

# Verificar si el archivo de entrada existe
if [ ! -f "$input_image" ]; then
  echo "El archivo $input_image no existe."
  exit 1
fi

# Obtener las dimensiones de la imagen usando identify
dimensions=$(identify -format "%wx%h" "$input_image")
original_width=$(echo $dimensions | cut -d'x' -f1)
original_height=$(echo $dimensions | cut -d'x' -f2)

# Ancho adicional a cada lado
extra_width=500

# Recortar y expandir el borde izquierdo
convert "$input_image" -crop 5x${original_height}+0+0 -scale ${extra_width}x${original_height}! left_border.png

# Recortar y expandir el borde derecho
convert "$input_image" -crop 5x${original_height}+$(($original_width - 5))+0 -scale ${extra_width}x${original_height}! right_border.png

# Combinar las imágenes
convert left_border.png "$input_image" right_border.png +append expanded_"$input_image"

# Limpiar archivos temporales
rm left_border.png right_border.png

echo "Imagen expandida guardada como expanded_$input_image"

