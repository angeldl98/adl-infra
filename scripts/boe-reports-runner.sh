#!/usr/bin/env bash
set -euo pipefail

ts() { date --iso-8601=seconds; }
log() { echo "[$(ts)] $*"; }

log "STEP_START boe_reports"
cd /opt/adl-suite/adl-data-analyst
npm ci --quiet
npm run build --silent
node dist/src/boe/reports/run.js
log "RUN_OK boe_reports"

