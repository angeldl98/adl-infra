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

# Ensure psql client (for counts/fail-fast)
if ! command -v psql >/dev/null 2>&1; then
  apt-get update >/dev/null 2>&1 && apt-get install -y postgresql-client >/dev/null 2>&1 || {
    echo "[$(date --iso-8601=seconds)] RUN_FAIL psql install failed"
    exit 1
  }
fi

psql_q() {
  PGPASSWORD="${POSTGRES_PASSWORD:-}" psql -h "${POSTGRES_HOST:-postgres}" -U "${POSTGRES_USER:-adl}" -d "${POSTGRES_DB:-adl_core}" -Atc "$1"
}

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
run_step_with_ci "raw_scraper" "/opt/adl-suite/adl-boe-raw-scraper" bash -lc "npx playwright install --with-deps chromium && npm run scrape:cron"

raw_count_before=$(psql_q "SELECT COUNT(*) FROM boe_subastas_raw;")

# BOE normalizer (build + run)
run_step_with_ci "normalizer" "/opt/adl-suite/adl-boe-normalizer" bash -lc "npm run build && npm start"

raw_count_after=$(psql_q "SELECT COUNT(*) FROM boe_subastas_raw;")
norm_count_before=$(psql_q "SELECT COUNT(*) FROM boe_subastas;")

if [ "${raw_count_after:-0}" -le "${raw_count_before:-0}" ]; then
  echo "[$(date --iso-8601=seconds)] RUN_FAIL normalizer blocked (no new raw rows) raw_before=${raw_count_before} raw_after=${raw_count_after}"
  exit 1
fi

norm_count_after=$(psql_q "SELECT COUNT(*) FROM boe_subastas;")

# BOE analyst publish (build + run plugin=boe)
run_step_with_ci "analyst_boe" "/opt/adl-suite/adl-data-analyst" bash -lc "npm run build && node dist/src/index.js --plugin=boe"

prod_count_after=$(psql_q "SELECT COUNT(*) FROM boe_prod.subastas_pro;")
sum_count_after=$(psql_q "SELECT COUNT(*) FROM boe_prod.subastas_summary;")

if [ "${norm_count_after:-0}" -le "${norm_count_before:-0}" ]; then
  echo "[$(date --iso-8601=seconds)] RUN_FAIL analyst skipped (no normalized rows) norm_before=${norm_count_before} norm_after=${norm_count_after}"
  exit 1
fi

if [ "${prod_count_after:-0}" -le 0 ]; then
  echo "[$(date --iso-8601=seconds)] RUN_FAIL analyst produced zero prod rows prod=${prod_count_after} summary=${sum_count_after}"
  exit 1
fi

# BOE analyst publish (build + run plugin=boe)
echo "[$(date --iso-8601=seconds)] METRICS raw_before=${raw_count_before} raw_after=${raw_count_after} norm_before=${norm_count_before} norm_after=${norm_count_after} prod=${prod_count_after} summary=${sum_count_after}"
' || {
  echo "[$(date --iso-8601=seconds)] RUN_FAIL boe-runner lock busy or failed"
  exit 1
}

echo "[$(date --iso-8601=seconds)] RUN_OK boe-runner"

