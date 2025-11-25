-- Migration: Zeitraum-Felder für Versicherung/Steuer/Kredit + Einnahmen
-- Erstellt: 17.11.2024
-- Beschreibung: Fügt Felder für Zeitraum-basierte Kosten und Einnahmen-Flag hinzu

-- Neue Spalten zu vehicle_costs hinzufügen
ALTER TABLE vehicle_costs
ADD COLUMN IF NOT EXISTS period_start_date TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS period_end_date TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS is_monthly_amount BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS is_income BOOLEAN DEFAULT FALSE;

-- Kommentare für Dokumentation
COMMENT ON COLUMN vehicle_costs.period_start_date IS 'Start-Datum für Versicherung/Steuer/Kredit-Zeiträume';
COMMENT ON COLUMN vehicle_costs.period_end_date IS 'End-Datum für Versicherung/Steuer/Kredit-Zeiträume';
COMMENT ON COLUMN vehicle_costs.is_monthly_amount IS 'True = amount ist Monatsbetrag, False = amount ist Gesamtbetrag für den Zeitraum';
COMMENT ON COLUMN vehicle_costs.is_income IS 'True = Einnahme, False = Ausgabe/Kosten';

-- Check Constraint: Wenn period_start_date gesetzt ist, muss auch period_end_date gesetzt sein
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'check_period_dates' 
    AND conrelid = 'vehicle_costs'::regclass
  ) THEN
    ALTER TABLE vehicle_costs
    ADD CONSTRAINT check_period_dates CHECK (
      (period_start_date IS NULL AND period_end_date IS NULL) OR
      (period_start_date IS NOT NULL AND period_end_date IS NOT NULL AND period_end_date >= period_start_date)
    );
  END IF;
END $$;
