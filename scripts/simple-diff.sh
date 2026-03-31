#!/usr/bin/env bash

# --- CONFIGURACIÓN Y DEPENDENCIAS ---

# Colores
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Verificar dependencias críticas
if ! command -v diff-so-fancy &> /dev/null; then
    echo -e "${RED}Error: diff-so-fancy no está instalado.${NC}" >&2
    echo "Tip: Agrégalo a tu environment.systemPackages en NixOS."
    exit 1
fi

check_fzf() {
    if ! command -v fzf &> /dev/null; then
        echo -e "${RED}Error: fzf no está instalado.${NC}" >&2
        exit 1
    fi
}

# --- FUNCIONES ---

# Función para obtener el contenido (Archivo, Clipboard o String)
get_content() {
    local input="$1"

    # 1. Si es un archivo existente, mostrar contenido
    if [[ -f "$input" ]]; then
        cat "$input"
        return 0
    fi

    # 2. Si es "clip" o "clipboard", usar wl-copy o xclip
    if [[ "$input" == "clip" || "$input" == "clipboard" ]]; then
        if command -v wl-paste &> /dev/null; then
            wl-paste
        elif command -v xclip &> /dev/null; then
            xclip -selection clipboard -o
        else
            echo -e "${RED}Error: No se encontró wl-paste ni xclip.${NC}" >&2
            exit 1
        fi
        return 0
    fi

    # 3. Si no es ninguno de los anteriores, tratar como string literal
    echo "$input"
}

# Función para mostrar ayuda
show_help() {
    echo -e "${BLUE}Uso: dff [OPCIONES] <archivo1/clip/string> <archivo2/clip/string>${NC}"
    echo ""
    echo "Compara dos fuentes de texto de forma interactiva."
    echo ""
    echo "Fuentes disponibles:"
    echo "  <archivo>    - Ruta a un archivo"
    echo "  clip         - Contenido del portapapeles (Wayland: wl-paste, X11: xclip)"
    echo "  <string>     - Texto literal (entre comillas si contiene espacios)"
    echo ""
    echo "Ejemplos:"
    echo "  dff archivo1.txt archivo2.txt"
    echo "  dff clip archivo.txt"
    echo "  dff archivo.txt clip"
    echo "  dff \"texto literal\" archivo.txt"
    echo "  dff clip \"texto para comparar\""
    echo ""
    echo "Opciones:"
    echo "  -h, --help   - Muestra esta ayuda"
    echo "  -f, --fzf    - Usar fzf para seleccionar archivos"
    echo ""
    echo "Notas:"
    echo "  - Requiere diff-so-fancy para el formateo"
    echo "  - Para Wayland: wl-paste/wl-copy"
    echo "  - Para X11: xclip"
}

# --- MODO FZF (Selección interactiva de archivos) ---

fzf_mode() {
    check_fzf

    echo -e "${BLUE}Selecciona el primer archivo:${NC}"
    local file1=$(find . -type f 2>/dev/null | fzf --height 40% --layout=reverse --border)
    if [[ -z "$file1" ]]; then
        echo "Operación cancelada."
        exit 0
    fi

    echo -e "${BLUE}Selecciona el segundo archivo:${NC}"
    local file2=$(find . -type f 2>/dev/null | fzf --height 40% --layout=reverse --border)
    if [[ -z "$file2" ]]; then
        echo "Operación cancelada."
        exit 0
    fi

    echo -e "${BLUE}Comparando:${NC}"
    echo "  • $file1"
    echo "  • $file2"
    echo ""

    # Realizar la comparación
    diff -u <(get_content "$file1") <(get_content "$file2") | diff-so-fancy
}

# --- PROCESAMIENTO DE ARGUMENTOS ---

# Manejo de opciones
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -f|--fzf)
            fzf_mode
            exit 0
            ;;
        -*)
            echo -e "${RED}Error: Opción desconocida '$1'${NC}" >&2
            show_help
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

# Verificar número de argumentos
if [[ $# -ne 2 ]]; then
    echo -e "${RED}Error: Se requieren exactamente 2 argumentos.${NC}" >&2
    show_help
    exit 1
fi

# --- EJECUCIÓN PRINCIPAL ---

# Obtener contenidos
content1=$(get_content "$1")
content2=$(get_content "$2")

# Mostrar información de lo que se está comparando
echo -e "${BLUE}Comparando:${NC}"
echo "  • $1"
echo "  • $2"
echo ""

# Realizar la comparación
diff -u <(echo "$content1") <(echo "$content2") | diff-so-fancy