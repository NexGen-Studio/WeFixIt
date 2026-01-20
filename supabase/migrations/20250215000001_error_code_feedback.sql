-- Migration: Erstelle error_code_feedback Tabelle
-- Datum: 2025-02-15
-- Beschreibung: User-Feedback zu Reparaturanleitungen

-- Tabelle für User-Feedback
CREATE TABLE IF NOT EXISTS error_code_feedback (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  error_code TEXT NOT NULL,
  cause_key TEXT NOT NULL,
  was_helpful BOOLEAN NOT NULL DEFAULT false,
  feedback_text TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  -- Verhindere mehrfaches Feedback für gleichen Code+Ursache
  UNIQUE(user_id, error_code, cause_key)
);

-- Index für schnelle Abfragen
CREATE INDEX IF NOT EXISTS idx_error_code_feedback_user 
  ON error_code_feedback(user_id);

CREATE INDEX IF NOT EXISTS idx_error_code_feedback_code 
  ON error_code_feedback(error_code);

CREATE INDEX IF NOT EXISTS idx_error_code_feedback_helpful 
  ON error_code_feedback(was_helpful);

-- RLS Policies
ALTER TABLE error_code_feedback ENABLE ROW LEVEL SECURITY;

-- User kann eigene Feedbacks lesen
CREATE POLICY "Users can view own feedback"
  ON error_code_feedback
  FOR SELECT
  USING (auth.uid() = user_id);

-- User kann eigene Feedbacks erstellen
CREATE POLICY "Users can create own feedback"
  ON error_code_feedback
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- User kann eigene Feedbacks updaten
CREATE POLICY "Users can update own feedback"
  ON error_code_feedback
  FOR UPDATE
  USING (auth.uid() = user_id);

-- Kommentar für Dokumentation
COMMENT ON TABLE error_code_feedback IS 'User-Feedback zu Reparaturanleitungen: War die Anleitung hilfreich?';
COMMENT ON COLUMN error_code_feedback.error_code IS 'OBD2-Fehlercode (z.B. P0420)';
COMMENT ON COLUMN error_code_feedback.cause_key IS 'Key der Ursache aus repair_guides JSONB';
COMMENT ON COLUMN error_code_feedback.was_helpful IS 'War die Reparaturanleitung hilfreich?';
COMMENT ON COLUMN error_code_feedback.feedback_text IS 'Optional: Zusätzlicher Feedback-Text vom User';
