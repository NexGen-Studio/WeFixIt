-- Migration: Unlock Tires and Parking for Free Users
-- Created: 09.01.2026
-- Description: Sets is_locked = false for 'Reifen' and 'Parkgebühren' categories

-- Unlock 'Reifen' (Tires) - Free users can now track tire costs
UPDATE cost_categories
SET is_locked = false
WHERE is_system = true AND name = 'Reifen';

-- Unlock 'Parkgebühren' (Parking Fees) - Free users can now track parking costs
UPDATE cost_categories
SET is_locked = false
WHERE is_system = true AND name = 'Parkgebühren';

-- Verification
DO $$
DECLARE
  unlocked_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO unlocked_count 
  FROM cost_categories 
  WHERE is_system = true AND is_locked = false;
  
  RAISE NOTICE 'Migration completed! % system categories are now unlocked for free users.', unlocked_count;
END $$;
