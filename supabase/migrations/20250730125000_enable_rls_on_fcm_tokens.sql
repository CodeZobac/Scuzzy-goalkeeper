-- Enable RLS for fcm_tokens table
ALTER TABLE public.fcm_tokens ENABLE ROW LEVEL SECURITY;

-- Create policies for fcm_tokens table
CREATE POLICY "Users can view their own fcm_tokens" ON public.fcm_tokens
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own fcm_tokens" ON public.fcm_tokens
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own fcm_tokens" ON public.fcm_tokens
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own fcm_tokens" ON public.fcm_tokens
  FOR DELETE USING (auth.uid() = user_id);
