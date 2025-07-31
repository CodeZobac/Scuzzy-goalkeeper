-- Enable RLS for availabilities table
ALTER TABLE public.availabilities ENABLE ROW LEVEL SECURITY;

-- Create policies for availabilities table
CREATE POLICY "Users can view all availabilities" ON public.availabilities
  FOR SELECT USING (true);

CREATE POLICY "Users can insert their own availabilities" ON public.availabilities
  FOR INSERT WITH CHECK (auth.uid() = goalkeeper_id);

CREATE POLICY "Users can update their own availabilities" ON public.availabilities
  FOR UPDATE USING (auth.uid() = goalkeeper_id);

CREATE POLICY "Users can delete their own availabilities" ON public.availabilities
  FOR DELETE USING (auth.uid() = goalkeeper_id);
