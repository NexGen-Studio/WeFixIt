-- Migration: Füge repair_guides Spalte zu automotive_knowledge hinzu
-- Datum: 2025-01-15
-- Beschreibung: Detaillierte Reparaturanleitungen pro Ursache (JSON-Struktur)

-- Füge repair_guides Spalte hinzu
ALTER TABLE automotive_knowledge 
ADD COLUMN IF NOT EXISTS repair_guides JSONB DEFAULT '{}';

-- Index für schnelleren Zugriff auf JSON-Daten
CREATE INDEX IF NOT EXISTS idx_automotive_knowledge_repair_guides 
ON automotive_knowledge USING gin(repair_guides);

-- Kommentar für Dokumentation
COMMENT ON COLUMN automotive_knowledge.repair_guides IS 'Detaillierte Schritt-für-Schritt Reparaturanleitungen pro Ursache. Struktur: { "ursache_key": { "cause_title": "...", "difficulty_level": "...", "steps": [...], "tools_required": [...], "safety_warnings": [...] } }';

-- Beispiel-Struktur für repair_guides:
-- {
--   "defekter_katalysator": {
--     "cause_title": "Defekter Katalysator",
--     "difficulty_level": "medium",
--     "estimated_time_hours": 2,
--     "estimated_cost_eur": [300, 800],
--     "for_beginners": true,
--     "steps": [
--       {
--         "step": 1,
--         "title": "Sicherheitsvorbereitung",
--         "description": "...",
--         "duration_minutes": 30,
--         "safety_warning": "...",
--         "tools": ["..."]
--       }
--     ],
--     "tools_required": ["..."],
--     "safety_warnings": ["..."],
--     "when_to_call_mechanic": ["..."]
--   }
-- }
