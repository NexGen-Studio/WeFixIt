-- ============================================================================
-- CRON Job: Auto Knowledge Harvester
-- Führt den Harvester automatisch alle 10 Minuten aus
-- ============================================================================

-- Aktiviere pg_cron Extension
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Erstelle CRON Job für automatisches Harvesting
-- Läuft alle 10 Minuten: */10 * * * *
SELECT cron.schedule(
  'auto-knowledge-harvester',        -- Job Name
  '*/10 * * * *',                    -- Alle 10 Minuten
  $$
  SELECT
    net.http_post(
      url := 'https://zbrlhswafnlpfwqikapu.supabase.co/functions/v1/auto-knowledge-harvester',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0'
      ),
      body := '{}'::jsonb
    ) AS request_id;
  $$
);

-- Zeige alle CRON Jobs
SELECT * FROM cron.job WHERE jobname = 'auto-knowledge-harvester';

-- WICHTIG: Wenn du den CRON stoppen willst:
-- SELECT cron.unschedule('auto-knowledge-harvester');

-- Kommentar
COMMENT ON EXTENSION pg_cron IS 
  'CRON-Scheduler für automatisches Knowledge Harvesting. 
   Läuft alle 10 Minuten und sammelt automatisch neue Artikel.';
