-- ============================================
-- MIGRATION: Add Notification Triggers
-- Date: 2026-01-27
-- Description: Auto-create notifications on specific events
-- ============================================

-- ============================================
-- 0. DROP EXISTING TRIGGERS AND FUNCTIONS
-- ============================================

-- Drop triggers first
DROP TRIGGER IF EXISTS trigger_notify_driver_order_assigned ON public.orders;
DROP TRIGGER IF EXISTS trigger_notify_driver_order_canceled ON public.orders;
DROP TRIGGER IF EXISTS trigger_notify_driver_approval_status ON public.profiles;
DROP TRIGGER IF EXISTS trigger_notify_driver_order_completed ON public.orders;

-- Drop trigger functions
DROP FUNCTION IF EXISTS public.notify_driver_order_assigned();
DROP FUNCTION IF EXISTS public.notify_driver_order_canceled();
DROP FUNCTION IF EXISTS public.notify_driver_approval_status();
DROP FUNCTION IF EXISTS public.notify_driver_order_completed();
DROP FUNCTION IF EXISTS public.cleanup_old_notifications(int);


-- ============================================
-- 1. TRIGGER: Order Assigned to Driver
-- ============================================

CREATE OR REPLACE FUNCTION public.notify_driver_order_assigned()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_merchant_name text;
BEGIN
  -- Only notify when order is newly assigned (status changes to 'assigned')
  IF NEW.status = 'assigned' AND (OLD.status IS NULL OR OLD.status != 'assigned') AND NEW.driver_id IS NOT NULL THEN
    -- Get merchant name
    SELECT p.full_name INTO v_merchant_name
    FROM public.profiles p
    WHERE p.user_id = NEW.merchant_id;

    -- Create notification
    PERFORM public.create_notification(
      p_user_id := NEW.driver_id,
      p_type := 'order_assigned',
      p_title := 'Đơn hàng mới!',
      p_body := format('Bạn có đơn hàng mới #%s từ %s', 
        SUBSTRING(NEW.id::text, 1, 8),
        COALESCE(v_merchant_name, 'cửa hàng')),
      p_data := jsonb_build_object(
        'order_id', NEW.id,
        'merchant_id', NEW.merchant_id,
        'merchant_name', v_merchant_name
      )
    );
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_notify_driver_order_assigned
  AFTER INSERT OR UPDATE OF status, driver_id ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_driver_order_assigned();

COMMENT ON FUNCTION public.notify_driver_order_assigned IS 'Notify driver when order is assigned';

-- ============================================
-- 2. TRIGGER: Order Canceled
-- ============================================

CREATE OR REPLACE FUNCTION public.notify_driver_order_canceled()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Only notify driver if order was assigned to them
  IF NEW.status = 'canceled' AND OLD.status != 'canceled' AND NEW.driver_id IS NOT NULL THEN
    PERFORM public.create_notification(
      p_user_id := NEW.driver_id,
      p_type := 'order_canceled',
      p_title := 'Đơn hàng đã hủy',
      p_body := format('Đơn hàng #%s đã bị hủy', 
        SUBSTRING(NEW.id::text, 1, 8)),
      p_data := jsonb_build_object(
        'order_id', NEW.id,
        'reason', COALESCE(NEW.cancellation_reason, 'Không rõ lý do')
      )
    );
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_notify_driver_order_canceled
  AFTER UPDATE OF status ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_driver_order_canceled();

COMMENT ON FUNCTION public.notify_driver_order_canceled IS 'Notify driver when order is canceled';

-- ============================================
-- 3. TRIGGER: Driver Approval Status Changed
-- ============================================

CREATE OR REPLACE FUNCTION public.notify_driver_approval_status()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_title text;
  v_body text;
  v_type text;
BEGIN
  -- Only notify if driver role exists and approval status changed
  IF 'driver' = ANY(NEW.roles) AND 
     NEW.driver_approval_status IS DISTINCT FROM OLD.driver_approval_status THEN
    
    -- Approved
    IF NEW.driver_approval_status = 'approved' THEN
      v_type := 'approval_approved';
      v_title := 'Tài khoản đã được duyệt!';
      v_body := 'Chúc mừng! Bạn đã được phê duyệt làm tài xế. Bạn có thể bắt đầu nhận đơn hàng ngay bây giờ.';
    
    -- Rejected
    ELSIF NEW.driver_approval_status = 'rejected' THEN
      v_type := 'approval_rejected';
      v_title := 'Tài khoản bị từ chối';
      v_body := format('Rất tiếc, tài khoản của bạn đã bị từ chối. Lý do: %s', 
        COALESCE(NEW.driver_rejection_reason, 'Không rõ lý do'));
    
    ELSE
      RETURN NEW; -- Don't notify for other statuses
    END IF;

    -- Create notification
    PERFORM public.create_notification(
      p_user_id := NEW.user_id,
      p_type := v_type,
      p_title := v_title,
      p_body := v_body,
      p_data := jsonb_build_object(
        'approval_status', NEW.driver_approval_status,
        'rejection_reason', NEW.driver_rejection_reason
      )
    );
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_notify_driver_approval_status
  AFTER UPDATE OF driver_approval_status ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_driver_approval_status();

COMMENT ON FUNCTION public.notify_driver_approval_status IS 'Notify driver when approval status changes';

-- ============================================
-- 4. TRIGGER: Order Completed (Payment Received)
-- ============================================

CREATE OR REPLACE FUNCTION public.notify_driver_order_completed()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Notify driver when order is completed
  IF NEW.status = 'completed' AND OLD.status != 'completed' AND NEW.driver_id IS NOT NULL THEN
    PERFORM public.create_notification(
      p_user_id := NEW.driver_id,
      p_type := 'payment_received',
      p_title := 'Đã nhận thanh toán',
      p_body := format('Bạn đã nhận %s đ cho đơn hàng #%s', 
        TO_CHAR(COALESCE(NEW.delivery_fee, 0), 'FM999,999,999'),
        SUBSTRING(NEW.id::text, 1, 8)),
      p_data := jsonb_build_object(
        'order_id', NEW.id,
        'amount', COALESCE(NEW.delivery_fee, 0)
      )
    );
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_notify_driver_order_completed
  AFTER UPDATE OF status ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_driver_order_completed();

COMMENT ON FUNCTION public.notify_driver_order_completed IS 'Notify driver when order is completed and payment received';

-- ============================================
-- 5. CLEANUP: Delete old notifications (optional cron job)
-- ============================================

-- This function can be called by a cron job to clean up old notifications
CREATE OR REPLACE FUNCTION public.cleanup_old_notifications(
  p_days_old int DEFAULT 30
)
RETURNS int
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count int;
BEGIN
  DELETE FROM public.notifications
  WHERE created_at < NOW() - (p_days_old || ' days')::interval
    AND read = true;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;

COMMENT ON FUNCTION public.cleanup_old_notifications IS 'Delete read notifications older than specified days';
