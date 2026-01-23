-- Add vehicle_specific_en column for English vehicle-specific data
-- vehicle_specific stays GERMAN, vehicle_specific_en is ENGLISH

ALTER TABLE automotive_knowledge
  ADD COLUMN IF NOT EXISTS vehicle_specific_en JSONB DEFAULT '{}'::jsonb;

CREATE INDEX IF NOT EXISTS idx_automotive_knowledge_vehicle_specific_en 
  ON automotive_knowledge USING gin(vehicle_specific_en);

COMMENT ON COLUMN automotive_knowledge.vehicle_specific_en IS 
  'English vehicle-specific diagnostic information (issues, causes, parts, costs)';
