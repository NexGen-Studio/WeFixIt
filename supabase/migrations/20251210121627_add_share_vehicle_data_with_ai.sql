-- Add share_vehicle_data_with_ai column to vehicles table
-- This allows users to control whether their vehicle data is shared with AI
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name='vehicles' 
        AND column_name='share_vehicle_data_with_ai'
    ) THEN
        ALTER TABLE vehicles 
        ADD COLUMN share_vehicle_data_with_ai BOOLEAN DEFAULT TRUE NOT NULL;
        
        COMMENT ON COLUMN vehicles.share_vehicle_data_with_ai 
        IS 'Controls whether vehicle data is shared with AI features (Ask Toni, Diagnostics). Default: true';
    END IF;
END $$;
