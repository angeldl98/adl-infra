# ADL Suite Maintenance Scripts

## Pipeline Runs Retention

### Purpose
Automatically delete old records from `pipeline_runs` table to prevent unbounded growth.

### Configuration
- **Retention period**: 90 days
- **Execution**: Daily at 03:00 AM (±10 min)
- **Batch size**: 1000 records per iteration
- **Method**: DELETE with WHERE clause (no partitioning)

### Files
- `scripts/cleanup-pipeline-runs.sql` - SQL cleanup logic
- `scripts/cleanup-pipeline-runs.sh` - Bash wrapper with logging
- `/etc/systemd/system/pipeline-runs-cleanup.service` - systemd service
- `/etc/systemd/system/pipeline-runs-cleanup.timer` - systemd timer

### Logs
- systemd journal: `journalctl -u pipeline-runs-cleanup.service`
- File log: `/opt/adl-suite/data/logs/maintenance/pipeline-runs-cleanup.log`

### Manual Execution
```bash
# Check timer status
sudo systemctl status pipeline-runs-cleanup.timer

# Run cleanup manually (does not affect timer schedule)
sudo systemctl start pipeline-runs-cleanup.service

# View logs
sudo journalctl -u pipeline-runs-cleanup.service -n 50
tail -f /opt/adl-suite/data/logs/maintenance/pipeline-runs-cleanup.log
```

### Monitoring
```sql
-- Check retention status
SELECT 
  COUNT(*) as total_records,
  MIN(started_at) as oldest_record,
  MAX(started_at) as newest_record,
  NOW() - MIN(started_at) as retention_age
FROM pipeline_runs;
```

### Modifying Retention Period
Edit `maintenance/scripts/cleanup-pipeline-runs.sql`:
```sql
retention_days INT := 90;  -- Change this value
```
Then reload:
```bash
sudo systemctl daemon-reload
```

### Disabling Cleanup
```bash
# Stop and disable timer
sudo systemctl stop pipeline-runs-cleanup.timer
sudo systemctl disable pipeline-runs-cleanup.timer
```

## Important Notes

- Cleanup runs during low-traffic hours (3 AM)
- Batched deletes prevent long table locks
- Does NOT affect scraper or normalizer operations
- Safe to run manually at any time
- Persistent timer ensures missed runs execute on next boot

