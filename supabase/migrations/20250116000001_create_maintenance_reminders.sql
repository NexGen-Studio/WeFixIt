-- Wartungserinnerungen Tabelle
CREATE TABLE IF NOT EXISTS public.maintenance_reminders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  vehicle_id UUID REFERENCES public.vehicles(id) ON DELETE CASCADE,
  
  title TEXT NOT NULL,
  description TEXT,
  
  -- Erinnerungstyp: 'date' oder 'mileage'
  reminder_type TEXT NOT NULL CHECK (reminder_type IN ('date', 'mileage')),
  
  -- Für Datum-basierte Erinnerungen
  due_date TIMESTAMPTZ,
  
  -- Für Kilometer-basierte Erinnerungen
  due_mileage INTEGER,
  
  -- Wiederkehrend (optional)
  is_recurring BOOLEAN DEFAULT false,
  recurrence_interval_days INTEGER, -- z.B. 365 für jährlich
  recurrence_interval_km INTEGER,   -- z.B. 15000 für alle 15.000km
  
  -- Status
  is_completed BOOLEAN DEFAULT false,
  completed_at TIMESTAMPTZ,
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index für schnellere Abfragen
CREATE INDEX IF NOT EXISTS idx_maintenance_reminders_user_id ON public.maintenance_reminders(user_id);
CREATE INDEX IF NOT EXISTS idx_maintenance_reminders_vehicle_id ON public.maintenance_reminders(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_maintenance_reminders_due_date ON public.maintenance_reminders(due_date) WHERE reminder_type = 'date' AND NOT is_completed;

-- RLS Policies
ALTER TABLE public.maintenance_reminders ENABLE ROW LEVEL SECURITY;

-- User kann nur eigene Erinnerungen sehen
CREATE POLICY "Users can view own maintenance reminders"
  ON public.maintenance_reminders
  FOR SELECT
  USING (auth.uid() = user_id);

-- User kann eigene Erinnerungen erstellen
CREATE POLICY "Users can create own maintenance reminders"
  ON public.maintenance_reminders
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- User kann eigene Erinnerungen updaten
CREATE POLICY "Users can update own maintenance reminders"
  ON public.maintenance_reminders
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- User kann eigene Erinnerungen löschen
CREATE POLICY "Users can delete own maintenance reminders"
  ON public.maintenance_reminders
  FOR DELETE
  USING (auth.uid() = user_id);

-- Trigger für updated_at
CREATE OR REPLACE FUNCTION update_maintenance_reminders_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_maintenance_reminders_updated_at
  BEFORE UPDATE ON public.maintenance_reminders
  FOR EACH ROW
  EXECUTE FUNCTION update_maintenance_reminders_updated_at();
