#!/usr/bin/env bash
set -euo pipefail

ts() { date --iso-8601=seconds; }
log() { echo "[$(ts)] $*"; }

log "STEP_START pharma_raw_scraper"
cd /opt/adl-suite/adl-pharma-raw-scraper
npm ci --quiet
npm start
log "STEP_OK pharma_raw_scraper"

log "STEP_START pharma_normalizer"
cd /opt/adl-suite/adl-pharma-normalizer
npm ci --quiet
npm start
log "STEP_OK pharma_normalizer"

log "STEP_START pharma_analyst"
cd /opt/adl-suite/adl-data-analyst
npm ci --quiet
npm run build --silent
node dist/index.js --plugin pharma
log "STEP_OK pharma_analyst"

log "RUN_OK pharma-runner"

