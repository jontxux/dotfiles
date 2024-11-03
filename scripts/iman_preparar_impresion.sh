#!/bin/sh

# Función para mostrar el uso del script
mostrar_uso() {
    echo "Uso: $0 [-o archivo_salida] imagen1 [imagen2 ... imagen6]"
    exit 1
}

# Nombre predeterminado del archivo de salida
ARCHIVO_SALIDA="salida_final_imanes.pdf"

# Procesar opciones
while [ "$1" != "" ]; do
    case $1 in
        -o )
            shift
            ARCHIVO_SALIDA=$1
            ;;
        -* )
            mostrar_uso
            ;;
        * )
            # Agregar archivo de imagen a la lista
            IMAGENES="$IMAGENES $1"
            ;;
    esac
    shift
done

# Comprueba si se han proporcionado suficientes argumentos
if [ "$IMAGENES" = "" ]; then
    mostrar_uso
fi

# Parámetros para las posiciones y espaciado
MARGEN_IZQUIERDO=315
MARGEN_SUPERIOR=379
ESPACIO_ENTRE_COLUMNAS=950
ESPACIO_ENTRE_FILAS=950
ANCHO_LIENZO=2480
ALTO_LIENZO=3508
ANCHO_IMAGEN=850
ALTO_IMAGEN=850

# Crear una lista de comandos composite
COMANDO_COMPOSITE="convert -size ${ANCHO_LIENZO}x${ALTO_LIENZO} xc:white -density 300 -units PixelsPerInch"

# Posiciones iniciales
X=$MARGEN_IZQUIERDO
Y=$MARGEN_SUPERIOR
COLUMNA=0
FILA=0

# Procesar cada archivo de imagen proporcionado
for ARCHIVO_IMAGEN in $IMAGENES; do
    COMANDO_COMPOSITE="$COMANDO_COMPOSITE \\( \"$ARCHIVO_IMAGEN\" -geometry +${X}+${Y} \\) -composite"

    # Mover a la siguiente columna o fila
    if [ $COLUMNA -eq 0 ]; then
        COLUMNA=1
        X=$(($MARGEN_IZQUIERDO + $ESPACIO_ENTRE_COLUMNAS))
    else
        COLUMNA=0
        X=$MARGEN_IZQUIERDO
        FILA=$(($FILA + 1))
        Y=$(($MARGEN_SUPERIOR + $FILA * $ESPACIO_ENTRE_FILAS))
    fi
done

# Añadir el nombre del archivo de salida
COMANDO_COMPOSITE="$COMANDO_COMPOSITE $ARCHIVO_SALIDA"

# Ejecutar el comando
eval $COMANDO_COMPOSITE

echo "PDF generado como $ARCHIVO_SALIDA"
