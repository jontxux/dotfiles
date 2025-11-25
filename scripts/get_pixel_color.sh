#!/bin/sh

# 1. Calcula la geometría
GEOMETRY=$(slurp -p -b 00000000 -c 00000000 -w 2)
[ -n "$GEOMETRY" ] || { echo "No se seleccionó ninguna región."; exit 1; }

# 2. Detecta ImageMagick 6 vs 7
if command -v magick >/dev/null 2>&1; then
    IM_CMD="magick"
elif command -v convert >/dev/null 2>&1; then
    IM_CMD="convert"
else
    echo "Error: ni 'magick' ni 'convert' disponibles." >&2
    exit 1
fi

# 3. Extrae color usando la herramienta adecuada
COLOR_HEX=$(
    grim -g "$GEOMETRY" -t ppm - |
    "$IM_CMD" - -format "#%[hex:p{0,0}]" info:
)
COLOR_RGB=$(
    grim -g "$GEOMETRY" -t ppm - |
    "$IM_CMD" - -format "%[pixel:p{0,0}]" info:
)

# 4. Muestra el resultado
echo "Hexadecimal: $COLOR_HEX"
echo "RGB:         $COLOR_RGB"
