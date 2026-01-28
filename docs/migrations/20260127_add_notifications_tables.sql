-- ============================================
-- MIGRATION: Add Notifications Tables (Safe Version)
-- Date: 2026-01-27
-- Description: Safely drop and recreate notifications tables
-- ============================================

-- ============================================
-- 0. SAFELY DROP EXISTING TABLES
-- ============================================

-- Note: We use IF EXISTS to avoid errors if objects don't exist yet

-- Drop existing tables first (CASCADE will drop dependent policies)
DROP TABLE IF EXISTS public.notifications CASCADE;
DROP TABLE IF EXISTS public.fcm_tokens CASCADE;


-- ============================================
-- 1. NOTIFICATIONS TABLE
-- ============================================

CREATE TABLE public.notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES public.profiles(user_id) ON DELETE CASCADE NOT NULL,
  type text NOT NULL,
  title text NOT NULL,
  body text NOT NULL,
  data jsonb DEFAULT '{}',
  read boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  expires_at timestamptz,
  CONSTRAINT notifications_type_check CHECK (
    type IN (
      'order_assigned',
      'order_canceled',
      'order_completed',
      'approval_approved',
      'approval_rejected',
      'payment_received',
      'announcement',
      'system_alert'
    )
  )
);

-- Comments
COMMENT ON TABLE public.notifications IS 'Push notifications for users';
COMMENT ON COLUMN public.notifications.type IS 'Notification type: order_assigned, order_canceled, approval_approved, etc.';
COMMENT ON COLUMN public.notifications.data IS 'Additional data as JSON (order_id, amount, etc.)';
COMMENT ON COLUMN public.notifications.expires_at IS 'Notification expiry time (auto-delete after this)';

-- Indexes for performance
CREATE INDEX notifications_user_id_created_at_idx 
  ON public.notifications(user_id, created_at DESC);

CREATE INDEX notifications_user_id_read_idx 
  ON public.notifications(user_id, read) 
  WHERE read = false;

CREATE INDEX notifications_expires_at_idx 
  ON public.notifications(expires_at) 
  WHERE expires_at IS NOT NULL;

-- ============================================
-- 2. FCM TOKENS TABLE
-- ============================================

CREATE TABLE public.fcm_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES public.profiles(user_id) ON DELETE CASCADE NOT NULL,
  token text NOT NULL UNIQUE,
  device_type text,
  device_id text,
  created_at timestamptz DEFAULT now(),
  last_used_at timestamptz DEFAULT now(),
  CONSTRAINT fcm_tokens_device_type_check CHECK (
    device_type IN ('android', 'ios', 'web')
  )
);

-- Indexes
CREATE INDEX fcm_tokens_user_id_idx 
  ON public.fcm_tokens(user_id);

CREATE INDEX fcm_tokens_token_idx 
  ON public.fcm_tokens(token);

-- Comments
COMMENT ON TABLE public.fcm_tokens IS 'Firebase Cloud Messaging tokens for push notifications';
COMMENT ON COLUMN public.fcm_tokens.token IS 'FCM registration token';
COMMENT ON COLUMN public.fcm_tokens.device_type IS 'Device platform: android, ios, web';
COMMENT ON COLUMN public.fcm_tokens.device_id IS 'Unique device identifier';

-- ============================================
-- 3. AUTO-DELETE EXPIRED NOTIFICATIONS
-- ============================================

CREATE OR REPLACE FUNCTION public.delete_expired_notifications()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  DELETE FROM public.notifications
  WHERE expires_at IS NOT NULL
    AND expires_at < NOW();
END;
$$;

COMMENT ON FUNCTION public.delete_expired_notifications IS 'Delete notifications that have expired';

-- ============================================
-- 4. ENABLE ROW LEVEL SECURITY
-- ============================================

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fcm_tokens ENABLE ROW LEVEL SECURITY;

-- Notifications policies
CREATE POLICY "Users can view their own notifications"
  ON public.notifications
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications"
  ON public.notifications
  FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own notifications"
  ON public.notifications
  FOR DELETE
  USING (auth.uid() = user_id);

CREATE POLICY "System can insert notifications"
  ON public.notifications
  FOR INSERT
  WITH CHECK (true);

-- FCM tokens policies
CREATE POLICY "Users can view their own FCM tokens"
  ON public.fcm_tokens
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own FCM tokens"
  ON public.fcm_tokens
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own FCM tokens"
  ON public.fcm_tokens
  FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own FCM tokens"
  ON public.fcm_tokens
  FOR DELETE
  USING (auth.uid() = user_id);
