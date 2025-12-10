-- ============================================================================
-- Failed Topics Tracking
-- Speichert fehlgeschlagene Harvester-Anfragen für späteren Retry
-- ============================================================================

CREATE TABLE IF NOT EXISTS failed_topics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  topic TEXT NOT NULL,
  error_code TEXT,
  error_message TEXT,
  retry_count INTEGER DEFAULT 0,
  last_attempt_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'retrying', 'success', 'failed'))
);

-- Index für schnelle Abfragen
CREATE INDEX idx_failed_topics_status ON failed_topics(status);
CREATE INDEX idx_failed_topics_created ON failed_topics(created_at DESC);

-- RLS aktivieren
ALTER TABLE failed_topics ENABLE ROW LEVEL SECURITY;

-- Policy: Service Role kann alles
CREATE POLICY "Service role can manage failed topics"
ON failed_topics
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- Kommentar
COMMENT ON TABLE failed_topics IS 'Tracking von fehlgeschlagenen Harvester-Anfragen für automatische Wiederholung';
