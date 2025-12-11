-- ============================================================================
-- CRON Job: Auto Cleanup Stuck Harvester Items
-- Räumt hängende Items automatisch auf (alle 30 Minuten)
-- ============================================================================

-- Cleanup-Funktion erstellen
CREATE OR REPLACE FUNCTION cleanup_stuck_harvester_items()
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  stuck_item RECORD;
  cutoff_time TIMESTAMPTZ;
  reset_count INTEGER := 0;
  failed_count INTEGER := 0;
BEGIN
  -- Items älter als 10 Minuten
  cutoff_time := NOW() - INTERVAL '10 minutes';
  
  RAISE NOTICE 'Cleanup gestartet. Cutoff: %', cutoff_time;
  
  -- Alle hängenden Items finden
  FOR stuck_item IN 
    SELECT * 
    FROM knowledge_harvest_queue
    WHERE status = 'processing'
      AND last_attempt_at < cutoff_time
  LOOP
    IF stuck_item.attempts >= 3 THEN
      -- Max Retries erreicht → failed_topics
      INSERT INTO failed_topics (topic, error_code, error_message, retry_count, status)
      VALUES (
        stuck_item.topic,
        'timeout',
        'Item stuck in processing for >10 minutes after ' || stuck_item.attempts || ' attempts',
        stuck_item.attempts,
        'failed'
      )
      ON CONFLICT (topic) DO UPDATE SET
        error_message = EXCLUDED.error_message,
        retry_count = EXCLUDED.retry_count,
        updated_at = NOW();
      
      -- Queue-Item als failed markieren
      UPDATE knowledge_harvest_queue
      SET status = 'failed',
          error_message = 'Failed after ' || stuck_item.attempts || ' attempts (auto-cleanup)'
      WHERE id = stuck_item.id;
      
      failed_count := failed_count + 1;
      RAISE NOTICE 'Failed: % (attempts: %)', stuck_item.topic, stuck_item.attempts;
      
    ELSE
      -- Retry möglich → zurück auf pending
      UPDATE knowledge_harvest_queue
      SET status = 'pending',
          error_message = 'Reset from stuck processing state (auto-cleanup)'
      WHERE id = stuck_item.id;
      
      reset_count := reset_count + 1;
      RAISE NOTICE 'Reset to pending: % (attempts: %)', stuck_item.topic, stuck_item.attempts;
    END IF;
  END LOOP;
  
  RAISE NOTICE 'Cleanup abgeschlossen. Reset: %, Failed: %', reset_count, failed_count;
END;
$$;

-- CRON Job erstellen (alle 30 Minuten)
SELECT cron.schedule(
  'cleanup-stuck-harvester-items',
  '*/30 * * * *',  -- Alle 30 Minuten
  $$SELECT cleanup_stuck_harvester_items();$$
);

-- Kommentar
COMMENT ON FUNCTION cleanup_stuck_harvester_items IS 
  'Automatisches Cleanup von hängenden Harvester-Items. 
   Läuft alle 30 Minuten via Cron-Job.';

-- Test (optional): Sofort ausführen
-- SELECT cleanup_stuck_harvester_items();
