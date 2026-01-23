-- Migration: Füge symptoms_en und causes_en Spalten hinzu
-- Datum: 2025-01-22
-- Grund: Symptoms und Causes sollen auch auf Englisch verfügbar sein

-- 1. Füge neue Spalten hinzu
ALTER TABLE automotive_knowledge
ADD COLUMN IF NOT EXISTS symptoms_en TEXT[] DEFAULT NULL,
ADD COLUMN IF NOT EXISTS causes_en TEXT[] DEFAULT NULL;

-- 2. Index für schnelleren Zugriff
CREATE INDEX IF NOT EXISTS idx_automotive_knowledge_symptoms_en 
ON automotive_knowledge USING gin(symptoms_en);

CREATE INDEX IF NOT EXISTS idx_automotive_knowledge_causes_en 
ON automotive_knowledge USING gin(causes_en);

-- 3. Kommentar für Dokumentation
COMMENT ON COLUMN automotive_knowledge.symptoms_en IS 'English symptoms (array of strings)';
COMMENT ON COLUMN automotive_knowledge.causes_en IS 'English causes (array of strings)';
