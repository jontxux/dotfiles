#!/bin/sh

# Función de ayuda
mostrar_ayuda() {
    echo "Uso: $0 [opciones] <imagen_original> <imagen_salida>"
    echo ""
    echo "Opciones:"
    echo "  -c, --color     Color del borde del círculo (por defecto: black)"
    echo "  -d, --diametro  Diámetro del círculo en mm (por defecto: 68)"
    echo "  -h, --help      Muestra esta ayuda y sale"
    exit 0
}

# Valores por defecto
COLOR="black"
DIAMETRO_MM=68

# Procesar las opciones
while [ $# -gt 0 ]; do
    case "$1" in
        -c|--color)
            shift
            COLOR=$1
            ;;
        -d|--diametro)
            shift
            DIAMETRO_MM=$1
            ;;
        -h|--help)
            mostrar_ayuda
            ;;
        --)
            shift
            break
            ;;
        -*)
            echo "Opción desconocida: $1"
            mostrar_ayuda
            ;;
        *)
            break
            ;;
    esac
    shift
done

# Verifica si se proporcionaron los argumentos correctos
if [ "$#" -ne 2 ]; then
    echo "Uso: $0 [opciones] <imagen_original> <imagen_salida>"
    exit 1
fi

# Argumentos
IMAGEN_ORIGINAL=$1
IMAGEN_SALIDA=$2

# Convertir mm a píxeles (300 dpi)
DIAMETRO_PX=$(echo "scale=2; $DIAMETRO_MM * 300 / 25.4" | bc)
RADIO_PX=$(echo "scale=2; $DIAMETRO_PX / 2" | bc)

# Dimensiones de la imagen original (850x850)
DIMENSION=850
CENTRO=$(echo "scale=2; $DIMENSION / 2" | bc)

# Crear y superponer el círculo
convert $IMAGEN_ORIGINAL -gravity center -stroke $COLOR -strokewidth 5 -fill none -draw "ellipse $CENTRO,$CENTRO $RADIO_PX,$RADIO_PX 0,360" $IMAGEN_SALIDA

echo "Imagen con círculo de $DIAMETRO_MM mm y color $COLOR creada: $IMAGEN_SALIDA"
