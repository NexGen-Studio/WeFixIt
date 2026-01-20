-- Migration: Splitte repair_guides in 4 separate Spalten (eine pro Sprache)
-- Datum: 2025-01-15
-- Grund: JSON zu groß bei 4 Sprachen → WORKER_LIMIT Timeout
-- Lösung: Separate Spalten = schnellere Generierung (nur DE zuerst)

-- 1. Füge neue Spalten hinzu
ALTER TABLE automotive_knowledge
ADD COLUMN IF NOT EXISTS repair_guides_de JSONB DEFAULT NULL,
ADD COLUMN IF NOT EXISTS repair_guides_en JSONB DEFAULT NULL,
ADD COLUMN IF NOT EXISTS repair_guides_fr JSONB DEFAULT NULL,
ADD COLUMN IF NOT EXISTS repair_guides_es JSONB DEFAULT NULL;

-- 2. Migiere bestehende Daten (falls repair_guides gefüllt ist)
-- Die alte repair_guides Spalte bleibt erstmal bestehen für Backup

-- 3. Kommentar für zukünftige Nutzung
COMMENT ON COLUMN automotive_knowledge.repair_guides_de IS 'Deutsche Reparaturanleitungen (JSONB)';
COMMENT ON COLUMN automotive_knowledge.repair_guides_en IS 'English repair guides (JSONB)';
COMMENT ON COLUMN automotive_knowledge.repair_guides_fr IS 'Guides de réparation français (JSONB)';
COMMENT ON COLUMN automotive_knowledge.repair_guides_es IS 'Guías de reparación español (JSONB)';

-- Hinweis: Die alte 'repair_guides' Spalte wird NICHT gelöscht, falls wir zurückrollen müssen
