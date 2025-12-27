#!/usr/bin/env bash
set -euo pipefail

CRON_FILE="/etc/cron.d/adl-boe-reports"
LOG_DIR="/opt/adl-suite/logs"

mkdir -p "${LOG_DIR}"

cat > "${CRON_FILE}" <<'EOF'
0 9 * * 1 root cd /opt/adl-suite && /usr/bin/docker compose run --rm boe-reports-runner >> /opt/adl-suite/logs/boe-reports.log 2>&1
EOF

chmod 644 "${CRON_FILE}"
echo "Cron installed at ${CRON_FILE}"

