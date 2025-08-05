-- Create function to check if email exists in auth.users
CREATE OR REPLACE FUNCTION check_email_exists(email_to_check TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Check if email exists in auth.users table
  RETURN EXISTS (
    SELECT 1 
    FROM auth.users 
    WHERE email = lower(email_to_check)
  );
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION check_email_exists(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION check_email_exists(TEXT) TO anon;