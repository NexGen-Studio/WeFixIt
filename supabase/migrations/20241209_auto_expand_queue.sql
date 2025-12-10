-- ============================================================================
-- Auto-Expanding Knowledge Queue
-- Füllt die Queue automatisch auf, wenn sie leer wird
-- ============================================================================

-- Funktion: Füge nächsten Batch OBD2-Codes hinzu
CREATE OR REPLACE FUNCTION auto_expand_knowledge_queue()
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  pending_count INT;
  last_obd2_code TEXT;
  next_code_num INT;
  batch_size INT := 50;
  i INT;
BEGIN
  -- 1. Prüfe wie viele Items pending sind
  SELECT COUNT(*) INTO pending_count
  FROM knowledge_harvest_queue
  WHERE status = 'pending';
  
  -- Wenn mehr als 10 pending, nichts tun
  IF pending_count > 10 THEN
    RETURN;
  END IF;
  
  RAISE NOTICE 'Queue niedrig (% pending). Fülle auf...', pending_count;
  
  -- 2. Finde letzten OBD2-Code
  SELECT topic INTO last_obd2_code
  FROM knowledge_harvest_queue
  WHERE category = 'fehlercode' 
    AND topic ~ '^[PCBU]\d{4}'
  ORDER BY topic DESC
  LIMIT 1;
  
  -- 3. Berechne nächsten Code
  IF last_obd2_code IS NULL THEN
    -- Start mit P0000
    next_code_num := 0;
  ELSE
    -- Extrahiere Nummer aus letztem Code (z.B. "P0420" -> 420)
    next_code_num := SUBSTRING(last_obd2_code FROM '\d{4}')::INT + 1;
  END IF;
  
  RAISE NOTICE 'Letzter Code: %, Nächster: P%', last_obd2_code, LPAD(next_code_num::TEXT, 4, '0');
  
  -- 4. Füge nächsten Batch P-Codes hinzu (Powertrain)
  FOR i IN 1..batch_size LOOP
    -- P-Codes: P0000-P3999
    IF next_code_num <= 3999 THEN
      INSERT INTO knowledge_harvest_queue (topic, search_language, category, priority)
      VALUES (
        'P' || LPAD(next_code_num::TEXT, 4, '0') || ' OBD2 diagnostic trouble code',
        'en',
        'fehlercode',
        100 - (next_code_num / 100) -- Höhere Priorität für niedrigere Codes
      )
      ON CONFLICT DO NOTHING;
      
      next_code_num := next_code_num + 1;
      
    -- C-Codes: C0000-C3999 (Chassis)
    ELSIF next_code_num <= 7999 THEN
      INSERT INTO knowledge_harvest_queue (topic, search_language, category, priority)
      VALUES (
        'C' || LPAD((next_code_num - 4000)::TEXT, 4, '0') || ' chassis diagnostic trouble code',
        'en',
        'fehlercode',
        50
      )
      ON CONFLICT DO NOTHING;
      
      next_code_num := next_code_num + 1;
      
    -- B-Codes: B0000-B3999 (Body)
    ELSIF next_code_num <= 11999 THEN
      INSERT INTO knowledge_harvest_queue (topic, search_language, category, priority)
      VALUES (
        'B' || LPAD((next_code_num - 8000)::TEXT, 4, '0') || ' body diagnostic trouble code',
        'en',
        'fehlercode',
        30
      )
      ON CONFLICT DO NOTHING;
      
      next_code_num := next_code_num + 1;
      
    -- U-Codes: U0000-U3999 (Network)
    ELSIF next_code_num <= 15999 THEN
      INSERT INTO knowledge_harvest_queue (topic, search_language, category, priority)
      VALUES (
        'U' || LPAD((next_code_num - 12000)::TEXT, 4, '0') || ' network diagnostic trouble code',
        'en',
        'fehlercode',
        20
      )
      ON CONFLICT DO NOTHING;
      
      next_code_num := next_code_num + 1;
      
    -- Alle OBD2-Codes fertig -> Reparaturanleitungen
    ELSE
      EXIT; -- Stop loop
    END IF;
  END LOOP;
  
  -- 5. Wenn alle OBD2-Codes fertig: Füge Reparaturthemen hinzu
  IF next_code_num > 15999 THEN
    RAISE NOTICE 'OBD2-Codes komplett. Füge Reparaturthemen hinzu...';
    
    INSERT INTO knowledge_harvest_queue (topic, search_language, category, priority) VALUES
      -- Häufige Reparaturen (EN)
      ('How to change engine oil step by step', 'en', 'reparatur', 80),
      ('Brake pad replacement guide with photos', 'en', 'reparatur', 80),
      ('Air filter replacement tutorial', 'en', 'reparatur', 75),
      ('Spark plug replacement guide', 'en', 'reparatur', 75),
      ('Battery replacement and testing', 'en', 'reparatur', 75),
      ('Alternator diagnosis and replacement', 'en', 'reparatur', 70),
      ('Starter motor troubleshooting guide', 'en', 'reparatur', 70),
      ('Coolant flush and replacement', 'en', 'reparatur', 70),
      ('Transmission fluid change guide', 'en', 'reparatur', 65),
      ('Timing belt replacement intervals and procedure', 'en', 'reparatur', 65),
      
      -- Deutsche Reparaturen
      ('Ölwechsel selber machen Anleitung', 'de', 'reparatur', 80),
      ('Bremsbeläge wechseln Schritt für Schritt', 'de', 'reparatur', 80),
      ('Luftfilter tauschen Anleitung', 'de', 'reparatur', 75),
      ('Zündkerzen wechseln Tutorial', 'de', 'reparatur', 75),
      ('Autobatterie wechseln und testen', 'de', 'reparatur', 75),
      
      -- Diagnose-Themen
      ('Engine misfire diagnosis checklist', 'en', 'diagnose', 85),
      ('Rough idle troubleshooting steps', 'en', 'diagnose', 85),
      ('Check engine light common causes', 'en', 'diagnose', 85),
      ('Car won''t start diagnosis flowchart', 'en', 'diagnose', 80),
      ('Overheating engine diagnosis guide', 'en', 'diagnose', 80)
    ON CONFLICT DO NOTHING;
  END IF;
  
  RAISE NOTICE 'Queue aufgefüllt. Neue Items hinzugefügt.';
END;
$$;

-- Trigger: Rufe auto_expand_knowledge_queue auf, wenn Queue-Item completed wird
CREATE OR REPLACE FUNCTION trigger_expand_queue()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- Nur ausführen wenn Status auf 'completed' gesetzt wird
  IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
    PERFORM auto_expand_knowledge_queue();
  END IF;
  
  RETURN NEW;
END;
$$;

-- Erstelle Trigger
DROP TRIGGER IF EXISTS expand_queue_on_complete ON knowledge_harvest_queue;
CREATE TRIGGER expand_queue_on_complete
  AFTER UPDATE ON knowledge_harvest_queue
  FOR EACH ROW
  EXECUTE FUNCTION trigger_expand_queue();

-- Kommentar
COMMENT ON FUNCTION auto_expand_knowledge_queue IS 
  'Füllt die knowledge_harvest_queue automatisch auf, wenn < 10 Items pending sind. 
   Geht systematisch durch P/C/B/U-Codes, dann Reparaturthemen.';
