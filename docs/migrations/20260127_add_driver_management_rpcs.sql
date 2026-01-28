-- ============================================
-- MIGRATION: Add Driver Management RPC Functions
-- Date: 2026-01-27
-- Description: RPC functions for driver approval and statistics
-- ============================================

-- ============================================
-- 1. APPROVE DRIVER
-- ============================================

CREATE OR REPLACE FUNCTION public.approve_driver(
  p_driver_id uuid,
  p_admin_notes text DEFAULT NULL
)
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
    RAISE EXCEPTION 'Only admins can approve drivers';
  END IF;

  -- Check if driver exists and has driver role
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE user_id = p_driver_id 
    AND 'driver' = ANY(roles)
  ) THEN
    RAISE EXCEPTION 'Driver not found or user does not have driver role';
  END IF;

  -- Update driver status
  UPDATE public.profiles
  SET 
    driver_approval_status = 'approved',
    driver_approved_at = NOW(),
    driver_approved_by = auth.uid(),
    driver_rejection_reason = NULL,
    updated_at = NOW()
  WHERE user_id = p_driver_id
  RETURNING * INTO v_profile;

  RETURN v_profile;
END;
$$;

COMMENT ON FUNCTION public.approve_driver IS 'Approve a pending driver application (admin only)';

-- ============================================
-- 2. REJECT DRIVER
-- ============================================

CREATE OR REPLACE FUNCTION public.reject_driver(
  p_driver_id uuid,
  p_reason text
)
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
    RAISE EXCEPTION 'Only admins can reject drivers';
  END IF;

  -- Check if driver exists
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE user_id = p_driver_id 
    AND 'driver' = ANY(roles)
  ) THEN
    RAISE EXCEPTION 'Driver not found or user does not have driver role';
  END IF;

  -- Validate reason is provided
  IF p_reason IS NULL OR TRIM(p_reason) = '' THEN
    RAISE EXCEPTION 'Rejection reason is required';
  END IF;

  -- Update driver status
  UPDATE public.profiles
  SET 
    driver_approval_status = 'rejected',
    driver_rejection_reason = p_reason,
    driver_approved_at = NULL,
    driver_approved_by = NULL,
    updated_at = NOW()
  WHERE user_id = p_driver_id
  RETURNING * INTO v_profile;

  RETURN v_profile;
END;
$$;

COMMENT ON FUNCTION public.reject_driver IS 'Reject a driver application with reason (admin only)';

-- ============================================
-- 3. GET DRIVER STATISTICS
-- ============================================

CREATE OR REPLACE FUNCTION public.get_driver_statistics(p_driver_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_stats jsonb;
BEGIN
  -- Check if caller is admin or the driver themselves
  IF NOT (
    'admin' = ANY((SELECT roles FROM public.profiles WHERE user_id = auth.uid()))
    OR auth.uid() = p_driver_id
  ) THEN
    RAISE EXCEPTION 'Unauthorized to view driver statistics';
  END IF;

  -- Calculate statistics
  SELECT jsonb_build_object(
    'total_orders', COUNT(*),
    'completed_orders', COUNT(*) FILTER (WHERE status = 'completed'),
    'canceled_orders', COUNT(*) FILTER (WHERE status = 'canceled'),
    'active_orders', COUNT(*) FILTER (WHERE status IN ('assigned', 'picked_up')),
    'total_earnings', COALESCE(SUM(delivery_fee) FILTER (WHERE status = 'completed'), 0),
    'avg_delivery_time_minutes', COALESCE(
      ROUND(AVG(EXTRACT(EPOCH FROM (completed_at - picked_up_at)) / 60)::numeric, 2) 
      FILTER (WHERE status = 'completed' AND picked_up_at IS NOT NULL AND completed_at IS NOT NULL), 
      0
    ),
    'first_order_date', MIN(created_at),
    'last_order_date', MAX(created_at),
    'orders_this_week', COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '7 days'),
    'orders_this_month', COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '30 days'),
    'completion_rate', CASE 
      WHEN COUNT(*) > 0 THEN 
        ROUND((COUNT(*) FILTER (WHERE status = 'completed')::numeric / COUNT(*)::numeric * 100), 2)
      ELSE 0 
    END
  ) INTO v_stats
  FROM public.orders
  WHERE driver_id = p_driver_id;

  RETURN v_stats;
END;
$$;

COMMENT ON FUNCTION public.get_driver_statistics IS 'Get comprehensive statistics for a driver';

-- ============================================
-- 4. GET ALL DRIVERS (Admin Only)
-- ============================================

CREATE OR REPLACE FUNCTION public.get_all_drivers(
  p_approval_status text DEFAULT NULL,
  p_driver_status text DEFAULT NULL,
  p_limit int DEFAULT 100,
  p_offset int DEFAULT 0
)
RETURNS TABLE (
  user_id uuid,
  phone text,
  full_name text,
  roles text[],
  driver_status text,
  driver_approval_status text,
  driver_approved_at timestamptz,
  driver_vehicle_info jsonb,
  driver_license_info jsonb,
  created_at timestamptz,
  updated_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Check if caller is admin
  IF NOT ('admin' = ANY((SELECT p.roles FROM public.profiles p WHERE p.user_id = auth.uid()))) THEN
    RAISE EXCEPTION 'Only admins can view all drivers';
  END IF;

  RETURN QUERY
  SELECT 
    p.user_id,
    p.phone,
    p.full_name,
    p.roles,
    p.driver_status,
    p.driver_approval_status,
    p.driver_approved_at,
    p.driver_vehicle_info,
    p.driver_license_info,
    p.created_at,
    p.updated_at
  FROM public.profiles p
  WHERE 'driver' = ANY(p.roles)
    AND (p_approval_status IS NULL OR p.driver_approval_status = p_approval_status)
    AND (p_driver_status IS NULL OR p.driver_status = p_driver_status)
  ORDER BY 
    CASE 
      WHEN p.driver_approval_status = 'pending' THEN 1
      WHEN p.driver_approval_status = 'approved' THEN 2
      ELSE 3
    END,
    p.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;

COMMENT ON FUNCTION public.get_all_drivers IS 'Get all drivers with optional filters (admin only)';

-- ============================================
-- GRANT PERMISSIONS
-- ============================================

-- Grant execute permissions to authenticated users
GRANT EXECUTE ON FUNCTION public.approve_driver TO authenticated;
GRANT EXECUTE ON FUNCTION public.reject_driver TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_driver_statistics TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_all_drivers TO authenticated;
