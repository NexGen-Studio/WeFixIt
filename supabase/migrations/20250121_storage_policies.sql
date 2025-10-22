-- Storage policies for vehicle_photos bucket (public)

-- Public vehicle photos are viewable by everyone
CREATE POLICY IF NOT EXISTS "Public vehicle photos viewable"
ON storage.objects FOR SELECT
USING (bucket_id = 'vehicle_photos');

-- Authenticated users can upload vehicle photos
CREATE POLICY IF NOT EXISTS "Authenticated users upload vehicle photos"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'vehicle_photos' 
  AND auth.role() = 'authenticated'
);

-- Users can update their own vehicle photos
CREATE POLICY IF NOT EXISTS "Users update own vehicle photos"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'vehicle_photos' 
  AND auth.role() = 'authenticated'
);

-- Users can delete their own vehicle photos
CREATE POLICY IF NOT EXISTS "Users delete own vehicle photos"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'vehicle_photos' 
  AND auth.role() = 'authenticated'
);

-- Storage policies for avatars bucket (private)

-- Users can upload their own avatar
CREATE POLICY IF NOT EXISTS "Users upload own avatar"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'avatars' 
  AND auth.role() = 'authenticated'
);

-- Users can update their own avatar
CREATE POLICY IF NOT EXISTS "Users update own avatar"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'avatars' 
  AND auth.role() = 'authenticated'
);

-- Users can view their own avatar
CREATE POLICY IF NOT EXISTS "Users view own avatar"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'avatars' 
  AND auth.role() = 'authenticated'
);

-- Users can delete their own avatar
CREATE POLICY IF NOT EXISTS "Users delete own avatar"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'avatars' 
  AND auth.role() = 'authenticated'
);
