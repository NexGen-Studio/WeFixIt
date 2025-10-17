-- Migration: Fix avatar_url in profiles table
-- Converts full URLs back to just the storage key

-- Update any avatar_url that contains a full URL to extract just the filename
UPDATE public.profiles
SET avatar_url = 
  CASE 
    -- If it's a full URL, extract just the filename
    WHEN avatar_url LIKE 'http%' THEN 
      substring(avatar_url from 'avatar_[a-f0-9\-]+\.jpg')
    -- Otherwise keep as is (it's already just a key)
    ELSE avatar_url
  END
WHERE avatar_url IS NOT NULL AND avatar_url != '';

-- Notify completion
DO $$ 
BEGIN
  RAISE NOTICE 'Avatar URLs cleaned up successfully!';
END $$;
