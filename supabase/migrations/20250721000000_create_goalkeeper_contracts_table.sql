-- Create goalkeeper_contracts table for contract management
CREATE TABLE goalkeeper_contracts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  announcement_id BIGINT REFERENCES announcements(id) ON DELETE CASCADE,
  goalkeeper_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  contractor_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  offered_amount DECIMAL(10,2),
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined', 'expired')),
  additional_notes TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  responded_at TIMESTAMP,
  expires_at TIMESTAMP DEFAULT (NOW() + INTERVAL '24 hours')
);

-- Create indexes for better performance
CREATE INDEX idx_contracts_goalkeeper ON goalkeeper_contracts(goalkeeper_user_id, status);
CREATE INDEX idx_contracts_announcement ON goalkeeper_contracts(announcement_id, status);
CREATE INDEX idx_contracts_contractor ON goalkeeper_contracts(contractor_user_id, status);
CREATE INDEX idx_contracts_expires_at ON goalkeeper_contracts(expires_at) WHERE status = 'pending';

-- Add new columns to notifications table for enhanced functionality
ALTER TABLE notifications 
ADD COLUMN IF NOT EXISTS category VARCHAR(50) DEFAULT 'general',
ADD COLUMN IF NOT EXISTS requires_action BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS action_taken_at TIMESTAMP,
ADD COLUMN IF NOT EXISTS expires_at TIMESTAMP;

-- Create indexes for notifications
CREATE INDEX IF NOT EXISTS idx_notifications_category_user ON notifications(user_id, category, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_requires_action ON notifications(user_id, requires_action, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_expires_at ON notifications(expires_at) WHERE expires_at IS NOT NULL;

-- Enable RLS for goalkeeper_contracts
ALTER TABLE goalkeeper_contracts ENABLE ROW LEVEL SECURITY;

-- Create policies for goalkeeper_contracts
CREATE POLICY "Allow goalkeepers to see their contracts" ON goalkeeper_contracts 
  FOR SELECT USING (auth.uid() = goalkeeper_user_id);

CREATE POLICY "Allow contractors to see their created contracts" ON goalkeeper_contracts 
  FOR SELECT USING (auth.uid() = contractor_user_id);

CREATE POLICY "Allow authenticated users to create contracts" ON goalkeeper_contracts 
  FOR INSERT WITH CHECK (auth.uid() = contractor_user_id);

CREATE POLICY "Allow goalkeepers to update their contract responses" ON goalkeeper_contracts 
  FOR UPDATE USING (auth.uid() = goalkeeper_user_id);

CREATE POLICY "Allow system to update expired contracts" ON goalkeeper_contracts 
  FOR UPDATE USING (true);

-- Enable real-time subscriptions for both tables
ALTER PUBLICATION supabase_realtime ADD TABLE goalkeeper_contracts;
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;