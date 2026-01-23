-- Migration: Erweitere error_code_feedback um Fahrzeuginformation
-- Datum: 2025-01-21
-- Beschreibung: Speichere welches Fahrzeug bei diesem Feedback verwendet wurde

-- Füge vehicle_id Spalte hinzu
ALTER TABLE error_code_feedback
  ADD COLUMN vehicle_id UUID REFERENCES vehicles(id) ON DELETE SET NULL;

-- Füge Index für schnelle Abfragen hinzu
CREATE INDEX IF NOT EXISTS idx_error_code_feedback_vehicle 
  ON error_code_feedback(vehicle_id);

-- Kommentar für Dokumentation
COMMENT ON COLUMN error_code_feedback.vehicle_id IS 'Fahrzeug-ID falls Feedback zu fahrzeugspezifischer Ursache';
