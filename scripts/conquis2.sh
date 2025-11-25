#!/bin/sh

# URL de la página web
URL="https://www.eitb.eus/es/television/programas/el-conquistador/capitulos-completos/"

# Usar bemenu para seleccionar tipo de video
PS3="Selecciona tipo de video: "
options=("episodio" "debate")

select opt in "${options[@]}"; do
  case $opt in
    "episodio"|"debate")
      SELECTION="$opt"
      break
      ;;
    *) 
      echo "Opción inválida"
      ;;
  esac
done

echo "Seleccionaste: $SELECTION"

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
VIDEO_TITLE=$(echo "$VIDEO_LINKS" | sed -n 's/.* data-titulovideo="\([^"]*\)".*/\1/p' | \
  fzf --height 23% --prompt 'Selecciona episodio: ' --border=rounded)

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
echo -n "Buscando la url del video directo en "
echo $VIDEO_DETAILS | jq

# Extraer la URL del video MP4 con la resolución 1280x720 usando jq
VIDEO_URL=$(echo "$VIDEO_DETAILS" | jq -r '.web_media[0].RENDITIONS[] | select(.FRAME_WIDTH == "1280" and .FRAME_HEIGHT == "720") | .PMD_URL')

# Imprimir la URL del video
echo "La URL del video es: $VIDEO_URL"

# Configurar el menú interactivo
PS3='Introduce la ruta de descarga: '
options=("usb" "tmp" "descargas")

select opt in "${options[@]}"; do
    case $opt in
        "usb")
            RUTA_DESCARGA="/media/usb"
            break
            ;;
        "tmp")
            RUTA_DESCARGA="/tmp"
            break
            ;;
        "descargas")
            RUTA_DESCARGA="$HOME/Descargas"
            break
            ;;
        *)
            echo "Error: Opción no válida"
            exit 1
            ;;
    esac
done

# Comprueba si el archivo ya existe
if [ -f "$RUTA_DESCARGA/$NOMBRE_ARCHIVO" ]; then
    echo "El archivo '$RUTA_DESCARGA/$NOMBRE_ARCHIVO' ya existe. No se descargará de nuevo."
else
    # Descargar el video usando la URL obtenida
    curl -o "$RUTA_DESCARGA/$NOMBRE_ARCHIVO" "$VIDEO_URL"
    echo "Archivo descargado a '$RUTA_DESCARGA/$NOMBRE_ARCHIVO'."
fi
