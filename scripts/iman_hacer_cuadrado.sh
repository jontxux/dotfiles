#!/bin/bash

# Verificar que se proporcionaron los argumentos necesarios
if [ "$#" -ne 2 ]; then
  echo "Uso: $0 ruta/a/tu/imagen.jpg salida/cuadrado_guardado.jpg"
  exit 1
fi

# Rutas de los archivos
image_path="$1"
output_image="$2"

# Configuración inicial
square_size=850
x=0
y=0
display_image="temp_image.jpg"

# Mensaje de instrucciones
instructions="Instrucciones: [w] Arriba, [s] Abajo, [a] Izquierda, [d] Derecha, [i] Aumentar tamaño, [o] Disminuir tamaño, [g] Guardar, [q] Salir"
echo "$instructions"

# Función para dibujar el cuadrado en la imagen
draw_square() {
  convert "$image_path" -stroke blue -strokewidth 5 -fill none -draw "rectangle $x,$y $((x + square_size)),$((y + square_size))" "$display_image"
}

# Inicializar con la imagen original
cp "$image_path" "$display_image"
draw_square
imv-wayland "$display_image" &
imv_pid=$!

# Mover el cuadrado con las teclas
while true; do
  read -n 1 -s key
  case "$key" in
    w) y=$((y - 10));;
    s) y=$((y + 10));;
    a) x=$((x - 10));;
    d) x=$((x + 10));;
    i) square_size=$((square_size + 10));;
    o) square_size=$((square_size - 10));;
    q) break;;
    g)
      convert "$image_path" -crop "${square_size}x${square_size}+$x+$y" "$output_image"
      echo -ne "\rRegión guardada como '$output_image'                           "
      break
      ;;
  esac
  draw_square
  echo -ne "\rPosición: ($x, $y) | Tamaño: $square_size                      "
done

kill $imv_pid

# Limpiar archivos temporales
rm "$display_image"
