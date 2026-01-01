-- Pipeline Runs Retention Script
-- Deletes records older than 90 days
-- Executed daily via systemd timer

DO $$
DECLARE
  deleted_count INT := 0;
  batch_size INT := 1000;
  retention_days INT := 90;
  cutoff_date TIMESTAMP;
  rows_deleted INT;
BEGIN
  -- Calculate cutoff date
  cutoff_date := NOW() - INTERVAL '90 days';
  
  RAISE NOTICE 'Starting pipeline_runs cleanup';
  RAISE NOTICE 'Cutoff date: %', cutoff_date;
  
  -- Delete in batches to avoid long locks
  LOOP
    DELETE FROM pipeline_runs
    WHERE id IN (
      SELECT id
      FROM pipeline_runs
      WHERE started_at < cutoff_date
      ORDER BY started_at ASC
      LIMIT batch_size
    );
    
    GET DIAGNOSTICS rows_deleted = ROW_COUNT;
    deleted_count := deleted_count + rows_deleted;
    
    EXIT WHEN rows_deleted = 0;
    
    -- Log progress
    RAISE NOTICE 'Deleted % rows (total: %)', rows_deleted, deleted_count;
    
    -- Small delay between batches to reduce lock contention
    PERFORM pg_sleep(0.1);
  END LOOP;
  
  RAISE NOTICE 'Cleanup complete. Total deleted: %', deleted_count;
  
  -- Log retention stats
  RAISE NOTICE 'Remaining records: %', (SELECT COUNT(*) FROM pipeline_runs);
  RAISE NOTICE 'Oldest record: %', (SELECT MIN(started_at) FROM pipeline_runs);
  RAISE NOTICE 'Newest record: %', (SELECT MAX(started_at) FROM pipeline_runs);
END $$;

