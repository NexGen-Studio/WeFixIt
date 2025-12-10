-- ============================================================================
-- Migration: Automotive Knowledge System mit Multi-Language Support
-- Datum: 2024-12-09
-- Zweck: KI-Wissensdatenbank für KFZ-Reparaturen, OBD2-Codes, Diagnosen
-- ============================================================================

-- ============================================================================
-- 1. pgvector Extension aktivieren (für Vector Embeddings)
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS vector;

-- ============================================================================
-- 2. Automotive Knowledge Tabelle (Multi-Language Support)
-- ============================================================================

CREATE TABLE IF NOT EXISTS automotive_knowledge (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Metadaten
  topic TEXT NOT NULL,
  category TEXT NOT NULL, -- 'fehlercode', 'bauteil', 'reparatur', 'theorie', 'tuning', 'elektro'
  subcategory TEXT, -- 'motor', 'getriebe', 'bremsen', 'elektrik', etc.
  vehicle_specific JSONB, -- {brand: 'VW', model: 'Golf 7', year: '2012-2020'}
  
  -- Multi-Language Content (alle Sprachen in einem Eintrag!)
  title_de TEXT,
  title_en TEXT,
  title_fr TEXT,
  title_es TEXT,
  
  content_de TEXT,
  content_en TEXT,
  content_fr TEXT,
  content_es TEXT,
  
  -- Strukturierte Daten (sprachunabhängig)
  symptoms TEXT[], -- ['Leistungsverlust', 'Ruckeln', 'Schwarzer Rauch']
  causes TEXT[], -- ['Defekter Turbolader', 'Verstopfter DPF']
  diagnostic_steps TEXT[], -- ['Prüfe Luftmassenmesser', 'Teste Ladedruck']
  repair_steps TEXT[], -- ['Turbolader ausbauen', 'Dichtungen prüfen']
  tools_required TEXT[], -- ['Drehmomentschlüssel', 'OBD2-Adapter']
  estimated_cost_eur NUMERIC(10,2), -- Durchschnittliche Kosten
  difficulty_level TEXT CHECK (difficulty_level IN ('easy', 'medium', 'hard', 'expert')),
  
  -- Vector Embeddings (ein Embedding pro Sprache!)
  embedding_de vector(1536),
  embedding_en vector(1536),
  embedding_fr vector(1536),
  embedding_es vector(1536),
  
  -- Metadaten & Qualität
  keywords TEXT[],
  original_language TEXT, -- 'en', 'de', 'fr', etc. (für Qualitätskontrolle)
  source_urls TEXT[], -- Für Nachvollziehbarkeit
  quality_score NUMERIC(3,2) CHECK (quality_score >= 0 AND quality_score <= 1), -- 0.0 - 1.0
  view_count INTEGER DEFAULT 0,
  helpful_count INTEGER DEFAULT 0,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indizes für Text-Suche
CREATE INDEX IF NOT EXISTS idx_knowledge_category ON automotive_knowledge(category);
CREATE INDEX IF NOT EXISTS idx_knowledge_subcategory ON automotive_knowledge(subcategory);
CREATE INDEX IF NOT EXISTS idx_knowledge_vehicle ON automotive_knowledge USING gin(vehicle_specific);
CREATE INDEX IF NOT EXISTS idx_knowledge_keywords ON automotive_knowledge USING gin(keywords);
CREATE INDEX IF NOT EXISTS idx_knowledge_created_at ON automotive_knowledge(created_at DESC);

-- Indizes für Vector Search (pro Sprache!)
CREATE INDEX IF NOT EXISTS idx_knowledge_embedding_de ON automotive_knowledge 
  USING ivfflat (embedding_de vector_cosine_ops) WITH (lists = 100);

CREATE INDEX IF NOT EXISTS idx_knowledge_embedding_en ON automotive_knowledge 
  USING ivfflat (embedding_en vector_cosine_ops) WITH (lists = 100);

CREATE INDEX IF NOT EXISTS idx_knowledge_embedding_fr ON automotive_knowledge 
  USING ivfflat (embedding_fr vector_cosine_ops) WITH (lists = 100);

CREATE INDEX IF NOT EXISTS idx_knowledge_embedding_es ON automotive_knowledge 
  USING ivfflat (embedding_es vector_cosine_ops) WITH (lists = 100);

-- RLS aktivieren
ALTER TABLE automotive_knowledge ENABLE ROW LEVEL SECURITY;

-- Public Read (alle können lesen)
CREATE POLICY "automotive_knowledge_read_all" ON automotive_knowledge
  FOR SELECT USING (true);

-- Admin Write (nur Service-Rolle kann schreiben)
CREATE POLICY "automotive_knowledge_write_service" ON automotive_knowledge
  FOR ALL USING (auth.role() = 'service_role');

-- ============================================================================
-- 3. Error Codes Tabelle (OBD2, Hersteller-spezifisch)
-- ============================================================================

CREATE TABLE IF NOT EXISTS error_codes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Code-Identifikation
  code TEXT UNIQUE NOT NULL, -- P0420, P0171, C1234, B0001, U0100
  code_type TEXT CHECK (code_type IN ('powertrain', 'chassis', 'body', 'network')),
  is_generic BOOLEAN DEFAULT true, -- true = SAE Standard, false = Hersteller-spezifisch
  manufacturer TEXT[], -- ['VW', 'Audi', 'Seat', 'Skoda'] wenn hersteller-spezifisch
  
  -- Multi-Language Beschreibungen
  description_de TEXT,
  description_en TEXT,
  description_fr TEXT,
  description_es TEXT,
  
  -- Technische Details
  symptoms TEXT[],
  common_causes TEXT[],
  diagnostic_steps TEXT[],
  repair_suggestions TEXT[],
  affected_components TEXT[], -- ['Catalytic Converter', 'O2 Sensor', 'ECU']
  
  -- Schweregrad & Priorität
  severity TEXT CHECK (severity IN ('low', 'medium', 'high', 'critical')),
  drive_safety BOOLEAN DEFAULT true, -- Kann man weiterfahren?
  immediate_action_required BOOLEAN DEFAULT false,
  
  -- Zusatz-Infos
  related_codes TEXT[], -- ['P0171', 'P0174'] (oft zusammen auftretend)
  typical_cost_range_eur TEXT, -- '50-200' oder '500-1500'
  
  -- Statistik
  occurrence_frequency TEXT CHECK (occurrence_frequency IN ('very_common', 'common', 'uncommon', 'rare')),
  search_count INTEGER DEFAULT 0,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index für schnelle Code-Suche
CREATE INDEX IF NOT EXISTS idx_error_codes_code ON error_codes(code);
CREATE INDEX IF NOT EXISTS idx_error_codes_type ON error_codes(code_type);
CREATE INDEX IF NOT EXISTS idx_error_codes_severity ON error_codes(severity);
CREATE INDEX IF NOT EXISTS idx_error_codes_manufacturer ON error_codes USING gin(manufacturer);

-- RLS aktivieren
ALTER TABLE error_codes ENABLE ROW LEVEL SECURITY;

-- Public Read
CREATE POLICY "error_codes_read_all" ON error_codes
  FOR SELECT USING (true);

-- Admin Write
CREATE POLICY "error_codes_write_service" ON error_codes
  FOR ALL USING (auth.role() = 'service_role');

-- ============================================================================
-- 4. Knowledge Harvest Queue (für automatisches Crawling)
-- ============================================================================

CREATE TABLE IF NOT EXISTS knowledge_harvest_queue (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  
  topic TEXT NOT NULL,
  search_language TEXT NOT NULL, -- 'de', 'en', 'fr', 'es', 'it', 'pl', 'tr', etc.
  category TEXT,
  priority INTEGER DEFAULT 0, -- höher = wichtiger
  
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
  attempts INTEGER DEFAULT 0,
  last_attempt_at TIMESTAMPTZ,
  error_message TEXT,
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index für Warteschlangen-Verarbeitung
CREATE INDEX IF NOT EXISTS idx_harvest_queue_status ON knowledge_harvest_queue(status, priority DESC);
CREATE INDEX IF NOT EXISTS idx_harvest_queue_created_at ON knowledge_harvest_queue(created_at);

-- RLS aktivieren
ALTER TABLE knowledge_harvest_queue ENABLE ROW LEVEL SECURITY;

-- Nur Service-Rolle kann auf Queue zugreifen
CREATE POLICY "harvest_queue_service_only" ON knowledge_harvest_queue
  FOR ALL USING (auth.role() = 'service_role');

-- ============================================================================
-- 5. Helper Functions für Vector Search
-- ============================================================================

-- Funktion: Match Documents (Deutsch)
CREATE OR REPLACE FUNCTION match_documents_de(
  query_embedding vector(1536),
  match_threshold float DEFAULT 0.78,
  match_count int DEFAULT 5
)
RETURNS TABLE (
  id uuid,
  topic text,
  category text,
  title text,
  content text,
  similarity float
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    automotive_knowledge.id,
    automotive_knowledge.topic,
    automotive_knowledge.category,
    automotive_knowledge.title_de as title,
    automotive_knowledge.content_de as content,
    1 - (automotive_knowledge.embedding_de <=> query_embedding) as similarity
  FROM automotive_knowledge
  WHERE automotive_knowledge.embedding_de IS NOT NULL
    AND 1 - (automotive_knowledge.embedding_de <=> query_embedding) > match_threshold
  ORDER BY automotive_knowledge.embedding_de <=> query_embedding
  LIMIT match_count;
END;
$$;

-- Funktion: Match Documents (Englisch)
CREATE OR REPLACE FUNCTION match_documents_en(
  query_embedding vector(1536),
  match_threshold float DEFAULT 0.78,
  match_count int DEFAULT 5
)
RETURNS TABLE (
  id uuid,
  topic text,
  category text,
  title text,
  content text,
  similarity float
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    automotive_knowledge.id,
    automotive_knowledge.topic,
    automotive_knowledge.category,
    automotive_knowledge.title_en as title,
    automotive_knowledge.content_en as content,
    1 - (automotive_knowledge.embedding_en <=> query_embedding) as similarity
  FROM automotive_knowledge
  WHERE automotive_knowledge.embedding_en IS NOT NULL
    AND 1 - (automotive_knowledge.embedding_en <=> query_embedding) > match_threshold
  ORDER BY automotive_knowledge.embedding_en <=> query_embedding
  LIMIT match_count;
END;
$$;

-- ============================================================================
-- 6. Trigger für updated_at
-- ============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_automotive_knowledge_updated_at
  BEFORE UPDATE ON automotive_knowledge
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_error_codes_updated_at
  BEFORE UPDATE ON error_codes
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 7. Initial Data: Prioritäts-Themen für Harvesting
-- ============================================================================

INSERT INTO knowledge_harvest_queue (topic, search_language, category, priority)
VALUES
  -- OBD2-Fehlercodes (Priorität: Hoch)
  ('P0420 catalyst efficiency below threshold', 'en', 'fehlercode', 100),
  ('P0171 system too lean bank 1', 'en', 'fehlercode', 100),
  ('P0300 random misfire detected', 'en', 'fehlercode', 100),
  ('P0401 EGR flow insufficient', 'en', 'fehlercode', 90),
  ('P0174 system too lean bank 2', 'en', 'fehlercode', 90),
  
  -- Deutsche Diagnose-Themen
  ('BMW E90 Turbolader defekt Symptome', 'de', 'diagnose', 80),
  ('VW Golf 7 TDI DPF regenerieren Anleitung', 'de', 'reparatur', 80),
  ('Audi A4 B8 Ölverlust Ursachen', 'de', 'diagnose', 70),
  
  -- Reparaturanleitungen
  ('How to replace turbocharger step by step', 'en', 'reparatur', 75),
  ('Brake pad replacement guide', 'en', 'reparatur', 75),
  ('Oil change procedure', 'en', 'reparatur', 70)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 8. Kommentare für Dokumentation
-- ============================================================================

COMMENT ON TABLE automotive_knowledge IS 
  'KI-Wissensdatenbank für KFZ-Reparaturen mit Multi-Language Support. 
   Enthält Reparaturanleitungen, Diagnosetexte, Bauteile-Infos, etc.';

COMMENT ON TABLE error_codes IS 
  'OBD2-Fehlercodes und herstellerspezifische Codes mit Multi-Language Beschreibungen.';

COMMENT ON TABLE knowledge_harvest_queue IS 
  'Warteschlange für automatisches Web-Harvesting durch KI-Worker.';

COMMENT ON FUNCTION match_documents_de IS 
  'Vector Similarity Search für deutsche Inhalte. Nutzt cosine similarity.';

COMMENT ON FUNCTION match_documents_en IS 
  'Vector Similarity Search für englische Inhalte. Nutzt cosine similarity.';
