#!/bin/bash

# Verificar que se haya proporcionado al menos un argumento
if [ -z "$1" ]; then
  echo "Uso: $0 '<descripción de la tarea>' [opciones]"
  echo "Opciones:"
  echo "  -m, --model <modelo>               Especifica el modelo a utilizar (por defecto: llama3.1)"
  echo "  -t, --temperature <temperatura>    Especifica la temperatura para la generación (por defecto: 0.7)"
  echo "  -n, --num-tokens <número>          Especifica el número máximo de tokens a predecir (por defecto: 50)"
  echo "  -k, --top-k <valor>                Especifica el valor para top-k sampling (por defecto: 40)"
  echo "  -p, --top-p <valor>                Especifica el valor para top-p sampling (por defecto: 0.9)"
  echo "  -r, --repeat-penalty <valor>       Especifica el valor para la penalización por repetición (por defecto: 1.1)"
  exit 1
fi

# Valores por defecto
MODEL="llama3.1"
TEMPERATURE=0.7
NUM_TOKENS=50
TOP_K=40
TOP_P=0.9
REPEAT_PENALTY=1.1

# Procesar los argumentos opcionales
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -m|--model) MODEL="$2"; shift ;;
    -t|--temperature) TEMPERATURE="$2"; shift ;;
    -n|--num-tokens) NUM_TOKENS="$2"; shift ;;
    -k|--top-k) TOP_K="$2"; shift ;;
    -p|--top-p) TOP_P="$2"; shift ;;
    -r|--repeat-penalty) REPEAT_PENALTY="$2"; shift ;;
    *) TASK_DESCRIPTION="$1" ;;
  esac
  shift
done

# Definir el contexto del sistema para asegurar que la API se centre en comandos de terminal
SYSTEM_MESSAGE="You are a Linux terminal assistant. Your task is to provide a complete and executable shell command based on the user's request. The command should be directly executable in a Debian Linux environment without any additional explanation or text."

# Construir el cuerpo de la solicitud
REQUEST_PAYLOAD=$(cat <<EOF
{
  "model": "$MODEL",
  "prompt": "Genera un comando de terminal Debian completo y sin explicaciones para: $TASK_DESCRIPTION",
  "system": "$SYSTEM_MESSAGE",
  "stream": false,
  "options": {
    "temperature": $TEMPERATURE,
    "num_predict": $NUM_TOKENS,
    "top_k": $TOP_K,
    "top_p": $TOP_P,
    "repeat_penalty": $REPEAT_PENALTY
  }
}
EOF
)

# Hacer la solicitud a la API con el texto proporcionado
response=$(curl -s http://localhost:11434/api/generate -d "$REQUEST_PAYLOAD" | jq -r '.response')

# Verificar si la respuesta está vacía o no es válida
if [ -z "$response" ] || [[ "$response" == "null" ]]; then
  echo "No se pudo generar un comando. Por favor verifica la solicitud o intenta nuevamente."
  exit 1
fi

# Mostrar el comando sugerido
echo "Comando sugerido: $response"

# Ejecutar el comando sugerido
# eval "$response"
