# Fahrzeugbild-Feature Setup

## 1. Datenbank-Migration anwenden

```bash
# In Supabase Dashboard
# SQL Editor > New Query
# Füge folgenden SQL-Code ein:

ALTER TABLE profiles ADD COLUMN IF NOT EXISTS vehicle_photo_url TEXT;
COMMENT ON COLUMN profiles.vehicle_photo_url IS 'Public URL to vehicle photo stored in vehicle_photos bucket';
```

ODER via Supabase CLI (falls lokale Entwicklung):
```bash
supabase db push
```

## 2. Storage Buckets prüfen/erstellen

### In Supabase Dashboard > Storage:

#### Bucket: `vehicle_photos` (öffentlich)
- Name: `vehicle_photos`
- Public: **JA** ✓
- Allowed MIME types: `image/*`
- Max file size: 5 MB

**Policies für `vehicle_photos`:**
```sql
-- SELECT policy (public read)
CREATE POLICY "Public vehicle photos are viewable by everyone"
ON storage.objects FOR SELECT
USING (bucket_id = 'vehicle_photos');

-- INSERT policy (authenticated users only)
CREATE POLICY "Authenticated users can upload vehicle photos"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'vehicle_photos' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- UPDATE policy (users can update their own)
CREATE POLICY "Users can update their own vehicle photos"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'vehicle_photos' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- DELETE policy (users can delete their own)
CREATE POLICY "Users can delete their own vehicle photos"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'vehicle_photos' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);
```

#### Bucket: `avatars` (privat) 
Sollte bereits existieren, falls nicht:
- Name: `avatars`
- Public: **NEIN** ✗
- Allowed MIME types: `image/*`
- Max file size: 2 MB

**Policies für `avatars`:**
```sql
-- Authenticated users can upload/update their own avatar
CREATE POLICY "Users can upload their own avatar"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'avatars' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can update their own avatar"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'avatars' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Users can download their own avatar
CREATE POLICY "Users can view their own avatar"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'avatars' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);
```

## 3. Testen

1. **App neu starten**
2. **Anmelden**
3. **Profil → Profil bearbeiten**
4. **"Fahrzeugbild wählen"** oder **"Profilbild als Fahrzeugbild"** klicken
5. **Speichern** (automatisch)
6. **Zurück zu Home** → Fahrzeugbild sollte unter km-Stand erscheinen

## Fehlerbehebung

### "Fehler beim Kopieren"
- Prüfen: Ist ein Profilbild hochgeladen?
- Prüfen: Existiert `avatars` Bucket?
- Prüfen: Hat User Zugriff auf `avatars` Bucket?
- Console-Log prüfen: `Error copying avatar to vehicle: ...`

### Bild wird nicht angezeigt
- Prüfen: Ist `vehicle_photo_url` in der Datenbank gespeichert?
  ```sql
  SELECT id, vehicle_photo_url FROM profiles WHERE id = 'USER_ID';
  ```
- Prüfen: Ist `vehicle_photos` Bucket öffentlich?
- Prüfen: URL funktioniert im Browser?

### Upload schlägt fehl
- Prüfen: Existiert `vehicle_photos` Bucket?
- Prüfen: Sind Upload-Policies gesetzt?
- Prüfen: Ist User angemeldet?
- Console-Log prüfen: `Error uploading vehicle photo: ...`
