-- ============================================
-- MIGRATION: Add Assign Driver Role RPC
-- Description: Helper function to manually assign driver role to a user
-- ============================================

CREATE OR REPLACE FUNCTION public.assign_driver_role(p_user_id uuid)
RETURNS public.profiles
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_profile public.profiles;
BEGIN
  -- Check if caller is admin
  IF NOT ('admin' = ANY((SELECT roles FROM public.profiles WHERE user_id = auth.uid()))) THEN
    RAISE EXCEPTION 'Only admins can assign roles';
  END IF;

  -- Update profile: add 'driver' to roles array if not present
  UPDATE public.profiles
  SET 
    roles = CASE 
      WHEN NOT ('driver' = ANY(roles)) THEN array_append(roles, 'driver')
      ELSE roles
    END,
    driver_approval_status = 'approved',
    driver_status = 'offline',
    updated_at = NOW()
  WHERE user_id = p_user_id
  RETURNING * INTO v_profile;

  IF v_profile IS NULL THEN
    RAISE EXCEPTION 'Profile not found';
  END IF;

  RETURN v_profile;
END;
$$;

GRANT EXECUTE ON FUNCTION public.assign_driver_role TO authenticated;
