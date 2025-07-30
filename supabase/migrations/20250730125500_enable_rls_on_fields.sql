-- Enable RLS for fields table
ALTER TABLE public.fields ENABLE ROW LEVEL SECURITY;

-- Create policies for fields table
CREATE POLICY "Users can view all fields" ON public.fields
  FOR SELECT USING (true);

CREATE POLICY "Admins can insert new fields" ON public.fields
  FOR INSERT WITH CHECK (false);

CREATE POLICY "Admins can update fields" ON public.fields
  FOR UPDATE USING (false);

CREATE POLICY "Admins can delete fields" ON public.fields
  FOR DELETE USING (false);
