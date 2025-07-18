CREATE TABLE announcements (
    id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_by UUID REFERENCES auth.users(id),
    title TEXT NOT NULL,
    description TEXT,
    date DATE NOT NULL,
    time TIME NOT NULL,
    price NUMERIC(10, 2),
    stadium TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE announcement_participants (
    id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    announcement_id BIGINT NOT NULL REFERENCES announcements(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(announcement_id, user_id)
);

-- Enable RLS for the new tables
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcement_participants ENABLE ROW LEVEL SECURITY;

-- Create policies for announcements
CREATE POLICY "Allow all users to read announcements" ON announcements FOR SELECT USING (true);
CREATE POLICY "Allow authenticated users to create announcements" ON announcements FOR INSERT WITH CHECK (auth.uid() = created_by);
CREATE POLICY "Allow owner to update their announcements" ON announcements FOR UPDATE USING (auth.uid() = created_by);
CREATE POLICY "Allow owner to delete their announcements" ON announcements FOR DELETE USING (auth.uid() = created_by);

-- Create policies for announcement_participants
CREATE POLICY "Allow users to see participants of an announcement" ON announcement_participants FOR SELECT USING (true);
CREATE POLICY "Allow authenticated users to join an announcement" ON announcement_participants FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Allow users to leave an announcement" ON announcement_participants FOR DELETE USING (auth.uid() = user_id);
