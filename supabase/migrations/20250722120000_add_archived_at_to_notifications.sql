-- Add archived_at column to notifications table for notification archiving after 30 days
ALTER TABLE notifications 
ADD COLUMN archived_at TIMESTAMP;

-- Create index for better performance when filtering archived notifications
CREATE INDEX idx_notifications_archived_at ON notifications(user_id, archived_at, created_at DESC);

-- Create index for better performance when filtering by category and archived status
CREATE INDEX idx_notifications_category_archived ON notifications(user_id, category, archived_at, created_at DESC);

-- Add comment to explain the column purpose
COMMENT ON COLUMN notifications.archived_at IS 'Timestamp when notification was archived (after 30 days)';