#!/usr/bin/env bash
set -euo pipefail

LOCK_DIR="/opt/adl-suite/data/locks"
LOCK_FILE="${LOCK_DIR}/boe-runner.lock"
LOG_FILE="/opt/adl-suite/logs/boe-runner.log"

mkdir -p "${LOCK_DIR}"
mkdir -p "$(dirname "${LOG_FILE}")"

exec >>"${LOG_FILE}" 2>&1
echo "[$(date --iso-8601=seconds)] RUN_START boe-runner"

if ! command -v flock >/dev/null 2>&1; then
  echo "flock not found; cannot ensure single execution"
  exit 1
fi

flock -n "${LOCK_FILE}" bash -c '
set -euo pipefail

run_step() {
  local name="$1"
  shift
  echo "[$(date --iso-8601=seconds)] STEP_START ${name}"
  (cd "$1" && shift && "$@")
  echo "[$(date --iso-8601=seconds)] STEP_OK ${name}"
}

run_step_with_ci() {
  local name="$1"
  local dir="$2"
  shift 2
  run_step "${name}:npm-ci" "${dir}" npm ci
  run_step "${name}:run" "${dir}" "$@"
}

# BOE RAW scraper (headless cron scrape)
run_step_with_ci "raw_scraper" "/opt/adl-suite/adl-boe-raw-scraper" npm run scrape:cron

# BOE normalizer (build + run)
run_step_with_ci "normalizer" "/opt/adl-suite/adl-boe-normalizer" bash -lc "npm run build && npm start"

# BOE analyst publish (build + run plugin=boe)
run_step_with_ci "analyst_boe" "/opt/adl-suite/adl-data-analyst" bash -lc "npm run build && node dist/src/index.js --plugin=boe"
' || {
  echo "[$(date --iso-8601=seconds)] RUN_FAIL boe-runner lock busy or failed"
  exit 1
}

echo "[$(date --iso-8601=seconds)] RUN_OK boe-runner"

