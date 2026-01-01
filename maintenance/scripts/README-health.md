# Pipeline Health Checker

## Usage
```bash
# Basic check
/opt/adl-suite/adl-infra/maintenance/scripts/check-pipeline-health.sh

# Verbose mode
/opt/adl-suite/adl-infra/maintenance/scripts/check-pipeline-health.sh --verbose
```

## Output

Log file: `/opt/adl-suite/data/logs/pipeline-health.log`

View alerts:
```bash
grep -E "ALERT|CRITICAL|WARN" /opt/adl-suite/data/logs/pipeline-health.log | tail -20
```

## Exit Codes

- `0`: All checks passed
- `1`: Issues detected

## Checks

**boe-raw**:
- Recent errors (1 hour)
- Consecutive errors (3+)
- Stalled (no run in 30+ min)
- Degraded mode (24h count)

**pharma-raw**:
- Recent errors (1 hour)
- Consecutive errors (3+)
- Stalled (no run in 10+ min)

## Optional Cron
```bash
# Hourly check
0 * * * * /opt/adl-suite/adl-infra/maintenance/scripts/check-pipeline-health.sh
```

