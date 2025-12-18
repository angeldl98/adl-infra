#!/usr/bin/env bash
set -euo pipefail

RUNTIME_ENV="/opt/adl-suite/data/secrets/runtime.env"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$ROOT_DIR/.env"

echo "[bootstrap] Verificando runtime env: $RUNTIME_ENV"
if [ ! -f "$RUNTIME_ENV" ]; then
  echo "[bootstrap][error] Falta $RUNTIME_ENV. Crea el archivo con las variables requeridas (GATEWAY_API_KEY, credenciales BOE, etc.)." >&2
  exit 1
fi

# Asegurar .env ignorado
if ! grep -q '^\\.env$' "$ROOT_DIR/.gitignore" 2>/dev/null; then
  echo ".env" >> "$ROOT_DIR/.gitignore"
fi

# Crear .env vacío con comentario si no existe
if [ ! -f "$ENV_FILE" ]; then
  cat > "$ENV_FILE" <<'EOF'
# Local env (sin secretos). Los secretos reales viven en /opt/adl-suite/data/secrets/runtime.env
# Añade overrides locales si es necesario.
EOF
  echo "[bootstrap] .env creado en $ENV_FILE (sin secretos)."
else
  echo "[bootstrap] .env ya existe, no se modifica."
fi

echo "[bootstrap] Endpoint oficial: POST http://localhost:4000/api/subastas/sync"
echo "[bootstrap] Listo. No se ha levantado ningún servicio."

