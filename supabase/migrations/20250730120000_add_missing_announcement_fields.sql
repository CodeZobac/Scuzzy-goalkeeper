-- Add missing fields to announcements table
ALTER TABLE announcements 
ADD COLUMN max_participants INTEGER DEFAULT 22,
ADD COLUMN needs_goalkeeper BOOLEAN DEFAULT false,
ADD COLUMN hired_goalkeeper_id UUID REFERENCES auth.users(id),
ADD COLUMN hired_goalkeeper_name TEXT,
ADD COLUMN goalkeeper_price NUMERIC(10, 2);

-- Create index for goalkeeper fields
CREATE INDEX idx_announcements_needs_goalkeeper ON announcements(needs_goalkeeper);
CREATE INDEX idx_announcements_hired_goalkeeper ON announcements(hired_goalkeeper_id);

-- Add comment to explain the new columns
COMMENT ON COLUMN announcements.max_participants IS 'Maximum number of participants allowed (default 22)';
COMMENT ON COLUMN announcements.needs_goalkeeper IS 'Whether this announcement is looking for a goalkeeper';
COMMENT ON COLUMN announcements.hired_goalkeeper_id IS 'User ID of hired goalkeeper if any';
COMMENT ON COLUMN announcements.hired_goalkeeper_name IS 'Name of hired goalkeeper for quick access';
COMMENT ON COLUMN announcements.goalkeeper_price IS 'Price offered for goalkeeper services';
