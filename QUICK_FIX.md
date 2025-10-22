# 🚗 Fahrzeugbild jetzt einrichten

## ⚡ Schnellanleitung (5 Minuten)

### Schritt 1: Datenbank-Spalte hinzufügen

Gehe zu **Supabase Dashboard** → **SQL Editor** → **New Query**

Füge ein und klicke **Run**:
```sql
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS vehicle_photo_url TEXT;
```

### Schritt 2: Storage Buckets erstellen

Gehe zu **Supabase Dashboard** → **Storage**

#### A) Bucket `vehicle_photos` erstellen (falls nicht vorhanden)
1. Klicke **"New bucket"**
2. Name: `vehicle_photos`
3. **Public**: ✓ AN
4. Klicke **"Create bucket"**

#### B) Bucket `avatars` prüfen (sollte existieren)
- Falls nicht vorhanden, erstelle ihn
- **Public**: ✗ AUS

### Schritt 3: Policies setzen

Gehe zu **Supabase Dashboard** → **SQL Editor** → **New Query**

Füge folgenden Code ein und klicke **Run**:

```sql
-- Vehicle photos policies (public bucket)
CREATE POLICY IF NOT EXISTS "Public vehicle photos viewable"
ON storage.objects FOR SELECT
USING (bucket_id = 'vehicle_photos');

CREATE POLICY IF NOT EXISTS "Authenticated users upload vehicle photos"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'vehicle_photos' AND auth.role() = 'authenticated');

CREATE POLICY IF NOT EXISTS "Users update own vehicle photos"
ON storage.objects FOR UPDATE
USING (bucket_id = 'vehicle_photos' AND auth.role() = 'authenticated');

-- Avatars policies (private bucket)
CREATE POLICY IF NOT EXISTS "Users upload own avatar"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'avatars' AND auth.role() = 'authenticated');

CREATE POLICY IF NOT EXISTS "Users view own avatar"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars' AND auth.role() = 'authenticated');
```

### Schritt 4: App testen

1. **Hot Restart** der App (nicht nur Hot Reload)
2. **Anmelden**
3. **Profil** → **Profil bearbeiten**
4. **"Fahrzeugbild wählen"** klicken
5. Bild auswählen
6. Warten auf Bestätigung: "Fahrzeugbild hochgeladen und gespeichert"
7. **Zurück zu Home**
8. **Fahrzeugbild sollte jetzt unter km-Stand erscheinen!**

## 🔧 Fehler beheben

### "Fehler beim Kopieren"
→ Erst ein Profilbild hochladen, dann nochmal versuchen

### Bild wird nicht angezeigt
→ Prüfe ob `vehicle_photos` Bucket **public** ist

### Upload schlägt fehl
→ Prüfe ob Policies gesetzt sind (Schritt 3)

## ✅ Fertig!

Wenn alles funktioniert:
- ✓ Fahrzeugbild wird hochgeladen
- ✓ Fahrzeugbild wird in Datenbank gespeichert
- ✓ Fahrzeugbild erscheint auf Home Screen
- ✓ "Profilbild als Fahrzeugbild" funktioniert
