-- ============================================================================
-- Reset Knowledge Base & Seed OBD2 Queue
-- Löscht alle fehlerhaften Einträge und befüllt Queue mit OBD2-Codes
-- ============================================================================

-- 1. Lösche alle automotive_knowledge Einträge mit NULL-Titeln
DELETE FROM automotive_knowledge 
WHERE title_de IS NULL OR title_en IS NULL;

-- 2. Setze Queue zurück (alle auf "pending")
UPDATE knowledge_harvest_queue
SET status = 'pending', 
    attempts = 0,
    error_message = NULL,
    last_attempt_at = NULL;

-- 3. Lösche alle bisherigen Queue-Einträge
DELETE FROM knowledge_harvest_queue;

-- 4. Füge die 50 häufigsten OBD2-Fehlercodes hinzu
INSERT INTO knowledge_harvest_queue (topic, search_language, category, priority) VALUES
  -- Powertrain (P-Codes) - Priorität 100-90
  ('P0420 Catalyst System Efficiency Below Threshold Bank 1', 'en', 'fehlercode', 100),
  ('P0171 System Too Lean Bank 1', 'en', 'fehlercode', 99),
  ('P0300 Random/Multiple Cylinder Misfire Detected', 'en', 'fehlercode', 98),
  ('P0174 System Too Lean Bank 2', 'en', 'fehlercode', 97),
  ('P0301 Cylinder 1 Misfire Detected', 'en', 'fehlercode', 96),
  ('P0401 Exhaust Gas Recirculation Flow Insufficient', 'en', 'fehlercode', 95),
  ('P0442 Evaporative Emission Control System Leak Detected Small Leak', 'en', 'fehlercode', 94),
  ('P0455 Evaporative Emission Control System Leak Detected Large Leak', 'en', 'fehlercode', 93),
  ('P0128 Coolant Thermostat Temperature Below Regulating Temperature', 'en', 'fehlercode', 92),
  ('P0456 Evaporative Emissions System Small Leak Detected', 'en', 'fehlercode', 91),
  
  -- Häufige Motor-Codes
  ('P0302 Cylinder 2 Misfire Detected', 'en', 'fehlercode', 90),
  ('P0303 Cylinder 3 Misfire Detected', 'en', 'fehlercode', 89),
  ('P0304 Cylinder 4 Misfire Detected', 'en', 'fehlercode', 88),
  ('P0172 System Too Rich Bank 1', 'en', 'fehlercode', 87),
  ('P0175 System Too Rich Bank 2', 'en', 'fehlercode', 86),
  ('P0135 O2 Sensor Heater Circuit Malfunction Bank 1 Sensor 1', 'en', 'fehlercode', 85),
  ('P0141 O2 Sensor Heater Circuit Malfunction Bank 1 Sensor 2', 'en', 'fehlercode', 84),
  ('P0430 Catalyst System Efficiency Below Threshold Bank 2', 'en', 'fehlercode', 83),
  ('P0440 Evaporative Emission Control System Malfunction', 'en', 'fehlercode', 82),
  ('P0446 Evaporative Emission Control System Vent Control Circuit Malfunction', 'en', 'fehlercode', 81),
  
  -- Sensor-Codes
  ('P0100 Mass or Volume Air Flow Circuit Malfunction', 'en', 'fehlercode', 80),
  ('P0110 Intake Air Temperature Circuit Malfunction', 'en', 'fehlercode', 79),
  ('P0115 Engine Coolant Temperature Circuit Malfunction', 'en', 'fehlercode', 78),
  ('P0120 Throttle Position Sensor Circuit Malfunction', 'en', 'fehlercode', 77),
  ('P0125 Insufficient Coolant Temperature for Closed Loop Fuel Control', 'en', 'fehlercode', 76),
  ('P0130 O2 Sensor Circuit Malfunction Bank 1 Sensor 1', 'en', 'fehlercode', 75),
  ('P0131 O2 Sensor Circuit Low Voltage Bank 1 Sensor 1', 'en', 'fehlercode', 74),
  ('P0132 O2 Sensor Circuit High Voltage Bank 1 Sensor 1', 'en', 'fehlercode', 73),
  ('P0133 O2 Sensor Circuit Slow Response Bank 1 Sensor 1', 'en', 'fehlercode', 72),
  ('P0134 O2 Sensor Circuit No Activity Detected Bank 1 Sensor 1', 'en', 'fehlercode', 71),
  
  -- Zündung & Einspritzung
  ('P0200 Injector Circuit Malfunction', 'en', 'fehlercode', 70),
  ('P0201 Injector Circuit Malfunction Cylinder 1', 'en', 'fehlercode', 69),
  ('P0325 Knock Sensor 1 Circuit Malfunction', 'en', 'fehlercode', 68),
  ('P0340 Camshaft Position Sensor Circuit Malfunction', 'en', 'fehlercode', 67),
  ('P0350 Ignition Coil Primary Secondary Circuit Malfunction', 'en', 'fehlercode', 66),
  ('P0351 Ignition Coil A Primary Secondary Circuit Malfunction', 'en', 'fehlercode', 65),
  
  -- Getriebe (Transmission)
  ('P0700 Transmission Control System Malfunction', 'en', 'fehlercode', 64),
  ('P0715 Input Turbine Speed Sensor Circuit Malfunction', 'en', 'fehlercode', 63),
  ('P0720 Output Speed Sensor Circuit Malfunction', 'en', 'fehlercode', 62),
  ('P0740 Torque Converter Clutch Circuit Malfunction', 'en', 'fehlercode', 61),
  ('P0750 Shift Solenoid A Malfunction', 'en', 'fehlercode', 60),
  
  -- Turbo & Luftsystem
  ('P0236 Turbo Boost Sensor A Circuit Range Performance', 'en', 'fehlercode', 59),
  ('P0243 Turbocharger Wastegate Solenoid A Malfunction', 'en', 'fehlercode', 58),
  ('P2015 Intake Manifold Runner Position Sensor Circuit Range Bank 1', 'en', 'fehlercode', 57),
  ('P2270 O2 Sensor Signal Stuck Lean Bank 1 Sensor 2', 'en', 'fehlercode', 56),
  ('P2279 Intake Air System Leak', 'en', 'fehlercode', 55),
  
  -- Deutsche Reparatur-Guides (hohe Priorität)
  ('VW Golf 7 TDI DPF regenerieren Anleitung', 'de', 'reparatur', 85),
  ('BMW E90 Turbolader defekt Symptome und Diagnose', 'de', 'diagnose', 84),
  ('Audi A4 B8 Ölverlust Ursachen finden', 'de', 'diagnose', 83),
  ('Mercedes W204 Luftmassenmesser reinigen', 'de', 'reparatur', 82)
ON CONFLICT DO NOTHING;

-- 5. Zeige Zusammenfassung
SELECT 
  'Queue Reset Complete' as status,
  COUNT(*) as total_queue_items,
  COUNT(CASE WHEN category = 'fehlercode' THEN 1 END) as obd2_codes,
  COUNT(CASE WHEN category IN ('reparatur', 'diagnose') THEN 1 END) as repair_guides
FROM knowledge_harvest_queue;

SELECT 
  'Database Cleaned' as status,
  COUNT(*) as remaining_articles
FROM automotive_knowledge;
