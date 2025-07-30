-- Create notifications table if it doesn't exist
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    type TEXT NOT NULL,
    data JSONB,
    read_at TIMESTAMPTZ,
    sent_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    category VARCHAR(50) DEFAULT 'general',
    requires_action BOOLEAN DEFAULT false,
    action_taken_at TIMESTAMP,
    expires_at TIMESTAMP,
    archived_at TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_read_at ON notifications(user_id, read_at);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_category_user ON notifications(user_id, category, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_requires_action ON notifications(user_id, requires_action, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_expires_at ON notifications(expires_at) WHERE expires_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_notifications_archived_at ON notifications(user_id, archived_at, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_category_archived ON notifications(user_id, category, archived_at, created_at DESC);

-- Enable RLS for notifications table
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Create policies for notifications table
CREATE POLICY "Users can view their own notifications" ON notifications 
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "System can insert notifications" ON notifications 
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can update their own notifications" ON notifications 
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own notifications" ON notifications 
  FOR DELETE USING (auth.uid() = user_id);

-- Enable real-time subscriptions for notifications
-- ALTER PUBLICATION supabase_realtime ADD TABLE notifications;

-- Add comments to explain the columns
COMMENT ON COLUMN notifications.category IS 'Category of notification (general, contracts, full_lobbies, etc.)';
COMMENT ON COLUMN notifications.requires_action IS 'Whether this notification requires user action';
COMMENT ON COLUMN notifications.action_taken_at IS 'Timestamp when user took action on notification';
COMMENT ON COLUMN notifications.expires_at IS 'Timestamp when notification expires (if applicable)';
COMMENT ON COLUMN notifications.archived_at IS 'Timestamp when notification was archived (after 30 days)';
