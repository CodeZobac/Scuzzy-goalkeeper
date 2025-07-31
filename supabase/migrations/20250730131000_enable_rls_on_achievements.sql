-- Enable RLS for achievements table
ALTER TABLE public.achievements ENABLE ROW LEVEL SECURITY;

-- Create policies for achievements table
CREATE POLICY "Users can view all achievements" ON public.achievements
  FOR SELECT USING (true);

CREATE POLICY "Admins can insert new achievements" ON public.achievements
  FOR INSERT WITH CHECK (false);

CREATE POLICY "Admins can update achievements" ON public.achievements
  FOR UPDATE USING (false);

CREATE POLICY "Admins can delete achievements" ON public.achievements
  FOR DELETE USING (false);
