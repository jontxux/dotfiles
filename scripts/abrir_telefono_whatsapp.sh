#!/bin/sh

# Comprobar si se pasó un argumento
if [ -z "$1" ]; then
    echo "Uso: $0 <número_de_teléfono>"
    exit 1
fi

# Número de teléfono pasado como argumento
telefono="$1"

# Validar el número de teléfono y añadir prefijo si es necesario
if echo "$telefono" | grep -qE '^[0-9]{9}$'; then
    # Si el número tiene exactamente 9 dígitos, añadir el prefijo de España
    telefono="34$telefono"
    echo "Se ha añadido el prefijo de España. Número completo: $telefono"
elif ! echo "$telefono" | grep -qE '^[0-9]{10,15}$'; then
    # Validar que el número tenga entre 10 y 15 dígitos si ya incluye un prefijo
    echo "Error: El número de teléfono debe contener solo dígitos y tener entre 10 y 15 caracteres."
    exit 1
fi

# URL de WhatsApp Web con el nuevo formato
url="https://web.whatsapp.com/send/?phone=$telefono"

# Abrir la URL en el navegador predeterminado
xdg-open "$url" 2>/dev/null || echo "No se pudo abrir la URL en el navegador."

echo "WhatsApp Web abierto para el número: $telefono"
