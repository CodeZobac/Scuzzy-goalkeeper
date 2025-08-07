-- Migration: Track custom email system usage
-- NOTE: The real fix for disabling Supabase emails must be done in the Supabase Dashboard:
-- Authentication → Settings → Email → Disable all email options
-- This migration just tracks that we're using a custom system

-- 4. Create app_settings table if it doesn't exist and add flag
CREATE TABLE IF NOT EXISTS public.app_settings (
  id SERIAL PRIMARY KEY,
  key TEXT UNIQUE NOT NULL,
  value TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on app_settings
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;

-- Create RLS policy (only service role can modify, authenticated users can read)
CREATE POLICY "Allow read access to app_settings" ON public.app_settings
  FOR SELECT USING (auth.role() = 'authenticated' OR auth.role() = 'anon');

CREATE POLICY "Allow service role to manage app_settings" ON public.app_settings
  FOR ALL USING (auth.role() = 'service_role');

-- Insert the email system flag
INSERT INTO public.app_settings (key, value, description)
VALUES 
  ('email_system', 'python_backend', 'Email system is handled by Python backend, not Supabase')
ON CONFLICT (key) DO UPDATE SET 
  value = 'python_backend',
  description = 'Email system is handled by Python backend, not Supabase',
  updated_at = NOW();

-- 5. Add comment to table
COMMENT ON TABLE public.app_settings IS 'Application-wide settings and configuration flags. Used to track that email system is handled by Python backend instead of Supabase.';
