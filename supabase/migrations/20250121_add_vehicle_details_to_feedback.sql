-- Erweitere error_code_feedback um lesbare Fahrzeugdaten
ALTER TABLE error_code_feedback
  ADD COLUMN IF NOT EXISTS vehicle_make TEXT,
  ADD COLUMN IF NOT EXISTS vehicle_model TEXT,
  ADD COLUMN IF NOT EXISTS vehicle_year INTEGER;

-- Index für bessere Performance
CREATE INDEX IF NOT EXISTS idx_error_code_feedback_vehicle_details 
  ON error_code_feedback(vehicle_make, vehicle_model, vehicle_year);

COMMENT ON COLUMN error_code_feedback.vehicle_make IS 'Fahrzeugmarke (z.B. Audi, BMW) für lesbare Zuordnung';
COMMENT ON COLUMN error_code_feedback.vehicle_model IS 'Fahrzeugmodell (z.B. RS4, 320d) für lesbare Zuordnung';
COMMENT ON COLUMN error_code_feedback.vehicle_year IS 'Baujahr des Fahrzeugs für lesbare Zuordnung';
