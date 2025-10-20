-- Migration: Erweitere maintenance_reminders mit allen neuen Features
-- Datum: 2025-01-20
-- Beschreibung: Kategorien, Werkstatt, Kosten, Fotos, erweiterte Felder

-- Schritt 1: Füge neue Spalten zur maintenance_reminders Tabelle hinzu
ALTER TABLE public.maintenance_reminders 
  ADD COLUMN IF NOT EXISTS category text,
  ADD COLUMN IF NOT EXISTS mileage_at_maintenance integer,
  ADD COLUMN IF NOT EXISTS workshop_name text,
  ADD COLUMN IF NOT EXISTS workshop_address text,
  ADD COLUMN IF NOT EXISTS cost numeric(10, 2),
  ADD COLUMN IF NOT EXISTS notes text,
  ADD COLUMN IF NOT EXISTS photos text[], -- Array von Storage-Keys
  ADD COLUMN IF NOT EXISTS documents text[], -- Array von PDF/Dokument Storage-Keys
  ADD COLUMN IF NOT EXISTS status text DEFAULT 'planned' CHECK (status IN ('planned', 'completed', 'overdue')),
  ADD COLUMN IF NOT EXISTS notification_enabled boolean DEFAULT true,
  ADD COLUMN IF NOT EXISTS last_notification_sent timestamptz;

-- Schritt 2: Erstelle Index für Performance
CREATE INDEX IF NOT EXISTS idx_maintenance_category ON public.maintenance_reminders(category);
CREATE INDEX IF NOT EXISTS idx_maintenance_status ON public.maintenance_reminders(status);
CREATE INDEX IF NOT EXISTS idx_maintenance_vehicle_status ON public.maintenance_reminders(vehicle_id, status);

-- Schritt 3: Update-Funktion für Status (setzt automatisch auf 'overdue' wenn überfällig)
CREATE OR REPLACE FUNCTION update_maintenance_status()
RETURNS trigger AS $$
BEGIN
  -- Wenn Datum-basiert und überfällig
  IF NEW.due_date IS NOT NULL AND NEW.due_date < CURRENT_DATE AND NEW.status = 'planned' THEN
    NEW.status := 'overdue';
  END IF;
  
  -- Wenn erledigt, setze completed_at
  IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
    NEW.completed_at := NOW();
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Schritt 4: Trigger für automatischen Status-Update
DROP TRIGGER IF EXISTS maintenance_status_trigger ON public.maintenance_reminders;
CREATE TRIGGER maintenance_status_trigger
  BEFORE INSERT OR UPDATE ON public.maintenance_reminders
  FOR EACH ROW
  EXECUTE FUNCTION update_maintenance_status();

-- Schritt 5: Storage Bucket für Wartungsfotos/-dokumente erstellen
INSERT INTO storage.buckets (id, name, public)
VALUES ('maintenance-files', 'maintenance-files', false)
ON CONFLICT (id) DO NOTHING;

-- Schritt 6: RLS Policies für maintenance-files Bucket
DROP POLICY IF EXISTS "maintenance_files_owner_select" ON storage.objects;
CREATE POLICY "maintenance_files_owner_select" ON storage.objects
  FOR SELECT TO authenticated
  USING (bucket_id = 'maintenance-files' AND (storage.foldername(name))[1] = auth.uid()::text);

DROP POLICY IF EXISTS "maintenance_files_owner_insert" ON storage.objects;
CREATE POLICY "maintenance_files_owner_insert" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'maintenance-files' AND (storage.foldername(name))[1] = auth.uid()::text);

DROP POLICY IF EXISTS "maintenance_files_owner_update" ON storage.objects;
CREATE POLICY "maintenance_files_owner_update" ON storage.objects
  FOR UPDATE TO authenticated
  USING (bucket_id = 'maintenance-files' AND (storage.foldername(name))[1] = auth.uid()::text)
  WITH CHECK (bucket_id = 'maintenance-files' AND (storage.foldername(name))[1] = auth.uid()::text);

DROP POLICY IF EXISTS "maintenance_files_owner_delete" ON storage.objects;
CREATE POLICY "maintenance_files_owner_delete" ON storage.objects
  FOR DELETE TO authenticated
  USING (bucket_id = 'maintenance-files' AND (storage.foldername(name))[1] = auth.uid()::text);

-- Schritt 7: View für Wartungsstatistiken
CREATE OR REPLACE VIEW maintenance_stats AS
SELECT 
  vehicle_id,
  COUNT(*) FILTER (WHERE status = 'planned') as planned_count,
  COUNT(*) FILTER (WHERE status = 'completed') as completed_count,
  COUNT(*) FILTER (WHERE status = 'overdue') as overdue_count,
  SUM(cost) FILTER (WHERE status = 'completed') as total_cost,
  MAX(due_date) FILTER (WHERE status = 'planned') as next_maintenance_date,
  AVG(cost) FILTER (WHERE status = 'completed' AND cost > 0) as avg_cost
FROM public.maintenance_reminders
GROUP BY vehicle_id;

-- Grant access zur View
GRANT SELECT ON maintenance_stats TO authenticated;

-- Notify completion
DO $$ 
BEGIN
  RAISE NOTICE 'Maintenance extended features migration completed successfully!';
END $$;
