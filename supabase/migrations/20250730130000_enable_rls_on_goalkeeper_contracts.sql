-- Enable RLS for goalkeeper_contracts table
ALTER TABLE public.goalkeeper_contracts ENABLE ROW LEVEL SECURITY;

-- Create policies for goalkeeper_contracts table
CREATE POLICY "Users can view their own goalkeeper_contracts" ON public.goalkeeper_contracts
  FOR SELECT USING (auth.uid() = goalkeeper_user_id OR auth.uid() = contractor_user_id);

CREATE POLICY "Users can insert their own goalkeeper_contracts" ON public.goalkeeper_contracts
  FOR INSERT WITH CHECK (auth.uid() = contractor_user_id);

CREATE POLICY "Users can update their own goalkeeper_contracts" ON public.goalkeeper_contracts
  FOR UPDATE USING (auth.uid() = goalkeeper_user_id OR auth.uid() = contractor_user_id);

CREATE POLICY "Users can delete their own goalkeeper_contracts" ON public.goalkeeper_contracts
  FOR DELETE USING (auth.uid() = contractor_user_id);
