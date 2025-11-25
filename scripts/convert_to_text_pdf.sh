#!/bin/bash

# Verificar si se han proporcionado los argumentos necesarios
if [ $# -ne 2 ]; then
  echo "Uso: $0 <input_pdf> <output_pdf>"
  exit 1
fi

# Asignar los argumentos a variables
input_pdf=$1
output_pdf=$2

# Verificar si el archivo de entrada existe
if [ ! -f "$input_pdf" ]; then
  echo "El archivo de entrada '$input_pdf' no existe."
  exit 1
fi

# Crear un directorio temporal para almacenar archivos intermedios
temp_dir=$(mktemp -d)

# Convertir PDF a imágenes usando pdftocairo
pdftocairo -png -r 300 "$input_pdf" "$temp_dir/page"

# Aplicar OCR a cada imagen
for img in "$temp_dir"/page-*.png; do
    tesseract "$img" "${img%.*}" pdf
done

# Combinar los PDFs en uno solo utilizando pdfunite de poppler
pdfunite "$temp_dir"/page-*.pdf "$output_pdf"

# Limpiar archivos temporales
rm -r "$temp_dir"

echo "Conversión completada. El archivo de salida es '$output_pdf'."
