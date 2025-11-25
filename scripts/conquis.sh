#!/bin/sh

# URL de la página web
URL="https://www.eitb.eus/es/television/programas/el-conquistador/capitulos-completos/"

# Usar bemenu para seleccionar tipo de video
SELECTION=$(printf "episodio\ndebate\n" | bemenu -H '23' -i \
  --tb='#323232' --tf='#bbbbbb' \
  --fb='#323232' --ff='#bbbbbb' \
  --nb='#323232' --nf='#bbbbbb' \
  --hb='#005577' --hf='#eeeeee' \
  --sb='#323232' --sf='#bbbbbb' \
  --ab='#323232' --af='#bbbbbb' \
  --hp=10 \
  -p 'Selecciona tipo de video: ')

# Extraer los detalles del video
VIDEO_LINKS=$(curl -s "$URL" | grep -o '<a[^>]*>' | grep -i -- 'title="T21')

# Aplicar filtro basado en selección
if [ "$SELECTION" = "episodio" ]; then
  VIDEO_LINKS=$(echo "$VIDEO_LINKS" | grep -i -v -- 'debate')
elif [ "$SELECTION" = "debate" ]; then
  VIDEO_LINKS=$(echo "$VIDEO_LINKS" | grep -i -- 'debate')
else
  echo "Selección no válida"
  exit 1
fi

# Usar bemenu para seleccionar el video específico
VIDEO_TITLE=$(echo "$VIDEO_LINKS" | sed -n 's/.* data-titulovideo="\([^"]*\)".*/\1/p' | bemenu -i -l 20 -H '23' \
  --tb='#323232' --tf='#bbbbbb' \
  --fb='#323232' --nb='#323232' --nf='#bbbbbb' \
  --hb='#005577' --hf='#eeeeee' \
  --sb='#323232' --sf='#bbbbbb' \
  -p 'Selecciona el episodio: ')

if [ -z "$VIDEO_TITLE" ]; then
    echo "No se ha seleccionado ningun video"
    exit 1
fi

NOMBRE_ARCHIVO=$(echo "$VIDEO_TITLE" | tr ' ()' '___')
NOMBRE_ARCHIVO="${NOMBRE_ARCHIVO}.mp4"

# Mostrar el título del video seleccionado
echo "El título del video seleccionado es: $VIDEO_TITLE"

# Extraer el id del video seleccionado
VIDEO_ID=$(echo "$VIDEO_LINKS" | grep "data-titulovideo=\"$VIDEO_TITLE\"" | sed -n 's/.* id="\([0-9]\+\)".*/\1/p')

# Imprimir el id del video
echo "El ID del video seleccionado es: $VIDEO_ID"

# Obtener los detalles del video usando el ID
VIDEO_DETAILS=$(curl -s "https://mam.eitb.eus/mam/REST/ServiceMultiweb/Video4/MULTIWEBTV/$VIDEO_ID/")

# Extraer la URL del video MP4 con la resolución 1280x720 usando jq
VIDEO_URL=$(echo "$VIDEO_DETAILS" | jq -r '.web_media[0].RENDITIONS[] | select(.FRAME_WIDTH == "1280" and .FRAME_HEIGHT == "720") | .PMD_URL')

# Imprimir la URL del video
echo "La URL del video es: $VIDEO_URL"

RUTA_DESCARGA=$(printf "usb\ntmp\ndescargas\n" | bemenu -H '23' -i \
  --tb='#323232' --tf='#bbbbbb' \
  --fb='#323232' --ff='#bbbbbb' \
  --nb='#323232' --nf='#bbbbbb' \
  --hb='#005577' --hf='#eeeeee' \
  --sb='#323232' --sf='#bbbbbb' \
  --ab='#323232' --af='#bbbbbb' \
  --hp=10 \
  -p 'Introduce la ruta de descarga: ')

# Comprueba la selección y establece la ruta de descarga utilizando case
case "$RUTA_DESCARGA" in
    "usb")
        RUTA_DESCARGA="/media/usb"
        ;;
    "tmp")
        RUTA_DESCARGA="/tmp"
        ;;
    "descargas")
        RUTA_DESCARGA="/home/$USER/Descargas"
        ;;
    *)
        echo "No se ha seleccionado una opción válida."
        exit 1
        ;;
esac

# Comprueba si el archivo ya existe
if [ -f "$RUTA_DESCARGA/$NOMBRE_ARCHIVO" ]; then
    echo "El archivo '$RUTA_DESCARGA/$NOMBRE_ARCHIVO' ya existe. No se descargará de nuevo."
else
    # Descargar el video usando la URL obtenida
    curl -o "$RUTA_DESCARGA/$NOMBRE_ARCHIVO" "$VIDEO_URL"
    echo "Archivo descargado a '$RUTA_DESCARGA/$NOMBRE_ARCHIVO'."
fi
