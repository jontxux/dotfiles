#!/bin/bash

# Definir variables
REPO_URL="https://codeberg.org/dnkl/yambar"
BUILD_DIR="bld/release"
INSTALL_DIR="$HOME/.local/bin"
EXECUTABLE="yambar"

# Clonar el repositorio
echo "Clonando el repositorio desde $REPO_URL..."
git clone "$REPO_URL" || { echo "Error al clonar el repositorio"; exit 1; }

# Crear el directorio de construcción y navegar a él
echo "Creando el directorio de construcción: $BUILD_DIR"
mkdir -p "$BUILD_DIR" && cd "$BUILD_DIR" || { echo "Error al crear/navegar al directorio de construcción"; exit 1; }

# Configurar la compilación con Meson
echo "Configurando la compilación con Meson..."
meson setup --buildtype=release \
    -Dplugin-i3=enabled \
    -Dplugin-foreign-toplevel=enabled \
    -Dplugin-alsa=enabled \
    -Dplugin-clock=enabled \
    -Dbackend-wayland=enabled \
    -Dbackend-x11=disabled \
    -Dplugin-backlight=disabled \
    -Dplugin-battery=disabled \
    -Dplugin-cpu=disabled \
    -Dplugin-disk-io=disabled \
    -Dplugin-dwl=disabled \
    -Dplugin-mem=disabled \
    -Dplugin-mpd=disabled \
    -Dplugin-network=disabled \
    -Dplugin-pipewire=disabled \
    -Dplugin-pulse=disabled \
    -Dplugin-removables=disabled \
    -Dplugin-river=disabled \
    -Dplugin-script=disabled \
    -Dplugin-sway-xkb=disabled \
    -Dplugin-xkb=disabled \
    -Dplugin-xwindow=disabled \
    ../.. || { echo "Error en la configuración de Meson"; exit 1; }

# Compilar con Ninja
echo "Compilando con Ninja..."
ninja || { echo "Error durante la compilación"; exit 1; }

# Copiar el binario al directorio de instalación
echo "Instalando el ejecutable en $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"
cp "$EXECUTABLE" "$INSTALL_DIR" || { echo "Error al copiar el ejecutable"; exit 1; }

echo "Instalación completada. Puedes ejecutar $EXECUTABLE desde $INSTALL_DIR."

