-- Add vehicle_photo_url column to profiles table
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS vehicle_photo_url TEXT;

-- Add comment
COMMENT ON COLUMN profiles.vehicle_photo_url IS 'Public URL to vehicle photo stored in vehicle_photos bucket';
