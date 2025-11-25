#!/bin/bash

# Verificar que se haya proporcionado al menos un argumento
if [ -z "$1" ]; then
  echo "Uso: $0 '<descripción de la situación>' [opciones]"
  echo "Opciones:"
  echo "  -m, --model <modelo>               Especifica el modelo a utilizar (por defecto: llama3.1)"
  echo "  -t, --tone <tono>                  Especifica el tono para la respuesta (por defecto: cordial)"
  echo "  -n, --num-tokens <número>          Especifica el número máximo de tokens a predecir (por defecto: 150)"
  exit 1
fi

# Valores por defecto
MODEL="llama3.1"
TONE="cordial"
NUM_TOKENS=150

# Procesar los argumentos opcionales
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -m|--model) MODEL="$2"; shift ;;
    -t|--tone) TONE="$2"; shift ;;
    -n|--num-tokens) NUM_TOKENS="$2"; shift ;;
    *) SITUATION_DESCRIPTION="$1" ;;
  esac
  shift
done

# Definir el contexto del sistema para asegurar que la API se centre en respuestas a clientes de Airbnb
SYSTEM_MESSAGE="You are an assistant for Airbnb hosts. Your task is to generate polite, clear, and professionally structured responses to guests based on the user's input. The response should be appropriate for the situation described and reflect the specified tone."

# Construir el cuerpo de la solicitud
REQUEST_PAYLOAD=$(cat <<EOF
{
  "model": "$MODEL",
  "prompt": "Genera una respuesta estructurada y con un tono $TONE para la siguiente situación: $SITUATION_DESCRIPTION",
  "system": "$SYSTEM_MESSAGE",
  "stream": false,
  "options": {
    "num_predict": $NUM_TOKENS
  }
}
EOF
)

# Hacer la solicitud a la API con el texto proporcionado
response=$(curl -s http://localhost:11434/api/generate -d "$REQUEST_PAYLOAD" | jq -r '.response')

# Verificar si la respuesta está vacía o no es válida
if [ -z "$response" ] || [[ "$response" == "null" ]]; then
  echo "No se pudo generar una respuesta. Por favor verifica la solicitud o intenta nuevamente."
  exit 1
fi

# Mostrar la respuesta sugerida
echo "Respuesta sugerida:"
echo "$response"

