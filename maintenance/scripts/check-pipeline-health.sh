#!/bin/bash
set -euo pipefail

COMPOSE_FILE="/opt/adl-suite/adl-infra/docker-compose.yml"
LOG_FILE="/opt/adl-suite/data/logs/pipeline-health.log"
VERBOSE=false

if [[ "${1:-}" == "--verbose" ]]; then
  VERBOSE=true
fi

mkdir -p "$(dirname "${LOG_FILE}")"

log() {
  local level="$1"
  shift
  echo "[$(date -Iseconds)] [$level] $*" | tee -a "${LOG_FILE}"
}

log_verbose() {
  if [ "$VERBOSE" = true ]; then
    log "INFO" "$*"
  fi
}

pg_env_args=()
if [ -n "${POSTGRES_PASSWORD:-}" ]; then
  pg_env_args=(-e "PGPASSWORD=${POSTGRES_PASSWORD}")
fi

query() {
  docker compose -f "${COMPOSE_FILE}" exec -T "${pg_env_args[@]}" postgres \
    psql -U adl -d adl_core -t -c "$1" | xargs
}

check_recent_errors() {
  local pipeline="$1"
  local lookback_hours="${2:-1}"

  local errors
  errors=$(query "
    SELECT COUNT(*)
    FROM pipeline_runs
    WHERE pipeline = '${pipeline}'
      AND started_at > NOW() - INTERVAL '${lookback_hours} hours'
      AND status = 'error';
  ")
  errors=${errors:-0}

  if [ "${errors}" -gt 0 ]; then
    log "ALERT" "${pipeline}: ${errors} error(s) in last ${lookback_hours} hour(s)"
    docker compose -f "${COMPOSE_FILE}" exec -T "${pg_env_args[@]}" postgres \
      psql -U adl -d adl_core -c "
        SELECT 
          to_char(started_at, 'YYYY-MM-DD HH24:MI:SS') AS started,
          to_char(finished_at, 'YYYY-MM-DD HH24:MI:SS') AS finished,
          status
        FROM pipeline_runs
        WHERE pipeline = '${pipeline}'
          AND started_at > NOW() - INTERVAL '${lookback_hours} hours'
          AND status = 'error'
        ORDER BY started_at DESC
        LIMIT 5;
      " | tee -a "${LOG_FILE}"
    return 1
  else
    log_verbose "${pipeline}: No errors in last ${lookback_hours} hour(s)"
    return 0
  fi
}

check_consecutive_errors() {
  local pipeline="$1"
  local threshold="${2:-3}"

  local consecutive
  consecutive=$(query "
    WITH recent_runs AS (
      SELECT status
      FROM pipeline_runs
      WHERE pipeline = '${pipeline}'
        AND status IN ('ok', 'error', 'degraded')
      ORDER BY started_at DESC
      LIMIT ${threshold}
    )
    SELECT COUNT(*) FROM recent_runs WHERE status = 'error';
  ")
  consecutive=${consecutive:-0}

  if [ "${consecutive}" -eq "${threshold}" ]; then
    log "CRITICAL" "${pipeline}: ${threshold} consecutive errors detected"
    return 1
  else
    log_verbose "${pipeline}: No consecutive errors (${consecutive}/${threshold})"
    return 0
  fi
}

check_stalled_pipeline() {
  local pipeline="$1"
  local expected_interval_minutes="$2"

  local last_run_minutes
  last_run_minutes=$(query "
    SELECT COALESCE(
      EXTRACT(EPOCH FROM (NOW() - MAX(started_at)))/60,
      999999
    )
    FROM pipeline_runs
    WHERE pipeline = '${pipeline}';
  ")
  last_run_minutes=${last_run_minutes:-999999}

  local threshold=$((expected_interval_minutes * 2))
  local is_stalled
  is_stalled=$(awk -v last="${last_run_minutes}" -v threshold="${threshold}" 'BEGIN { print (last > threshold) ? 1 : 0 }')

  if [ "${is_stalled}" -eq 1 ]; then
    log "ALERT" "${pipeline}: Stalled (last run ${last_run_minutes} min ago, expected every ${expected_interval_minutes} min)"
    return 1
  else
    log_verbose "${pipeline}: Normal (last run ${last_run_minutes} min ago)"
    return 0
  fi
}

check_degraded_mode() {
  local pipeline="$1"
  local lookback_hours="${2:-24}"

  local degraded_count
  degraded_count=$(query "
    SELECT COUNT(*)
    FROM pipeline_runs
    WHERE pipeline = '${pipeline}'
      AND started_at > NOW() - INTERVAL '${lookback_hours} hours'
      AND status = 'degraded';
  ")
  degraded_count=${degraded_count:-0}

  if [ "${degraded_count}" -gt 0 ]; then
    log "WARN" "${pipeline}: ${degraded_count} degraded run(s) in last ${lookback_hours} hour(s)"
    return 1
  else
    log_verbose "${pipeline}: No degraded runs in last ${lookback_hours} hour(s)"
    return 0
  fi
}

generate_summary() {
  log "INFO" "=== Pipeline Health Summary ==="

  local total recent errors degraded
  total=$(query "SELECT COUNT(*) FROM pipeline_runs;")
  recent=$(query "SELECT COUNT(*) FROM pipeline_runs WHERE started_at > NOW() - INTERVAL '24 hours';")
  errors=$(query "SELECT COUNT(*) FROM pipeline_runs WHERE started_at > NOW() - INTERVAL '24 hours' AND status = 'error';")
  degraded=$(query "SELECT COUNT(*) FROM pipeline_runs WHERE started_at > NOW() - INTERVAL '24 hours' AND status = 'degraded';")

  log "INFO" "Total runs: ${total}"
  log "INFO" "Runs (24h): ${recent}"
  log "INFO" "Errors (24h): ${errors}"
  log "INFO" "Degraded (24h): ${degraded}"
  log "INFO" "================================"
}

main() {
  log "INFO" "Starting pipeline health check"

  local has_issues=false

  generate_summary

  log "INFO" "Checking boe-raw..."
  check_recent_errors "boe-raw" 1 || has_issues=true
  check_consecutive_errors "boe-raw" 3 || has_issues=true
  check_stalled_pipeline "boe-raw" 15 || has_issues=true
  check_degraded_mode "boe-raw" 24 || has_issues=true

  log "INFO" "Checking pharma-raw..."
  check_recent_errors "pharma-raw" 1 || has_issues=true
  check_consecutive_errors "pharma-raw" 3 || has_issues=true
  check_stalled_pipeline "pharma-raw" 5 || has_issues=true

  if [ "$has_issues" = true ]; then
    log "WARN" "Health check completed with ISSUES"
    echo ""
    echo "⚠️  Issues detected. Review: ${LOG_FILE}"
    exit 1
  else
    log "INFO" "Health check completed - all pipelines healthy"
    echo ""
    echo "✓ All pipelines healthy"
    exit 0
  fi
}

main "$@"

