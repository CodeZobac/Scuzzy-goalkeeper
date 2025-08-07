-- Create function to get user ID by email from auth.users
CREATE OR REPLACE FUNCTION get_user_id_by_email(email_to_check TEXT)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Get user ID by email from auth.users table
  RETURN (
    SELECT id 
    FROM auth.users 
    WHERE email = lower(email_to_check)
    LIMIT 1
  );
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_user_id_by_email(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_id_by_email(TEXT) TO anon;