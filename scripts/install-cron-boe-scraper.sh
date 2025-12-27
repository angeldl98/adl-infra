#!/usr/bin/env bash
set -euo pipefail

CRON_FILE="/etc/cron.d/adl-boe-scraper"
LOG_DIR="/opt/adl-suite/logs"
mkdir -p "${LOG_DIR}"

cat > "${CRON_FILE}" <<'EOF'
30 8 * * * root cd /opt/adl-suite && BOE_PDF_DAILY_BUDGET=10 BOE_PDF_MAX_DAYS_AHEAD=45 BOE_PDF_ONLY_ACTIVE=true BOE_PDF_ONLY_INMUEBLE=true BOE_PDF_DRY_RUN=false /usr/bin/docker compose run --rm boe-runner >> /opt/adl-suite/logs/boe-runner.log 2>&1
30 20 * * * root cd /opt/adl-suite && BOE_PDF_DAILY_BUDGET=10 BOE_PDF_MAX_DAYS_AHEAD=45 BOE_PDF_ONLY_ACTIVE=true BOE_PDF_ONLY_INMUEBLE=true BOE_PDF_DRY_RUN=false /usr/bin/docker compose run --rm boe-runner >> /opt/adl-suite/logs/boe-runner.log 2>&1
EOF

chmod 644 "${CRON_FILE}"
echo "Cron installed at ${CRON_FILE}"

