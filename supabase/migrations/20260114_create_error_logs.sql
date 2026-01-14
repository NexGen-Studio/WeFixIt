-- Tabelle für Error Logging
CREATE TABLE IF NOT EXISTS error_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  error_type TEXT NOT NULL,
  error_message TEXT NOT NULL,
  stack_trace TEXT,
  screen TEXT,
  error_code TEXT, -- z.B. OBD2 Code falls relevant
  device_info JSONB, -- OS, Model, App Version
  context JSONB, -- Zusätzlicher Kontext (z.B. welche Funktion, Parameter, etc.)
  severity TEXT CHECK (severity IN ('low', 'medium', 'high', 'critical')) DEFAULT 'medium',
  resolved BOOLEAN DEFAULT FALSE,
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index für schnelle Abfragen
CREATE INDEX idx_error_logs_user_id ON error_logs(user_id);
CREATE INDEX idx_error_logs_created_at ON error_logs(created_at DESC);
CREATE INDEX idx_error_logs_severity ON error_logs(severity);
CREATE INDEX idx_error_logs_resolved ON error_logs(resolved);

-- RLS aktivieren
ALTER TABLE error_logs ENABLE ROW LEVEL SECURITY;

-- Policy: Service Role kann alles
CREATE POLICY "Service role can manage error_logs"
  ON error_logs
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Policy: Authenticated users können ihre eigenen Fehler sehen
CREATE POLICY "Users can view their own error_logs"
  ON error_logs
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Policy: Authenticated users können eigene Fehler einfügen
CREATE POLICY "Users can insert their own error_logs"
  ON error_logs
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Funktion für automatische Benachrichtigungen (optional)
-- Diese Funktion wird von einem Webhook aufgerufen
CREATE OR REPLACE FUNCTION notify_on_critical_error()
RETURNS TRIGGER AS $$
BEGIN
  -- Nur bei kritischen Fehlern
  IF NEW.severity = 'critical' THEN
    -- Hier könnte ein Webhook aufgerufen werden via pg_net oder Supabase Edge Function
    PERFORM pg_notify('critical_error', json_build_object(
      'error_id', NEW.id,
      'user_id', NEW.user_id,
      'error_message', NEW.error_message,
      'screen', NEW.screen,
      'created_at', NEW.created_at
    )::text);
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger für kritische Fehler
CREATE TRIGGER on_critical_error_trigger
  AFTER INSERT ON error_logs
  FOR EACH ROW
  WHEN (NEW.severity = 'critical')
  EXECUTE FUNCTION notify_on_critical_error();

-- View für Error Statistics (hilfreich für Dashboard)
CREATE OR REPLACE VIEW error_statistics AS
SELECT 
  DATE_TRUNC('day', created_at) as date,
  error_type,
  screen,
  severity,
  COUNT(*) as error_count,
  COUNT(DISTINCT user_id) as affected_users
FROM error_logs
GROUP BY DATE_TRUNC('day', created_at), error_type, screen, severity
ORDER BY date DESC, error_count DESC;

-- Grant permissions
GRANT SELECT ON error_statistics TO authenticated;
GRANT SELECT ON error_statistics TO service_role;
