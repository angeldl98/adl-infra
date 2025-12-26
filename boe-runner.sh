#!/usr/bin/env bash
set -euo pipefail

LOCK_DIR="/opt/adl-suite/data/locks"
LOCK_FILE="${LOCK_DIR}/boe-runner.lock"
LOG_FILE="/opt/adl-suite/logs/boe-runner.log"

mkdir -p "${LOCK_DIR}"
mkdir -p "$(dirname "${LOG_FILE}")"

exec >>"${LOG_FILE}" 2>&1
echo "[$(date --iso-8601=seconds)] boe-runner start"

if ! command -v flock >/dev/null 2>&1; then
  echo "flock not found; cannot ensure single execution"
  exit 1
fi

flock -n "${LOCK_FILE}" bash -c '
  set -euo pipefail

  run_step() {
    local name="$1"
    shift
    echo "[$(date --iso-8601=seconds)] step ${name} start"
    (cd "$1" && shift && "$@")
    echo "[$(date --iso-8601=seconds)] step ${name} end"
  }

  # BOE RAW scraper (includes controlled PDF fetch step inside npm start)
  run_step "raw+pdf" "/opt/adl-suite/adl-boe-raw-scraper" /usr/bin/env PATH="/usr/local/bin:/usr/bin:/bin" npm start

  # BOE normalizer
  run_step "normalizer" "/opt/adl-suite/adl-boe-normalizer" /usr/bin/env PATH="/usr/local/bin:/usr/bin:/bin" npm start
' || {
  echo "[$(date --iso-8601=seconds)] boe-runner lock busy or failed"
  exit 1
}

echo "[$(date --iso-8601=seconds)] boe-runner end"

