#!/usr/bin/env bash

# Script para compilar e instalar la barra personalizada de sway

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Instalación de sway-barra ===${NC}"

# Verificar dependencias
echo -e "${BLUE}Verificando dependencias...${NC}"

check_dep() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "${RED}Error: $1 no está instalado.${NC}"
        echo "Instala con: sudo apt install $1 (Debian/Ubuntu)"
        echo "O añade a configuration.nix en NixOS"
        return 1
    fi
    echo -e "  ✓ $1"
}

check_dep gcc || exit 1
check_dep pkg-config || exit 1
check_dep git || exit 1

# Verificar librerías de desarrollo
echo -e "${BLUE}Verificando librerías de desarrollo...${NC}"

check_lib() {
    if ! pkg-config --exists "$1"; then
        echo -e "${RED}Error: Librería $1 no encontrada.${NC}"
        echo "Instala:"
        echo "  Debian/Ubuntu: lib$1-dev"
        echo "  NixOS: $1 en buildInputs"
        return 1
    fi
    echo -e "  ✓ $1"
}

check_lib json-c || exit 1
check_lib libpulse || exit 1

# Directorios
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
BARRA_SRC_DIR="$DOTFILES_DIR/pkgs/sway-bar/src"
BARRA_BIN_DIR="$HOME/.local/bin"
SWAY_CONFIG_DIR="$HOME/.config/sway"

echo -e "${BLUE}Compilando barra...${NC}"

cd "$BARRA_SRC_DIR"

if [[ ! -f "barra.c" ]]; then
    echo -e "${RED}Error: No se encontró barra.c en $BARRA_SRC_DIR${NC}"
    exit 1
fi

# Compilar
echo -e "Compilando desde: $BARRA_SRC_DIR/barra.c"
gcc -Wall -O2 -o barra barra.c \
    $(pkg-config --cflags --libs json-c libpulse) \
    -lpulse-mainloop-glib -lpthread

if [[ $? -ne 0 ]]; then
    echo -e "${RED}Error en la compilación${NC}"
    exit 1
fi

# Instalar
echo -e "${BLUE}Instalando...${NC}"

mkdir -p "$BARRA_BIN_DIR"
cp barra "$BARRA_BIN_DIR/barra"
chmod +x "$BARRA_BIN_DIR/barra"

echo -e "${GREEN}✓ Barra compilada e instalada en: $BARRA_BIN_DIR/barra${NC}"

# Verificar configuración de sway
echo -e "${BLUE}Verificando configuración de sway...${NC}"

if [[ -f "$SWAY_CONFIG_DIR/config" ]]; then
    if grep -q "status_command ~/.config/sway/barra" "$SWAY_CONFIG_DIR/config"; then
        echo -e "${GREEN}✓ Configuración de sway ya apunta a ~/.config/sway/barra${NC}"
        echo -e "  Creando enlace simbólico..."
        mkdir -p "$SWAY_CONFIG_DIR"
        ln -sf "$BARRA_BIN_DIR/barra" "$SWAY_CONFIG_DIR/barra"
        echo -e "${GREEN}✓ Enlace creado: $SWAY_CONFIG_DIR/barra -> $BARRA_BIN_DIR/barra${NC}"
    else
        echo -e "${BLUE}Nota: La configuración de sway no usa ~/.config/sway/barra${NC}"
        echo -e "  Busca 'status_command' en $SWAY_CONFIG_DIR/config"
    fi
else
    echo -e "${BLUE}Nota: No se encontró configuración de sway en $SWAY_CONFIG_DIR/config${NC}"
fi

echo -e "${GREEN}=== Instalación completada ===${NC}"
echo ""
echo "Para usar la barra:"
echo "1. Recarga sway: Mod+Shift+c"
echo "2. O reinicia sway"
echo ""
echo "La barra muestra:"
echo "  • Workspaces"
echo "  • Ventana activa"
echo "  • Volumen"
echo "  • Fecha y hora"
echo ""
echo "Ubicaciones:"
echo "  • Binario: $BARRA_BIN_DIR/barra"
echo "  • Enlace: $SWAY_CONFIG_DIR/barra"
echo "  • Código fuente: $BARRA_SRC_DIR/barra.c"