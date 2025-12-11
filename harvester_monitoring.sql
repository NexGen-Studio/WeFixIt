-- ============================================================================
-- HARVESTER MONITORING DASHBOARD
-- Führe dieses SQL im Supabase SQL Editor aus um den Status zu prüfen
-- ============================================================================

-- 1. CRON-JOBS STATUS
SELECT '=== CRON JOBS ===' as section;
SELECT 
  jobname,
  schedule,
  active,
  command as "command (gekürzt)"
FROM cron.job
ORDER BY jobid;

-- 2. QUEUE STATUS (Letzte Stunde)
SELECT '=== QUEUE STATUS (1h) ===' as section;
SELECT 
  status,
  COUNT(*) as count,
  MAX(created_at) as last_update
FROM knowledge_harvest_queue
WHERE created_at > NOW() - INTERVAL '1 hour'
GROUP BY status
ORDER BY status;

-- 3. AKTUELLE PROCESSING ITEMS
SELECT '=== AKTUELL IN VERARBEITUNG ===' as section;
SELECT 
  topic,
  attempts,
  last_attempt_at,
  NOW() - last_attempt_at as processing_duration
FROM knowledge_harvest_queue
WHERE status = 'processing'
ORDER BY last_attempt_at DESC
LIMIT 10;

-- 4. HÄNGENDE ITEMS (älter als 10 Min)
SELECT '=== HÄNGENDE ITEMS (>10 Min) ===' as section;
SELECT 
  topic,
  attempts,
  last_attempt_at,
  NOW() - last_attempt_at as stuck_duration,
  error_message
FROM knowledge_harvest_queue
WHERE status = 'processing'
  AND last_attempt_at < NOW() - INTERVAL '10 minutes'
ORDER BY last_attempt_at;

-- 5. LETZTE FEHLER
SELECT '=== FAILED TOPICS (Letzte 20) ===' as section;
SELECT 
  topic,
  error_code,
  error_message,
  retry_count,
  created_at
FROM failed_topics
ORDER BY created_at DESC
LIMIT 20;

-- 6. LETZTE ERFOLGE
SELECT '=== LETZTE ERFOLGE ===' as section;
SELECT 
  topic,
  last_attempt_at as completed_at,
  attempts
FROM knowledge_harvest_queue
WHERE status = 'completed'
ORDER BY last_attempt_at DESC
LIMIT 10;

-- 7. ERFOLGSRATE (Letzte 24h)
SELECT '=== ERFOLGSRATE (24h) ===' as section;
SELECT 
  status,
  COUNT(*) as count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
FROM knowledge_harvest_queue
WHERE created_at > NOW() - INTERVAL '24 hours'
GROUP BY status
ORDER BY count DESC;

-- 8. PERFORMANCE PRO STUNDE (Heute)
SELECT '=== ITEMS PRO STUNDE (Heute) ===' as section;
SELECT 
  DATE_TRUNC('hour', created_at) as hour,
  status,
  COUNT(*) as count
FROM knowledge_harvest_queue
WHERE created_at > CURRENT_DATE
GROUP BY hour, status
ORDER BY hour DESC, status;

-- 9. GESAMT-STATISTIK
SELECT '=== GESAMT-STATISTIK ===' as section;
SELECT 
  COUNT(*) FILTER (WHERE status = 'completed') as completed,
  COUNT(*) FILTER (WHERE status = 'pending') as pending,
  COUNT(*) FILTER (WHERE status = 'processing') as processing,
  COUNT(*) FILTER (WHERE status = 'failed') as failed,
  COUNT(*) as total,
  ROUND(COUNT(*) FILTER (WHERE status = 'completed') * 100.0 / NULLIF(COUNT(*), 0), 2) as success_rate
FROM knowledge_harvest_queue;

-- 10. AUTOMOTIVE KNOWLEDGE (Gespeicherte Artikel)
SELECT '=== AUTOMOTIVE KNOWLEDGE ===' as section;
SELECT 
  COUNT(*) as total_articles,
  COUNT(DISTINCT category) as categories,
  MAX(created_at) as last_article
FROM automotive_knowledge;
