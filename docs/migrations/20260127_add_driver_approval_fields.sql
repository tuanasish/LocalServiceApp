-- ============================================
-- MIGRATION: Add Driver Approval Fields
-- Date: 2026-01-27
-- Description: Add driver approval workflow fields to profiles table
-- ============================================

-- Add driver approval fields to profiles table
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS driver_approval_status text DEFAULT 'pending',
  ADD COLUMN IF NOT EXISTS driver_approved_at timestamptz,
  ADD COLUMN IF NOT EXISTS driver_approved_by uuid REFERENCES public.profiles(user_id),
  ADD COLUMN IF NOT EXISTS driver_rejection_reason text,
  ADD COLUMN IF NOT EXISTS driver_vehicle_info jsonb DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS driver_license_info jsonb DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS driver_documents jsonb DEFAULT '[]';

-- Add comment for documentation
COMMENT ON COLUMN public.profiles.driver_approval_status IS 'Driver approval status: pending, approved, rejected';
COMMENT ON COLUMN public.profiles.driver_vehicle_info IS 'Vehicle information: {type, plate_number, brand, model, year, color}';
COMMENT ON COLUMN public.profiles.driver_license_info IS 'License information: {number, expiry_date, issue_date, class}';
COMMENT ON COLUMN public.profiles.driver_documents IS 'Array of document URLs: [license_photo, vehicle_registration, insurance, etc]';

-- Create index for driver approval queries
CREATE INDEX IF NOT EXISTS profiles_driver_approval_idx 
  ON public.profiles(driver_approval_status) 
  WHERE 'driver' = ANY(roles);

-- Migrate existing drivers to 'approved' status
-- This ensures backward compatibility - all current drivers can continue working
UPDATE public.profiles
SET 
  driver_approval_status = 'approved',
  driver_approved_at = created_at
WHERE 'driver' = ANY(roles)
  AND driver_approval_status = 'pending';

-- Add check constraint for valid approval statuses
ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_driver_approval_status_check
  CHECK (driver_approval_status IN ('pending', 'approved', 'rejected'));

COMMENT ON TABLE public.profiles IS 'User profiles with driver approval workflow support';
