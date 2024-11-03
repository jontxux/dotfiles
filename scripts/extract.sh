#!/bin/sh

# Función para mostrar el uso del script
usage() {
    echo "Usage: $0 <archivo_comprimido> [directorio_destino]"
    exit 1
}

# Verificar que se haya pasado al menos un argumento
if [ $# -lt 1 ]; then
    usage
fi

# Archivo comprimido a extraer
ARCHIVO="$1"

# Directorio de destino (por defecto es el directorio actual)
DIRECTORIO="${2:-.}"

# Verificar si el archivo existe
if [ ! -f "$ARCHIVO" ];then
    echo "Error: Archivo '$ARCHIVO' no encontrado."
    exit 1
fi

# Verificar si el directorio de destino existe
if [ ! -d "$DIRECTORIO" ]; then
    echo "Error: Directorio destino '$DIRECTORIO' no encontrado."
    exit 1
fi

# Extraer el archivo basado en su extensión
case "$ARCHIVO" in
    *.tar)
        bsdtar -xf "$ARCHIVO" -C "$DIRECTORIO"
        ;;
    *.tar.gz | *.tgz)
        bsdtar -xzf "$ARCHIVO" -C "$DIRECTORIO"
        ;;
    *.tar.bz2 | *.tbz2)
        bsdtar -xjf "$ARCHIVO" -C "$DIRECTORIO"
        ;;
    *.tar.xz | *.txz)
        bsdtar -xJf "$ARCHIVO" -C "$DIRECTORIO"
        ;;
    *.zip)
        bsdtar -xf "$ARCHIVO" -C "$DIRECTORIO"
        ;;
    *.7z)
        bsdtar -xf "$ARCHIVO" -C "$DIRECTORIO"
        ;;
    *.deb)
        bsdtar -xf "$ARCHIVO" -C "$DIRECTORIO"
        ;;
    *.rar)
        if command -v unrar >/dev/null 2>&1; then
            unrar x -o+ "$ARCHIVO" "$DIRECTORIO"
        else
            echo "Error: 'unrar' no está instalado. Por favor, instálalo e intenta de nuevo."
            exit 1
        fi
        ;;
    *)
        echo "Error: Tipo de archivo no soportado."
        exit 1
        ;;
esac

echo "Archivo extraído exitosamente en '$DIRECTORIO'."
