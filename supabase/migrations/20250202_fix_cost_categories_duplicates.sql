-- Migration: Fix Cost Categories Duplicate Bug
-- Erstellt: 02.12.2024
-- Beschreibung: Verhindert Duplikat-Kategorien durch UNIQUE Constraint

-- ============================================================================
-- 1. CHECK CONSTRAINT ANPASSEN & UNIQUE CONSTRAINT HINZUFÜGEN
-- ============================================================================
-- Problem: Alter Check Constraint verlangt user_id = NULL für System-Kategorien
-- Aber wir brauchen UNIQUE (user_id, name) für User-Kategorien
-- Lösung: Check Constraint entfernen, separates UNIQUE für User-Kategorien

DO $$ 
BEGIN
  -- Alten Check Constraint entfernen
  IF EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'check_user_or_system'
  ) THEN
    ALTER TABLE cost_categories DROP CONSTRAINT check_user_or_system;
    RAISE NOTICE 'Alter Check Constraint entfernt';
  END IF;
  
  -- UNIQUE Constraint für User-Kategorien (nur non-system)
  -- Partial UNIQUE: Nur für is_system = FALSE
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes 
    WHERE indexname = 'cost_categories_user_name_unique'
  ) THEN
    -- Für User-Kategorien: user_id + name muss unique sein
    CREATE UNIQUE INDEX cost_categories_user_name_unique 
    ON cost_categories(user_id, name) 
    WHERE is_system = FALSE;
    
    RAISE NOTICE 'UNIQUE Index für User-Kategorien erfolgreich hinzugefügt';
  ELSE
    RAISE NOTICE 'UNIQUE Index für User-Kategorien existiert bereits';
  END IF;
  
  -- UNIQUE für System-Kategorien: nur name
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes 
    WHERE indexname = 'cost_categories_system_name_unique'
  ) THEN
    CREATE UNIQUE INDEX cost_categories_system_name_unique 
    ON cost_categories(name) 
    WHERE is_system = TRUE;
    
    RAISE NOTICE 'UNIQUE Index für System-Kategorien erfolgreich hinzugefügt';
  ELSE
    RAISE NOTICE 'UNIQUE Index existiert bereits';
  END IF;
END $$;

-- ============================================================================
-- 2. is_locked SPALTE HINZUFÜGEN (falls nicht vorhanden)
-- ============================================================================
-- Für Feature-Gate: Kategorien für Free User sperren

DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'cost_categories' 
    AND column_name = 'is_locked'
  ) THEN
    ALTER TABLE cost_categories 
    ADD COLUMN is_locked BOOLEAN NOT NULL DEFAULT false;
    
    RAISE NOTICE 'is_locked Spalte erfolgreich hinzugefügt';
  ELSE
    RAISE NOTICE 'is_locked Spalte existiert bereits';
  END IF;
END $$;

-- ============================================================================
-- 3. STANDARD-KATEGORIEN EINFÜGEN
-- ============================================================================
-- System-Kategorien mit Icons und Farben
-- ON CONFLICT DO NOTHING verhindert Duplikate

-- Treibstoff (Free User Zugriff)
INSERT INTO cost_categories (user_id, name, icon_name, color_hex, is_system, is_locked, sort_order)
SELECT NULL, 'Treibstoff', 'local_gas_station', '0xFFFFB129', true, false, 1
WHERE NOT EXISTS (
  SELECT 1 FROM cost_categories WHERE name = 'Treibstoff' AND is_system = true
);

-- Wartung & Reparatur (Premium)
INSERT INTO cost_categories (user_id, name, icon_name, color_hex, is_system, is_locked, sort_order)
SELECT NULL, 'Wartung & Reparatur', 'build', '0xFFFF5252', true, true, 2
WHERE NOT EXISTS (
  SELECT 1 FROM cost_categories WHERE name = 'Wartung & Reparatur' AND is_system = true
);

-- Versicherung (Premium)
INSERT INTO cost_categories (user_id, name, icon_name, color_hex, is_system, is_locked, sort_order)
SELECT NULL, 'Versicherung', 'security', '0xFF2196F3', true, true, 3
WHERE NOT EXISTS (
  SELECT 1 FROM cost_categories WHERE name = 'Versicherung' AND is_system = true
);

-- Steuer (Premium)
INSERT INTO cost_categories (user_id, name, icon_name, color_hex, is_system, is_locked, sort_order)
SELECT NULL, 'Steuer', 'account_balance', '0xFF4CAF50', true, true, 4
WHERE NOT EXISTS (
  SELECT 1 FROM cost_categories WHERE name = 'Steuer' AND is_system = true
);

-- Parkgebühren (Premium)
INSERT INTO cost_categories (user_id, name, icon_name, color_hex, is_system, is_locked, sort_order)
SELECT NULL, 'Parkgebühren', 'local_parking', '0xFF9C27B0', true, true, 5
WHERE NOT EXISTS (
  SELECT 1 FROM cost_categories WHERE name = 'Parkgebühren' AND is_system = true
);

-- Autowäsche (Premium)
INSERT INTO cost_categories (user_id, name, icon_name, color_hex, is_system, is_locked, sort_order)
SELECT NULL, 'Autowäsche', 'local_car_wash', '0xFF00BCD4', true, true, 6
WHERE NOT EXISTS (
  SELECT 1 FROM cost_categories WHERE name = 'Autowäsche' AND is_system = true
);

-- Maut & Vignette (Premium)
INSERT INTO cost_categories (user_id, name, icon_name, color_hex, is_system, is_locked, sort_order)
SELECT NULL, 'Maut & Vignette', 'toll', '0xFFFF9800', true, true, 7
WHERE NOT EXISTS (
  SELECT 1 FROM cost_categories WHERE name = 'Maut & Vignette' AND is_system = true
);

-- Reifen (Premium)
INSERT INTO cost_categories (user_id, name, icon_name, color_hex, is_system, is_locked, sort_order)
SELECT NULL, 'Reifen', 'tire_repair', '0xFF607D8B', true, true, 8
WHERE NOT EXISTS (
  SELECT 1 FROM cost_categories WHERE name = 'Reifen' AND is_system = true
);

-- Zubehör (Premium)
INSERT INTO cost_categories (user_id, name, icon_name, color_hex, is_system, is_locked, sort_order)
SELECT NULL, 'Zubehör', 'shopping_cart', '0xFFE91E63', true, true, 9
WHERE NOT EXISTS (
  SELECT 1 FROM cost_categories WHERE name = 'Zubehör' AND is_system = true
);

-- Sonstiges (Premium)
INSERT INTO cost_categories (user_id, name, icon_name, color_hex, is_system, is_locked, sort_order)
SELECT NULL, 'Sonstiges', 'more_horiz', '0xFF9E9E9E', true, true, 10
WHERE NOT EXISTS (
  SELECT 1 FROM cost_categories WHERE name = 'Sonstiges' AND is_system = true
);

-- ============================================================================
-- 4. RLS POLICIES FIXEN (System-Kategorien haben user_id = NULL!)
-- ============================================================================
-- Problem: Policy prüft auth.uid() = user_id, aber NULL = NULL ist FALSE

DROP POLICY IF EXISTS "Everyone can view system categories" ON cost_categories;

CREATE POLICY "Everyone can view system categories"
  ON cost_categories FOR SELECT
  USING (
    is_system = TRUE 
    OR (user_id IS NOT NULL AND auth.uid() = user_id)
  );

-- ============================================================================
-- 5. TEMPORÄR ALLE KATEGORIEN FREIGEBEN (FÜR TESTING)
-- ============================================================================
-- User möchte alle Kategorien ohne Lock testen können

UPDATE cost_categories 
SET is_locked = false 
WHERE is_system = true;

-- ============================================================================
-- 6. VERIFIZIERUNG
-- ============================================================================

-- Ausgabe der erstellten Kategorien
DO $$ 
DECLARE
  category_count INTEGER;
  unlocked_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO category_count FROM cost_categories WHERE is_system = true;
  SELECT COUNT(*) INTO unlocked_count FROM cost_categories WHERE is_system = true AND is_locked = false;
  RAISE NOTICE 'Migration abgeschlossen! % System-Kategorien vorhanden, % davon freigeschaltet.', category_count, unlocked_count;
END $$;
