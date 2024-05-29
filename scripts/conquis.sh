#!/bin/sh

# URL de la página web
URL="https://www.eitb.eus/es/television/programas/el-conquistador/capitulos-completos/"

# Extraer el id del video que quieres descargar (el episodio más reciente)
VIDEO_ID=$(curl -s "$URL" | grep -o '<a[^>]*>' | grep -i -- 'title="T20' | grep -i -v -- debate | sed -n 's/.* id="\([0-9]\+\)".*/\1/p' | sort -nr | head -1)

# Imprimir el id del video
echo "El ID del video más reciente es: $VIDEO_ID"

# Obtener los detalles del video usando el ID
VIDEO_DETAILS=$(curl -s "https://mam.eitb.eus/mam/REST/ServiceMultiweb/Video4/MULTIWEBTV/$VIDEO_ID/")

# Extraer la URL del video MP4 con la resolución 1280x720 usando jq
VIDEO_URL=$(echo "$VIDEO_DETAILS" | jq -r '.web_media[0].RENDITIONS[] | select(.FRAME_WIDTH == "1280" and .FRAME_HEIGHT == "720") | .PMD_URL')

# Imprimir la URL del video
echo "La URL del video es: $VIDEO_URL"

# Descargar el video usando la URL obtenida
curl -o /tmp/conquis.mp4 "$VIDEO_URL"
