#!/bin/bash
#
# Wrapper script for pipeline_runs retention
# Executes SQL cleanup and logs results
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQL_FILE="${SCRIPT_DIR}/cleanup-pipeline-runs.sql"
LOG_DIR="/opt/adl-suite/data/logs/maintenance"
LOG_FILE="${LOG_DIR}/pipeline-runs-cleanup.log"

# Ensure log directory exists
mkdir -p "${LOG_DIR}"

# Log execution
echo "===========================================================" | tee -a "${LOG_FILE}"
echo "Pipeline Runs Cleanup - $(date -Iseconds)" | tee -a "${LOG_FILE}"
echo "===========================================================" | tee -a "${LOG_FILE}"

# Execute cleanup via Docker (adl-infra stack)
docker compose -f /opt/adl-suite/adl-infra/docker-compose.yml exec -T postgres \
  psql -U adl -d adl_core -f - < "${SQL_FILE}" 2>&1 | tee -a "${LOG_FILE}"

EXIT_CODE=${PIPESTATUS[0]}

if [ $EXIT_CODE -eq 0 ]; then
  echo "✓ Cleanup completed successfully" | tee -a "${LOG_FILE}"
else
  echo "✗ Cleanup failed with exit code: $EXIT_CODE" | tee -a "${LOG_FILE}"
fi

echo "" | tee -a "${LOG_FILE}"

exit $EXIT_CODE

