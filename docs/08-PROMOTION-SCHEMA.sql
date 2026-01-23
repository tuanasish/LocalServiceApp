-- ============================================
-- CHỢ QUÊ MVP - PROMOTION SCHEMA
-- Version: 1.1
-- Bổ sung: Freeship first order + Voucher code
-- Run after 02-SCHEMA.sql
-- ============================================

-- ============================================
-- 1. PROMOTIONS TABLE
-- ============================================

CREATE TABLE public.promotions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  market_id text NOT NULL,
  
  -- Identification
  code text UNIQUE,                    -- NULL = tự động apply (first_order)
  name text NOT NULL,                  -- "Freeship đơn đầu", "GIAM10K"
  description text,
  
  -- Type & Discount
  promo_type text NOT NULL,            -- 'first_order', 'voucher', 'all_orders'
  discount_type text NOT NULL,         -- 'freeship', 'fixed', 'percent'
  discount_value int NOT NULL,         -- VD: 15000 (freeship max), 10000 (fixed), 10 (percent)
  max_discount int,                    -- Cap cho percent: VD max 20000
  
  -- Conditions
  min_order_value int DEFAULT 0,       -- Đơn tối thiểu để apply
  service_type text DEFAULT 'food',    -- 'food' only for this app
  
  -- Usage limits
  max_total_uses int,                  -- NULL = unlimited
  max_uses_per_user int DEFAULT 1,     -- Mỗi user dùng được bao nhiêu lần
  current_uses int DEFAULT 0,
  
  -- Validity
  valid_from timestamptz DEFAULT now(),
  valid_to timestamptz,
  status text DEFAULT 'active',        -- 'active', 'paused', 'expired'
  
  -- Metadata
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX promotions_market_idx ON public.promotions(market_id, status);
CREATE INDEX promotions_code_idx ON public.promotions(code) WHERE code IS NOT NULL;
CREATE INDEX promotions_type_idx ON public.promotions(promo_type, status);

-- ============================================
-- 2. USER PROMOTIONS (Usage tracking)
-- ============================================

CREATE TABLE public.user_promotions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(user_id) ON DELETE CASCADE,
  promotion_id uuid NOT NULL REFERENCES public.promotions(id) ON DELETE CASCADE,
  order_id uuid REFERENCES public.orders(id) ON DELETE SET NULL,
  discount_applied int NOT NULL,       -- Số tiền thực tế được giảm
  used_at timestamptz DEFAULT now(),
  
  -- Prevent duplicate usage based on promo rules
  UNIQUE(user_id, promotion_id, order_id)
);

CREATE INDEX user_promotions_user_idx ON public.user_promotions(user_id);
CREATE INDEX user_promotions_promo_idx ON public.user_promotions(promotion_id);

-- ============================================
-- 3. ALTER ORDERS TABLE
-- ============================================

ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS
  promotion_id uuid REFERENCES public.promotions(id),
  promotion_code text,
  discount_amount int DEFAULT 0;

-- ============================================
-- 4. RLS POLICIES
-- ============================================

ALTER TABLE public.promotions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_promotions ENABLE ROW LEVEL SECURITY;

-- Promotions: Anyone can read active, only admin can manage
CREATE POLICY "Anyone read active promotions" ON public.promotions 
  FOR SELECT USING (status = 'active' AND (valid_to IS NULL OR valid_to > now()));
CREATE POLICY "Admin manage promotions" ON public.promotions 
  FOR ALL USING (has_role('super_admin'));

-- User Promotions: Users see their own, admin sees all
CREATE POLICY "Users read own promotions" ON public.user_promotions 
  FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Admin read all user promotions" ON public.user_promotions 
  FOR SELECT USING (has_role('super_admin'));
CREATE POLICY "Service role full access" ON public.user_promotions 
  FOR ALL USING (auth.role() = 'service_role');

-- ============================================
-- 5. HELPER FUNCTIONS
-- ============================================

-- Check if user is eligible for first order promo
CREATE OR REPLACE FUNCTION public.is_first_order(p_user_id uuid)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
AS $$
  SELECT NOT EXISTS (
    SELECT 1 FROM public.orders
    WHERE customer_id = p_user_id
      AND status = 'COMPLETED'
  );
$$;

-- Get applicable promotions for user
CREATE OR REPLACE FUNCTION public.get_available_promotions(
  p_user_id uuid,
  p_market_id text,
  p_order_value int
)
RETURNS TABLE (
  id uuid,
  code text,
  name text,
  discount_type text,
  discount_value int,
  max_discount int
)
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
    p.code,
    p.name,
    p.discount_type,
    p.discount_value,
    p.max_discount
  FROM public.promotions p
  WHERE p.market_id = p_market_id
    AND p.status = 'active'
    AND (p.valid_from IS NULL OR p.valid_from <= now())
    AND (p.valid_to IS NULL OR p.valid_to > now())
    AND (p.min_order_value <= p_order_value)
    AND (p.max_total_uses IS NULL OR p.current_uses < p.max_total_uses)
    -- Check user hasn't exceeded their limit
    AND (
      SELECT COUNT(*) FROM public.user_promotions up 
      WHERE up.user_id = p_user_id AND up.promotion_id = p.id
    ) < p.max_uses_per_user
    -- Special check for first_order type
    AND (
      p.promo_type != 'first_order' 
      OR is_first_order(p_user_id)
    );
END;
$$;

-- Calculate discount amount
CREATE OR REPLACE FUNCTION public.calculate_discount(
  p_promotion_id uuid,
  p_delivery_fee int,
  p_items_total int
)
RETURNS int
LANGUAGE plpgsql STABLE
AS $$
DECLARE
  v_promo public.promotions;
  v_discount int;
BEGIN
  SELECT * INTO v_promo FROM public.promotions WHERE id = p_promotion_id;
  
  IF v_promo IS NULL THEN
    RETURN 0;
  END IF;
  
  CASE v_promo.discount_type
    WHEN 'freeship' THEN
      -- Freeship: giảm tối đa = delivery_fee, nhưng không quá discount_value
      v_discount := LEAST(p_delivery_fee, v_promo.discount_value);
    WHEN 'fixed' THEN
      -- Fixed: giảm cố định
      v_discount := v_promo.discount_value;
    WHEN 'percent' THEN
      -- Percent: % của tổng đơn, cap bởi max_discount
      v_discount := (p_items_total * v_promo.discount_value / 100);
      IF v_promo.max_discount IS NOT NULL THEN
        v_discount := LEAST(v_discount, v_promo.max_discount);
      END IF;
  END CASE;
  
  RETURN COALESCE(v_discount, 0);
END;
$$;

-- Apply promotion to order (update create_order or use separately)
CREATE OR REPLACE FUNCTION public.apply_promotion(
  p_order_id uuid,
  p_promotion_id uuid
)
RETURNS public.orders
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_order public.orders;
  v_promo public.promotions;
  v_discount int;
BEGIN
  -- Get order
  SELECT * INTO v_order FROM public.orders WHERE id = p_order_id FOR UPDATE;
  IF v_order IS NULL THEN
    RAISE EXCEPTION 'ORDER_NOT_FOUND';
  END IF;
  
  -- Check order belongs to current user
  IF v_order.customer_id != auth.uid() THEN
    RAISE EXCEPTION 'NOT_ALLOWED';
  END IF;
  
  -- Get promotion
  SELECT * INTO v_promo FROM public.promotions WHERE id = p_promotion_id;
  IF v_promo IS NULL OR v_promo.status != 'active' THEN
    RAISE EXCEPTION 'INVALID_PROMOTION';
  END IF;
  
  -- Calculate discount
  v_discount := calculate_discount(p_promotion_id, v_order.delivery_fee, v_order.items_total);
  
  -- Update order
  UPDATE public.orders
  SET promotion_id = p_promotion_id,
      promotion_code = v_promo.code,
      discount_amount = v_discount,
      total_amount = delivery_fee + items_total - v_discount
  WHERE id = p_order_id
  RETURNING * INTO v_order;
  
  -- Track usage
  INSERT INTO public.user_promotions (user_id, promotion_id, order_id, discount_applied)
  VALUES (auth.uid(), p_promotion_id, p_order_id, v_discount);
  
  -- Update promo usage count
  UPDATE public.promotions
  SET current_uses = current_uses + 1
  WHERE id = p_promotion_id;
  
  RETURN v_order;
END;
$$;

-- ============================================
-- 6. SEED DATA - FREESHIP FIRST ORDER
-- ============================================

INSERT INTO public.promotions (
  market_id, code, name, description,
  promo_type, discount_type, discount_value,
  max_uses_per_user, status
) VALUES (
  'huyen_demo',
  NULL,  -- Auto-apply, không cần code
  'Freeship đơn đầu tiên',
  'Miễn phí giao hàng cho đơn hàng đầu tiên của bạn!',
  'first_order',
  'freeship',
  50000,  -- Max freeship 50k
  1,      -- Mỗi user chỉ 1 lần
  'active'
);

-- Example voucher code
INSERT INTO public.promotions (
  market_id, code, name, description,
  promo_type, discount_type, discount_value,
  min_order_value, max_total_uses, max_uses_per_user, 
  valid_to, status
) VALUES (
  'huyen_demo',
  'CHOQUEMOI',
  'Giảm 10K cho khách mới',
  'Nhập mã CHOQUEMOI để được giảm 10.000đ',
  'voucher',
  'fixed',
  10000,
  30000,   -- Đơn tối thiểu 30k
  100,     -- Tổng 100 lần dùng
  1,       -- Mỗi user 1 lần
  '2026-03-01 00:00:00+07',
  'active'
);

-- ============================================
-- 7. TRIGGER: Auto-update updated_at
-- ============================================

CREATE TRIGGER promotions_updated_at 
  BEFORE UPDATE ON public.promotions 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
