-- Create chat_history table for Ask Toni conversations
CREATE TABLE IF NOT EXISTS chat_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  messages JSONB NOT NULL DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  CONSTRAINT chat_history_title_length CHECK (char_length(title) >= 3 AND char_length(title) <= 100)
);

-- Add indexes (only if not exists)
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_chat_history_user_id') THEN
        CREATE INDEX idx_chat_history_user_id ON chat_history(user_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_chat_history_updated_at') THEN
        CREATE INDEX idx_chat_history_updated_at ON chat_history(user_id, updated_at DESC);
    END IF;
END $$;

-- Enable RLS
ALTER TABLE chat_history ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own chat history" ON chat_history;
DROP POLICY IF EXISTS "Users can create own chat history" ON chat_history;
DROP POLICY IF EXISTS "Users can update own chat history" ON chat_history;
DROP POLICY IF EXISTS "Users can delete own chat history" ON chat_history;

-- RLS Policies
CREATE POLICY "Users can view own chat history"
  ON chat_history FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create own chat history"
  ON chat_history FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own chat history"
  ON chat_history FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own chat history"
  ON chat_history FOR DELETE
  USING (auth.uid() = user_id);

-- Add comment
COMMENT ON TABLE chat_history IS 'Stores conversation history for Ask Toni chatbot';
COMMENT ON COLUMN chat_history.title IS 'Auto-generated title for the conversation';
COMMENT ON COLUMN chat_history.messages IS 'Array of messages in format: [{role: "user"|"assistant", content: "..."}]';
