#!/bin/bash

file1="$1"
file2="$2"

# Validar que se proporcionaron ambos argumentos
if [ $# -ne 2 ]; then
    echo "Uso: $0 <archivo1> <archivo2>" >&2
    exit 1
fi

# Verificar que diff-so-fancy está disponible
if ! command -v diff-so-fancy &> /dev/null; then
    echo "Error: diff-so-fancy no está instalado" >&2
    exit 1
fi

# Ejecutar diff sin eval
if [ -f "$file1" ] && [ -f "$file2" ]; then
    diff -u "$file1" "$file2" | diff-so-fancy
elif [ -f "$file1" ]; then
    diff -u "$file1" <(echo "$file2") | diff-so-fancy
elif [ -f "$file2" ]; then
    diff -u <(echo "$file1") "$file2" | diff-so-fancy
else
    diff -u <(echo "$file1") <(echo "$file2") | diff-so-fancy
fi
