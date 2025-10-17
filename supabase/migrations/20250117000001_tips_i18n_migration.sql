-- Migration: Convert tips table to i18n format
-- This script converts existing tips from single language to bilingual format

-- Step 1: Check if old columns exist and new ones don't
DO $$ 
BEGIN
  -- Only run migration if we have old format (title/body) and not new format
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema='public' AND table_name='tips' AND column_name='title'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema='public' AND table_name='tips' AND column_name='title_de'
  ) THEN
    
    -- Step 2: Add new columns
    ALTER TABLE public.tips ADD COLUMN IF NOT EXISTS title_de text;
    ALTER TABLE public.tips ADD COLUMN IF NOT EXISTS title_en text;
    ALTER TABLE public.tips ADD COLUMN IF NOT EXISTS body_de text;
    ALTER TABLE public.tips ADD COLUMN IF NOT EXISTS body_en text;
    
    -- Step 3: Copy existing data to German columns (assuming existing data is German)
    UPDATE public.tips SET 
      title_de = title,
      body_de = body;
    
    -- Step 4: Add English translations for existing tips
    -- You can customize these translations
    UPDATE public.tips SET
      title_en = CASE title
        WHEN 'Reifenluftdruck prüfen' THEN 'Check tire pressure'
        WHEN 'Ölstand im Blick behalten' THEN 'Keep an eye on oil level'
        WHEN 'Wischerblätter wechseln' THEN 'Replace wiper blades'
        WHEN 'Bremsen checken' THEN 'Check brakes'
        WHEN 'Lichter testen' THEN 'Test lights'
        WHEN 'Kühlflüssigkeit prüfen' THEN 'Check coolant'
        WHEN 'Batterie pflegen' THEN 'Maintain battery'
        WHEN 'Reifendruck nach Beladung' THEN 'Tire pressure when loaded'
        WHEN 'Klimaanlage nutzen' THEN 'Use air conditioning'
        WHEN 'Sanft beschleunigen' THEN 'Accelerate gently'
        ELSE 'Car maintenance tip'
      END,
      body_en = CASE body
        WHEN 'Prüfe monatlich den Reifenluftdruck – falscher Druck erhöht Verbrauch und Verschleiß.' 
          THEN 'Check tire pressure monthly – incorrect pressure increases fuel consumption and wear.'
        WHEN 'Kontrolliere den Ölstand alle paar Wochen, vor allem vor langen Fahrten.' 
          THEN 'Check the oil level every few weeks, especially before long trips.'
        WHEN 'Schlieren auf der Scheibe? Zeit für neue Wischerblätter – mehr Sicht, mehr Sicherheit.' 
          THEN 'Streaks on the windshield? Time for new wiper blades – better visibility, more safety.'
        WHEN 'Achte auf quietschende Geräusche oder längere Bremswege – frühzeitig Werkstatt aufsuchen.' 
          THEN 'Watch for squeaking sounds or longer braking distances – visit the workshop early.'
        WHEN 'Regelmäßig Front-, Rück- und Bremslichter testen – bessere Sicht und Sichtbarkeit.' 
          THEN 'Regularly test front, rear and brake lights – better vision and visibility.'
        WHEN 'Der Kühlflüssigkeitsstand sollte zwischen Min/Max liegen – schützt vor Überhitzung.' 
          THEN 'The coolant level should be between Min/Max – protects against overheating.'
        WHEN 'Kurze Strecken und Kälte belasten die Batterie – gelegentlich längere Fahrten einplanen.' 
          THEN 'Short distances and cold weather stress the battery – plan occasional longer trips.'
        WHEN 'Bei hoher Beladung den Reifendruck laut Hersteller erhöhen – Sicherheit + Effizienz.' 
          THEN 'Increase tire pressure according to manufacturer when heavily loaded – safety + efficiency.'
        WHEN 'Auch im Winter kurz laufen lassen – beugt Gerüchen vor und schont Dichtungen.' 
          THEN 'Run it briefly even in winter – prevents odors and protects seals.'
        WHEN 'Vorausschauend fahren spart Sprit und schont Motor und Bremsen.' 
          THEN 'Anticipatory driving saves fuel and protects engine and brakes.'
        ELSE 'Regular maintenance helps keep your car in good condition.'
      END;
    
    -- Step 5: Make new columns NOT NULL (now that they have data)
    ALTER TABLE public.tips ALTER COLUMN title_de SET NOT NULL;
    ALTER TABLE public.tips ALTER COLUMN title_en SET NOT NULL;
    ALTER TABLE public.tips ALTER COLUMN body_de SET NOT NULL;
    ALTER TABLE public.tips ALTER COLUMN body_en SET NOT NULL;
    
    -- Step 6: Drop old columns
    ALTER TABLE public.tips DROP COLUMN IF EXISTS title;
    ALTER TABLE public.tips DROP COLUMN IF EXISTS body;
    
    RAISE NOTICE 'Tips table successfully migrated to i18n format!';
  ELSE
    RAISE NOTICE 'Tips table already in i18n format or migration not needed.';
  END IF;
END $$;
