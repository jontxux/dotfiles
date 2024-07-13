#!/bin/sh

# Selecciona una región de la pantalla y guarda las coordenadas en GEOMETRY
GEOMETRY=$(slurp -p -b 00000000 -c 00000000 -w 2)
if [ -z "$GEOMETRY" ]; then
    echo "No se seleccionó ninguna región."
    exit 1
fi

# Toma una captura de pantalla de la región seleccionada y obtiene el color del píxel en la coordenada superior izquierda en varios formatos
COLOR_HEX=$(grim -g "$GEOMETRY" -t ppm - | convert - -format "#%[hex:p{0,0}]" info:)
COLOR_RGB=$(grim -g "$GEOMETRY" -t ppm - | convert - -format "%[pixel:p{0,0}]" info:)

# Imprime el color del píxel en diferentes formatos
echo "Hexadecimal: $COLOR_HEX"
echo "RGB: $COLOR_RGB"
