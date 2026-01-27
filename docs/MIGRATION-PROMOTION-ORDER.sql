-- ============================================
-- MIGRATION: Thêm Promotion Support vào create_order
-- Version: 1.0
-- Run after 03-RPC-FUNCTIONS.sql và 08-PROMOTION-SCHEMA.sql
-- ============================================

-- Cập nhật RPC function create_order để hỗ trợ promotion
CREATE OR REPLACE FUNCTION public.create_order(
  p_market_id text,
  p_service_type text,
  p_shop_id uuid,
  p_pickup jsonb,
  p_dropoff jsonb,
  p_items jsonb default '[]',
  p_delivery_fee int default 0,
  p_customer_name text default null,
  p_customer_phone text default null,
  p_note text default null,
  p_promotion_id uuid default null,
  p_discount_amount int default 0
)
RETURNS public.orders
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_order public.orders;
  v_items_total int := 0;
  v_item jsonb;
  v_total_amount int;
BEGIN
  -- Calculate items total
  IF jsonb_array_length(p_items) > 0 THEN
    SELECT COALESCE(SUM((item->>'subtotal')::int), 0) INTO v_items_total
    FROM jsonb_array_elements(p_items) AS item;
  END IF;

  -- Calculate total with discount
  v_total_amount := p_delivery_fee + v_items_total - p_discount_amount;
  IF v_total_amount < 0 THEN
    v_total_amount := 0; -- Ensure non-negative
  END IF;

  -- Create order
  INSERT INTO public.orders (
    market_id, service_type, shop_id,
    customer_id, pickup, dropoff,
    delivery_fee, items_total, total_amount,
    customer_name, customer_phone, note,
    promotion_id, discount_amount
  ) VALUES (
    p_market_id, p_service_type, p_shop_id,
    auth.uid(), p_pickup, p_dropoff,
    p_delivery_fee, v_items_total, v_total_amount,
    p_customer_name, p_customer_phone, p_note,
    p_promotion_id, p_discount_amount
  )
  RETURNING * INTO v_order;

  -- Create order items
  IF jsonb_array_length(p_items) > 0 THEN
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
      INSERT INTO public.order_items (
        order_id, product_id, product_name, quantity, unit_price, subtotal, note
      ) VALUES (
        v_order.id,
        (v_item->>'product_id')::uuid,
        v_item->>'product_name',
        (v_item->>'quantity')::int,
        (v_item->>'unit_price')::int,
        (v_item->>'subtotal')::int,
        v_item->>'note'
      );
    END LOOP;
  END IF;

  -- Nếu có promotion, track usage
  IF p_promotion_id IS NOT NULL AND p_discount_amount > 0 THEN
    -- Lấy promotion code
    DECLARE
      v_promo_code text;
    BEGIN
      SELECT code INTO v_promo_code FROM public.promotions WHERE id = p_promotion_id;
      
      -- Update order với promotion_code
      UPDATE public.orders
      SET promotion_code = v_promo_code
      WHERE id = v_order.id
      RETURNING * INTO v_order;
      
      -- Track usage trong user_promotions
      INSERT INTO public.user_promotions (user_id, promotion_id, order_id, discount_applied)
      VALUES (auth.uid(), p_promotion_id, v_order.id, p_discount_amount)
      ON CONFLICT (user_id, promotion_id, order_id) DO NOTHING;
      
      -- Update promo usage count
      UPDATE public.promotions
      SET current_uses = current_uses + 1
      WHERE id = p_promotion_id;
    END;
  END IF;

  -- Log event
  INSERT INTO public.order_events (order_id, actor_id, event_type, to_status)
  VALUES (v_order.id, auth.uid(), 'ORDER_CREATED', 'PENDING_CONFIRMATION');

  RETURN v_order;
END;
$$;
