-- ============================================
-- MIGRATION: Add Notification RPC Functions
-- Date: 2026-01-27
-- Description: RPC functions for notification management
-- ============================================

-- ============================================
-- 0. DROP EXISTING FUNCTIONS (if any)
-- ============================================

DROP FUNCTION IF EXISTS public.save_fcm_token(text, text, text);
DROP FUNCTION IF EXISTS public.get_user_notifications(int, int, boolean);
DROP FUNCTION IF EXISTS public.mark_notification_read(uuid, boolean);
DROP FUNCTION IF EXISTS public.mark_all_notifications_read();
DROP FUNCTION IF EXISTS public.delete_notification(uuid);
DROP FUNCTION IF EXISTS public.get_unread_notifications_count();

-- Drop all possible overloads of create_notification
DROP FUNCTION IF EXISTS public.create_notification(uuid, text, text, text);
DROP FUNCTION IF EXISTS public.create_notification(uuid, text, text, text, jsonb);
DROP FUNCTION IF EXISTS public.create_notification(uuid, text, text, text, jsonb, timestamptz);

DROP FUNCTION IF EXISTS public.get_user_fcm_tokens(uuid);


-- ============================================
-- 1. SAVE FCM TOKEN
-- ============================================

CREATE OR REPLACE FUNCTION public.save_fcm_token(
  p_token text,
  p_device_type text DEFAULT NULL,
  p_device_id text DEFAULT NULL
)
RETURNS public.fcm_tokens
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_token public.fcm_tokens;
BEGIN
  -- Upsert FCM token (update if exists, insert if not)
  INSERT INTO public.fcm_tokens (user_id, token, device_type, device_id, last_used_at)
  VALUES (auth.uid(), p_token, p_device_type, p_device_id, NOW())
  ON CONFLICT (token)
  DO UPDATE SET
    last_used_at = NOW(),
    device_type = COALESCE(EXCLUDED.device_type, fcm_tokens.device_type),
    device_id = COALESCE(EXCLUDED.device_id, fcm_tokens.device_id)
  RETURNING * INTO v_token;

  RETURN v_token;
END;
$$;

COMMENT ON FUNCTION public.save_fcm_token IS 'Save or update FCM token for push notifications';

-- ============================================
-- 2. GET USER NOTIFICATIONS
-- ============================================

CREATE OR REPLACE FUNCTION public.get_user_notifications(
  p_limit int DEFAULT 50,
  p_offset int DEFAULT 0,
  p_unread_only boolean DEFAULT false
)
RETURNS TABLE (
  id uuid,
  type text,
  title text,
  body text,
  data jsonb,
  read boolean,
  created_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    n.id,
    n.type,
    n.title,
    n.body,
    n.data,
    n.read,
    n.created_at
  FROM public.notifications n
  WHERE n.user_id = auth.uid()
    AND (NOT p_unread_only OR n.read = false)
    AND (n.expires_at IS NULL OR n.expires_at > NOW())
  ORDER BY n.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;

COMMENT ON FUNCTION public.get_user_notifications IS 'Get user notifications with pagination';

-- ============================================
-- 3. MARK NOTIFICATION AS READ
-- ============================================

CREATE OR REPLACE FUNCTION public.mark_notification_read(
  p_notification_id uuid,
  p_read boolean DEFAULT true
)
RETURNS public.notifications
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_notification public.notifications;
BEGIN
  -- Check if notification belongs to user
  IF NOT EXISTS (
    SELECT 1 FROM public.notifications 
    WHERE id = p_notification_id 
    AND user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Notification not found or unauthorized';
  END IF;

  -- Update read status
  UPDATE public.notifications
  SET read = p_read
  WHERE id = p_notification_id
  RETURNING * INTO v_notification;

  RETURN v_notification;
END;
$$;

COMMENT ON FUNCTION public.mark_notification_read IS 'Mark notification as read or unread';

-- ============================================
-- 4. MARK ALL NOTIFICATIONS AS READ
-- ============================================

CREATE OR REPLACE FUNCTION public.mark_all_notifications_read()
RETURNS int
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count int;
BEGIN
  UPDATE public.notifications
  SET read = true
  WHERE user_id = auth.uid()
    AND read = false;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;

COMMENT ON FUNCTION public.mark_all_notifications_read IS 'Mark all user notifications as read';

-- ============================================
-- 5. DELETE NOTIFICATION
-- ============================================

CREATE OR REPLACE FUNCTION public.delete_notification(
  p_notification_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Check if notification belongs to user
  IF NOT EXISTS (
    SELECT 1 FROM public.notifications 
    WHERE id = p_notification_id 
    AND user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Notification not found or unauthorized';
  END IF;

  -- Delete notification
  DELETE FROM public.notifications
  WHERE id = p_notification_id;

  RETURN true;
END;
$$;

COMMENT ON FUNCTION public.delete_notification IS 'Delete a notification';

-- ============================================
-- 6. GET UNREAD NOTIFICATIONS COUNT
-- ============================================

CREATE OR REPLACE FUNCTION public.get_unread_notifications_count()
RETURNS int
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count int;
BEGIN
  SELECT COUNT(*)
  INTO v_count
  FROM public.notifications
  WHERE user_id = auth.uid()
    AND read = false
    AND (expires_at IS NULL OR expires_at > NOW());

  RETURN v_count;
END;
$$;

COMMENT ON FUNCTION public.get_unread_notifications_count IS 'Get count of unread notifications';

-- ============================================
-- 7. CREATE NOTIFICATION (Internal use by triggers/edge functions)
-- ============================================

CREATE OR REPLACE FUNCTION public.create_notification(
  p_user_id uuid,
  p_type text,
  p_title text,
  p_body text,
  p_data jsonb DEFAULT '{}',
  p_expires_at timestamptz DEFAULT NULL
)
RETURNS public.notifications
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_notification public.notifications;
BEGIN
  INSERT INTO public.notifications (
    user_id,
    type,
    title,
    body,
    data,
    expires_at
  )
  VALUES (
    p_user_id,
    p_type,
    p_title,
    p_body,
    p_data,
    p_expires_at
  )
  RETURNING * INTO v_notification;

  RETURN v_notification;
END;
$$;

COMMENT ON FUNCTION public.create_notification IS 'Create a new notification (for internal use)';

-- ============================================
-- 8. GET USER FCM TOKENS
-- ============================================

CREATE OR REPLACE FUNCTION public.get_user_fcm_tokens(
  p_user_id uuid
)
RETURNS TABLE (
  token text,
  device_type text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    t.token,
    t.device_type
  FROM public.fcm_tokens t
  WHERE t.user_id = p_user_id
  ORDER BY t.last_used_at DESC;
END;
$$;

COMMENT ON FUNCTION public.get_user_fcm_tokens IS 'Get all FCM tokens for a user (for sending notifications)';

-- ============================================
-- GRANT PERMISSIONS
-- ============================================

GRANT EXECUTE ON FUNCTION public.save_fcm_token TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_notifications TO authenticated;
GRANT EXECUTE ON FUNCTION public.mark_notification_read TO authenticated;
GRANT EXECUTE ON FUNCTION public.mark_all_notifications_read TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_notification TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_unread_notifications_count TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_notification TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_fcm_tokens TO authenticated;
