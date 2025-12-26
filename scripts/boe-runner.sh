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

# Ensure Python + Great Expectations for analyst quality gate
if ! command -v python3 >/dev/null 2>&1; then
  apt-get update >/dev/null 2>&1 && apt-get install -y python3 python3-pip >/dev/null 2>&1 || {
    echo "[$(date --iso-8601=seconds)] RUN_FAIL python3 install failed"
    exit 1
  }
fi

python3 - <<'PY' >/dev/null 2>&1 || {
import importlib
import sys
for mod in ("pandas", "great_expectations"):
    try:
        importlib.import_module(mod)
    except ImportError:
        sys.exit(1)
sys.exit(0)
}
if [ $? -ne 0 ]; then
  pip3 install --no-cache-dir pandas great_expectations >/dev/null 2>&1 || {
    echo "[$(date --iso-8601=seconds)] RUN_FAIL great_expectations install failed"
    exit 1
  }
fi

psql_q() {
  PGPASSWORD="${POSTGRES_PASSWORD:-}" psql -h "${POSTGRES_HOST:-postgres}" -U "${POSTGRES_USER:-adl}" -d "${POSTGRES_DB:-adl_core}" -Atc "$1"
}

flock -n "${LOCK_FILE}" bash -c '
set -euo pipefail

log_fail() {
  echo "[$(date --iso-8601=seconds)] RUN_FAIL $1"
  exit 1
}

run_step() {
  local name="$1"
  shift
  echo "[$(date --iso-8601=seconds)] STEP_START ${name}"
  if (cd "$1" && shift && "$@"); then
    echo "[$(date --iso-8601=seconds)] STEP_OK ${name}"
  else
    echo "[$(date --iso-8601=seconds)] STEP_FAIL ${name}"
    exit 1
  fi
}

run_step_with_ci() {
  local name="$1"
  local dir="$2"
  shift 2
  run_step "${name}:npm-ci" "${dir}" npm ci
  run_step "${name}:run" "${dir}" "$@"
}

raw_count_before=$(psql_q "SELECT COUNT(*) FROM boe_subastas_raw;")

# BOE RAW scraper (headless cron scrape)
run_step_with_ci "raw_scraper" "/opt/adl-suite/adl-boe-raw-scraper" bash -lc "npx playwright install --with-deps chromium && npm run scrape:cron"

raw_count_after=$(psql_q "SELECT COUNT(*) FROM boe_subastas_raw;")
if [ "${raw_count_after:-0}" -le "${raw_count_before:-0}" ]; then
  log_fail "raw produced no new rows raw_before=${raw_count_before} raw_after=${raw_count_after}"
fi

norm_count_before=$(psql_q "SELECT COUNT(*) FROM boe_subastas;")

# BOE normalizer (build + run)
run_step_with_ci "normalizer" "/opt/adl-suite/adl-boe-normalizer" bash -lc "npm run build && npm start"

norm_count_after=$(psql_q "SELECT COUNT(*) FROM boe_subastas;")
if [ "${norm_count_after:-0}" -le "${norm_count_before:-0}" ]; then
  log_fail "normalizer produced no rows norm_before=${norm_count_before} norm_after=${norm_count_after}"
fi

prod_count_before=$(psql_q "SELECT COUNT(*) FROM boe_prod.subastas_pro;")
sum_count_before=$(psql_q "SELECT COUNT(*) FROM boe_prod.subastas_summary;")

# BOE analyst publish (build + run plugin=boe)
run_step_with_ci "analyst_boe" "/opt/adl-suite/adl-data-analyst" bash -lc "npm run build && node dist/src/index.js --plugin=boe"

prod_count_after=$(psql_q "SELECT COUNT(*) FROM boe_prod.subastas_pro;")
sum_count_after=$(psql_q "SELECT COUNT(*) FROM boe_prod.subastas_summary;")

if [ "${prod_count_after:-0}" -le "${prod_count_before:-0}" ]; then
  log_fail "analyst produced zero prod rows prod_before=${prod_count_before} prod_after=${prod_count_after} summary_after=${sum_count_after}"
fi

echo "[$(date --iso-8601=seconds)] METRICS raw_before=${raw_count_before} raw_after=${raw_count_after} norm_before=${norm_count_before} norm_after=${norm_count_after} prod_before=${prod_count_before} prod_after=${prod_count_after} summary_before=${sum_count_before} summary_after=${sum_count_after}"
' || {
  echo "[$(date --iso-8601=seconds)] RUN_FAIL boe-runner lock busy or failed"
  exit 1
}

echo "[$(date --iso-8601=seconds)] RUN_OK boe-runner"

