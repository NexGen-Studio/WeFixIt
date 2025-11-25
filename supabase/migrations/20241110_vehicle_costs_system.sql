-- Migration: KFZ-Kosten Tracker System
-- Erstellt: 10.11.2024
-- Beschreibung: Tabellen für Fahrzeugkosten-Tracking mit Custom-Kategorien

-- ============================================================================
-- 1. COST CATEGORIES TABELLE
-- ============================================================================
-- Speichert Standard-Kategorien (system) und benutzerdefinierte Kategorien

CREATE TABLE IF NOT EXISTS cost_categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Kategorie-Details
  name TEXT NOT NULL,
  icon_name TEXT NOT NULL, -- Material Icon Name (z.B. 'local_gas_station')
  color_hex TEXT NOT NULL, -- Hex-Farbe (z.B. '#FF5722')
  is_system BOOLEAN DEFAULT FALSE, -- true = Standard-Kategorie
  sort_order INTEGER DEFAULT 0, -- Für Sortierung
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT check_user_or_system CHECK (
    (is_system = TRUE AND user_id IS NULL) OR
    (is_system = FALSE AND user_id IS NOT NULL)
  )
);

-- Index für Performance
CREATE INDEX IF NOT EXISTS idx_cost_categories_user_id ON cost_categories(user_id);
CREATE INDEX IF NOT EXISTS idx_cost_categories_is_system ON cost_categories(is_system);

-- RLS aktivieren
ALTER TABLE cost_categories ENABLE ROW LEVEL SECURITY;

-- Policies: System-Kategorien sind für alle sichtbar
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'cost_categories' AND policyname = 'Everyone can view system categories') THEN
    CREATE POLICY "Everyone can view system categories"
      ON cost_categories FOR SELECT
      USING (is_system = TRUE OR auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'cost_categories' AND policyname = 'Users can create own categories') THEN
    CREATE POLICY "Users can create own categories"
      ON cost_categories FOR INSERT
      WITH CHECK (auth.uid() = user_id AND is_system = FALSE);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'cost_categories' AND policyname = 'Users can update own categories') THEN
    CREATE POLICY "Users can update own categories"
      ON cost_categories FOR UPDATE
      USING (auth.uid() = user_id AND is_system = FALSE);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'cost_categories' AND policyname = 'Users can delete own categories') THEN
    CREATE POLICY "Users can delete own categories"
      ON cost_categories FOR DELETE
      USING (auth.uid() = user_id AND is_system = FALSE);
  END IF;
END $$;

-- ============================================================================
-- 2. VEHICLE COSTS TABELLE
-- ============================================================================
-- Speichert alle Kosteneinträge mit erweiterten Feldern für Treibstoff

CREATE TABLE IF NOT EXISTS vehicle_costs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  vehicle_id UUID REFERENCES vehicles(id) ON DELETE SET NULL,
  category_id UUID NOT NULL REFERENCES cost_categories(id) ON DELETE RESTRICT,
  
  -- Basisdaten
  title TEXT NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  currency TEXT DEFAULT 'EUR',
  date TIMESTAMPTZ NOT NULL,
  mileage INTEGER,
  notes TEXT,
  
  -- Treibstoff-spezifisch (optional, nur wenn category = fuel)
  is_refueling BOOLEAN DEFAULT FALSE,
  fuel_type TEXT, -- 'petrol', 'diesel', 'electric', 'hybrid'
  fuel_amount_liters DECIMAL(8,3), -- Menge in Litern
  price_per_liter DECIMAL(6,3), -- Preis pro Liter
  is_full_tank BOOLEAN DEFAULT FALSE, -- Vollbetankung?
  trip_distance INTEGER, -- km seit letzter Betankung
  gas_station TEXT, -- Tankstellen-Name
  
  -- Streckentyp (optional, für detaillierte Statistiken)
  distance_highway INTEGER, -- km Autobahn
  distance_city INTEGER, -- km Stadt
  distance_country INTEGER, -- km Landstraße
  
  -- Medien
  photos TEXT[], -- Array von Supabase Storage URLs
  
  -- Verknüpfung mit Wartungen (für Auto-Sync)
  maintenance_reminder_id UUID REFERENCES maintenance_reminders(id) ON DELETE SET NULL,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indizes für Performance
CREATE INDEX IF NOT EXISTS idx_vehicle_costs_user_id ON vehicle_costs(user_id);
CREATE INDEX IF NOT EXISTS idx_vehicle_costs_vehicle_id ON vehicle_costs(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_vehicle_costs_category_id ON vehicle_costs(category_id);
CREATE INDEX IF NOT EXISTS idx_vehicle_costs_date ON vehicle_costs(date DESC);
CREATE INDEX IF NOT EXISTS idx_vehicle_costs_maintenance_id ON vehicle_costs(maintenance_reminder_id);

-- RLS aktivieren
ALTER TABLE vehicle_costs ENABLE ROW LEVEL SECURITY;

-- Policies
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'vehicle_costs' AND policyname = 'Users can view own costs') THEN
    CREATE POLICY "Users can view own costs"
      ON vehicle_costs FOR SELECT
      USING (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'vehicle_costs' AND policyname = 'Users can insert own costs') THEN
    CREATE POLICY "Users can insert own costs"
      ON vehicle_costs FOR INSERT
      WITH CHECK (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'vehicle_costs' AND policyname = 'Users can update own costs') THEN
    CREATE POLICY "Users can update own costs"
      ON vehicle_costs FOR UPDATE
      USING (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'vehicle_costs' AND policyname = 'Users can delete own costs') THEN
    CREATE POLICY "Users can delete own costs"
      ON vehicle_costs FOR DELETE
      USING (auth.uid() = user_id);
  END IF;
END $$;

-- ============================================================================
-- 3. STANDARD-KATEGORIEN (SEED-DATEN)
-- ============================================================================
-- 11 vordefinierte Kategorien mit passenden Icons und Farben

-- Erst alte System-Kategorien löschen (falls vorhanden)
DELETE FROM cost_categories WHERE is_system = TRUE;

-- Dann neu einfügen
INSERT INTO cost_categories (user_id, name, icon_name, color_hex, is_system, sort_order) VALUES
  (NULL, 'fuel', 'local_gas_station', '#E53935', TRUE, 1),        -- Rot
  (NULL, 'maintenance', 'build', '#F8AD20', TRUE, 2),             -- Orange
  (NULL, 'insurance', 'shield', '#2196F3', TRUE, 3),              -- Blau
  (NULL, 'tax', 'account_balance', '#388E3C', TRUE, 4),           -- Grün
  (NULL, 'leasing', 'credit_card', '#9C27B0', TRUE, 5),           -- Lila
  (NULL, 'parking', 'local_parking', '#795548', TRUE, 6),         -- Braun
  (NULL, 'cleaning', 'local_car_wash', '#00BCD4', TRUE, 7),       -- Cyan
  (NULL, 'accessories', 'shopping_cart', '#FF9800', TRUE, 8),     -- Orange
  (NULL, 'vignette', 'confirmation_number', '#607D8B', TRUE, 9),  -- Blau-Grau
  (NULL, 'income', 'attach_money', '#4CAF50', TRUE, 10),          -- Hellgrün
  (NULL, 'other', 'more_horiz', '#9E9E9E', TRUE, 11);             -- Grau

-- ============================================================================
-- 4. TRIGGER FÜR UPDATED_AT
-- ============================================================================

-- Funktion für automatisches Update von updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger für cost_categories
DROP TRIGGER IF EXISTS update_cost_categories_updated_at ON cost_categories;
CREATE TRIGGER update_cost_categories_updated_at
  BEFORE UPDATE ON cost_categories
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trigger für vehicle_costs
DROP TRIGGER IF EXISTS update_vehicle_costs_updated_at ON vehicle_costs;
CREATE TRIGGER update_vehicle_costs_updated_at
  BEFORE UPDATE ON vehicle_costs
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 5. HELPER VIEWS (OPTIONAL)
-- ============================================================================

-- View für Kosten-Statistiken pro Kategorie
CREATE OR REPLACE VIEW cost_stats_by_category AS
SELECT 
  vc.user_id,
  vc.vehicle_id,
  cc.name as category_name,
  cc.icon_name,
  cc.color_hex,
  COUNT(vc.id) as total_count,
  SUM(vc.amount) as total_amount,
  AVG(vc.amount) as avg_amount,
  MIN(vc.date) as first_date,
  MAX(vc.date) as last_date
FROM vehicle_costs vc
JOIN cost_categories cc ON vc.category_id = cc.id
GROUP BY vc.user_id, vc.vehicle_id, cc.id, cc.name, cc.icon_name, cc.color_hex;

-- View für Treibstoff-Statistiken
CREATE OR REPLACE VIEW fuel_stats AS
SELECT 
  user_id,
  vehicle_id,
  COUNT(*) as refuel_count,
  SUM(fuel_amount_liters) as total_liters,
  AVG(fuel_amount_liters) as avg_liters_per_refuel,
  AVG(price_per_liter) as avg_price_per_liter,
  SUM(amount) as total_cost,
  -- Verbrauchsberechnung (nur bei Vollbetankung)
  AVG(CASE 
    WHEN is_full_tank AND trip_distance > 0 AND fuel_amount_liters > 0 
    THEN (fuel_amount_liters * 100.0 / trip_distance) 
    ELSE NULL 
  END) as avg_consumption_per_100km
FROM vehicle_costs
WHERE is_refueling = TRUE
GROUP BY user_id, vehicle_id;

-- ============================================================================
-- Migration abgeschlossen
-- ============================================================================
