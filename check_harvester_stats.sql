-- ============================================================================
-- Harvester Statistiken prüfen
-- Führe das in der Supabase SQL Console aus
-- ============================================================================

-- 1. Wie viele Artikel sind vorhanden?
SELECT 
  COUNT(*) as total_articles,
  COUNT(*) FILTER (WHERE content_de IS NOT NULL) as deutsch,
  COUNT(*) FILTER (WHERE content_en IS NOT NULL) as englisch,
  COUNT(*) FILTER (WHERE content_fr IS NOT NULL) as französisch,
  COUNT(*) FILTER (WHERE content_es IS NOT NULL) as spanisch
FROM automotive_knowledge;

-- 2. Queue Status
SELECT 
  status,
  COUNT(*) as count
FROM knowledge_harvest_queue
GROUP BY status
ORDER BY count DESC;

-- 3. Kategorien-Verteilung
SELECT 
  category,
  COUNT(*) as count
FROM automotive_knowledge
GROUP BY category
ORDER BY count DESC;

-- 4. Neueste Artikel
SELECT 
  topic,
  category,
  created_at
FROM automotive_knowledge
ORDER BY created_at DESC
LIMIT 10;

-- ============================================================================
-- ENTSCHEIDUNGSHILFE:
-- 
-- Wenn du > 20 erfolgreiche Artikel hast:
--   → NICHT löschen, sondern Queue nachfüllen
--
-- Wenn du < 10 Artikel hast:
--   → Kannst löschen und neu starten
--
-- Bei Fehlerrate > 50%:
--   → Prüfe OpenAI/Perplexity API Keys
-- ============================================================================
