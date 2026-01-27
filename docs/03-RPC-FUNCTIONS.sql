-- ============================================
-- CHỢ QUÊ MVP - RPC FUNCTIONS
-- Version: 1.0
-- Run after 02-SCHEMA.sql
-- ============================================

-- ============================================
-- CUSTOMER FUNCTIONS
-- ============================================

-- Create Order (with items for food)
create or replace function public.create_order(
  p_market_id text,
  p_service_type text,
  p_shop_id uuid,
  p_pickup jsonb,
  p_dropoff jsonb,
  p_items jsonb default '[]',
  p_delivery_fee int default 0,
  p_customer_name text default null,
  p_customer_phone text default null,
  p_note text default null
)
returns public.orders
language plpgsql
security definer
as $$
declare
  v_order public.orders;
  v_items_total int := 0;
  v_item jsonb;
begin
  -- Calculate items total
  if jsonb_array_length(p_items) > 0 then
    select coalesce(sum((item->>'subtotal')::int), 0) into v_items_total
    from jsonb_array_elements(p_items) as item;
  end if;

  -- Create order
  insert into public.orders (
    market_id, service_type, shop_id,
    customer_id, pickup, dropoff,
    delivery_fee, items_total, total_amount,
    customer_name, customer_phone, note
  ) values (
    p_market_id, p_service_type, p_shop_id,
    auth.uid(), p_pickup, p_dropoff,
    p_delivery_fee, v_items_total, p_delivery_fee + v_items_total,
    p_customer_name, p_customer_phone, p_note
  )
  returning * into v_order;

  -- Create order items
  if jsonb_array_length(p_items) > 0 then
    for v_item in select * from jsonb_array_elements(p_items)
    loop
      insert into public.order_items (
        order_id, product_id, product_name, quantity, unit_price, subtotal, note
      ) values (
        v_order.id,
        (v_item->>'product_id')::uuid,
        v_item->>'product_name',
        (v_item->>'quantity')::int,
        (v_item->>'unit_price')::int,
        (v_item->>'subtotal')::int,
        v_item->>'note'
      );
    end loop;
  end if;

  -- Log event
  insert into public.order_events (order_id, actor_id, event_type, to_status)
  values (v_order.id, auth.uid(), 'ORDER_CREATED', 'PENDING_CONFIRMATION');

  return v_order;
end;
$$;

-- Cancel Order by Customer
create or replace function public.cancel_order_by_customer(
  p_order_id uuid,
  p_reason text default null
)
returns public.orders
language plpgsql
security definer
as $$
declare
  v_order public.orders;
begin
  select * into v_order from public.orders where id = p_order_id for update;

  if v_order is null then
    raise exception 'ORDER_NOT_FOUND';
  end if;

  if v_order.customer_id <> auth.uid() then
    raise exception 'NOT_ALLOWED';
  end if;

  if v_order.status <> 'PENDING_CONFIRMATION' then
    raise exception 'CANNOT_CANCEL' using detail = 'Chỉ có thể hủy đơn khi chờ xác nhận';
  end if;

  update public.orders
  set status = 'CANCELED',
      canceled_by = auth.uid(),
      canceled_at = now(),
      cancel_reason = p_reason
  where id = p_order_id
  returning * into v_order;

  insert into public.order_events (order_id, actor_id, event_type, from_status, to_status, meta)
  values (p_order_id, auth.uid(), 'CANCELED_BY_CUSTOMER', 'PENDING_CONFIRMATION', 'CANCELED', 
    jsonb_build_object('reason', p_reason));

  return v_order;
end;
$$;

-- ============================================
-- ADMIN FUNCTIONS
-- ============================================

-- Confirm Order
create or replace function public.confirm_order(p_order_id uuid)
returns public.orders
language plpgsql
security definer
as $$
declare
  v_order public.orders;
begin
  if not has_role('super_admin') then
    raise exception 'NOT_ALLOWED';
  end if;

  select * into v_order from public.orders where id = p_order_id for update;

  if v_order is null then
    raise exception 'ORDER_NOT_FOUND';
  end if;

  if v_order.status <> 'PENDING_CONFIRMATION' then
    raise exception 'INVALID_STATUS';
  end if;

  update public.orders
  set status = 'CONFIRMED',
      confirmed_by = auth.uid(),
      confirmed_at = now()
  where id = p_order_id
  returning * into v_order;

  insert into public.order_events (order_id, actor_id, event_type, from_status, to_status)
  values (p_order_id, auth.uid(), 'CONFIRMED_BY_ADMIN', 'PENDING_CONFIRMATION', 'CONFIRMED');

  return v_order;
end;
$$;

-- Assign Driver
create or replace function public.assign_driver(
  p_order_id uuid,
  p_driver_id uuid
)
returns public.orders
language plpgsql
security definer
as $$
declare
  v_order public.orders;
  v_driver public.profiles;
begin
  if not has_role('super_admin') then
    raise exception 'NOT_ALLOWED';
  end if;

  -- Check driver exists and is available
  select * into v_driver from public.profiles 
  where user_id = p_driver_id 
    and 'driver' = any(roles) 
    and status = 'active';

  if v_driver is null then
    raise exception 'DRIVER_NOT_FOUND';
  end if;

  select * into v_order from public.orders where id = p_order_id for update;

  if v_order is null then
    raise exception 'ORDER_NOT_FOUND';
  end if;

  if v_order.status <> 'CONFIRMED' then
    raise exception 'INVALID_STATUS' using detail = 'Chỉ có thể gán đơn đã xác nhận';
  end if;

  -- Update order
  update public.orders
  set status = 'ASSIGNED',
      driver_id = p_driver_id,
      assigned_by = auth.uid(),
      assigned_at = now()
  where id = p_order_id
  returning * into v_order;

  -- Update driver status
  update public.profiles
  set driver_status = 'busy'
  where user_id = p_driver_id;

  insert into public.order_events (order_id, actor_id, event_type, from_status, to_status, meta)
  values (p_order_id, auth.uid(), 'ASSIGNED_BY_ADMIN', 'CONFIRMED', 'ASSIGNED',
    jsonb_build_object('driver_id', p_driver_id));

  return v_order;
end;
$$;

-- Reassign Driver
create or replace function public.reassign_driver(
  p_order_id uuid,
  p_new_driver_id uuid,
  p_reason text default null
)
returns public.orders
language plpgsql
security definer
as $$
declare
  v_order public.orders;
  v_old_driver_id uuid;
begin
  if not has_role('super_admin') then
    raise exception 'NOT_ALLOWED';
  end if;

  select * into v_order from public.orders where id = p_order_id for update;

  if v_order is null then
    raise exception 'ORDER_NOT_FOUND';
  end if;

  if v_order.status not in ('ASSIGNED', 'PICKED_UP') then
    raise exception 'INVALID_STATUS';
  end if;

  v_old_driver_id := v_order.driver_id;

  -- Update order
  update public.orders
  set driver_id = p_new_driver_id,
      assigned_by = auth.uid(),
      assigned_at = now()
  where id = p_order_id
  returning * into v_order;

  -- Update old driver status (if no other active orders)
  update public.profiles
  set driver_status = 'online'
  where user_id = v_old_driver_id
    and not exists (
      select 1 from public.orders 
      where driver_id = v_old_driver_id 
        and status in ('ASSIGNED', 'PICKED_UP')
        and id <> p_order_id
    );

  -- Update new driver status
  update public.profiles
  set driver_status = 'busy'
  where user_id = p_new_driver_id;

  insert into public.order_events (order_id, actor_id, event_type, meta)
  values (p_order_id, auth.uid(), 'REASSIGNED_BY_ADMIN',
    jsonb_build_object('old_driver_id', v_old_driver_id, 'new_driver_id', p_new_driver_id, 'reason', p_reason));

  return v_order;
end;
$$;

-- Cancel Order by Admin
create or replace function public.cancel_order_by_admin(
  p_order_id uuid,
  p_reason text
)
returns public.orders
language plpgsql
security definer
as $$
declare
  v_order public.orders;
  v_old_status text;
begin
  if not has_role('super_admin') then
    raise exception 'NOT_ALLOWED';
  end if;

  select * into v_order from public.orders where id = p_order_id for update;

  if v_order is null then
    raise exception 'ORDER_NOT_FOUND';
  end if;

  if v_order.status in ('COMPLETED', 'CANCELED') then
    raise exception 'INVALID_STATUS';
  end if;

  v_old_status := v_order.status;

  update public.orders
  set status = 'CANCELED',
      canceled_by = auth.uid(),
      canceled_at = now(),
      cancel_reason = p_reason
  where id = p_order_id
  returning * into v_order;

  -- Release driver if assigned
  if v_order.driver_id is not null then
    update public.profiles
    set driver_status = 'online'
    where user_id = v_order.driver_id
      and not exists (
        select 1 from public.orders 
        where driver_id = v_order.driver_id 
          and status in ('ASSIGNED', 'PICKED_UP')
          and id <> p_order_id
      );
  end if;

  insert into public.order_events (order_id, actor_id, event_type, from_status, to_status, meta)
  values (p_order_id, auth.uid(), 'CANCELED_BY_ADMIN', v_old_status, 'CANCELED',
    jsonb_build_object('reason', p_reason));

  return v_order;
end;
$$;

-- ============================================
-- DRIVER FUNCTIONS
-- ============================================

-- Go Online
create or replace function public.driver_go_online()
returns public.profiles
language plpgsql
security definer
as $$
declare
  v_profile public.profiles;
begin
  update public.profiles
  set driver_status = 'online'
  where user_id = auth.uid()
    and 'driver' = any(roles)
  returning * into v_profile;

  if v_profile is null then
    raise exception 'NOT_A_DRIVER';
  end if;

  return v_profile;
end;
$$;

-- Go Offline
create or replace function public.driver_go_offline()
returns public.profiles
language plpgsql
security definer
as $$
declare
  v_profile public.profiles;
  v_active_orders int;
begin
  -- Check for active orders
  select count(*) into v_active_orders
  from public.orders
  where driver_id = auth.uid()
    and status in ('ASSIGNED', 'PICKED_UP');

  if v_active_orders > 0 then
    raise exception 'HAS_ACTIVE_ORDERS' using detail = 'Hoàn thành đơn trước khi offline';
  end if;

  update public.profiles
  set driver_status = 'offline'
  where user_id = auth.uid()
  returning * into v_profile;

  -- Clear location
  delete from public.driver_locations where driver_id = auth.uid();

  return v_profile;
end;
$$;

-- Update Order Status by Driver
create or replace function public.update_order_status(
  p_order_id uuid,
  p_new_status text
)
returns public.orders
language plpgsql
security definer
as $$
declare
  v_order public.orders;
  v_allowed boolean;
begin
  select * into v_order from public.orders where id = p_order_id for update;

  if v_order is null then
    raise exception 'ORDER_NOT_FOUND';
  end if;

  if v_order.driver_id <> auth.uid() then
    raise exception 'NOT_ALLOWED';
  end if;

  -- Check valid transitions
  v_allowed := case
    when v_order.status = 'ASSIGNED' and p_new_status = 'PICKED_UP' then true
    when v_order.status = 'PICKED_UP' and p_new_status = 'COMPLETED' then true
    else false
  end;

  if not v_allowed then
    raise exception 'INVALID_TRANSITION';
  end if;

  update public.orders
  set status = p_new_status,
      picked_up_at = case when p_new_status = 'PICKED_UP' then now() else picked_up_at end,
      completed_at = case when p_new_status = 'COMPLETED' then now() else completed_at end
  where id = p_order_id
  returning * into v_order;

  -- If completed, release driver
  if p_new_status = 'COMPLETED' then
    update public.profiles
    set driver_status = 'online'
    where user_id = auth.uid()
      and not exists (
        select 1 from public.orders 
        where driver_id = auth.uid() 
          and status in ('ASSIGNED', 'PICKED_UP')
          and id <> p_order_id
      );
    
    -- Clear tracking
    update public.driver_locations
    set order_id = null
    where driver_id = auth.uid() and order_id = p_order_id;
  end if;

  insert into public.order_events (order_id, actor_id, event_type, from_status, to_status)
  values (p_order_id, auth.uid(), 'STATUS_UPDATED_BY_DRIVER', v_order.status, p_new_status);

  return v_order;
end;
$$;

-- Update Driver Location
create or replace function public.update_driver_location(
  p_order_id uuid,
  p_lat double precision,
  p_lng double precision,
  p_heading double precision default null,
  p_speed double precision default null,
  p_accuracy double precision default null
)
returns public.driver_locations
language plpgsql
security definer
as $$
declare
  v_location public.driver_locations;
begin
  insert into public.driver_locations (driver_id, order_id, lat, lng, heading, speed, accuracy, updated_at)
  values (auth.uid(), p_order_id, p_lat, p_lng, p_heading, p_speed, p_accuracy, now())
  on conflict (driver_id)
  do update set
    order_id = excluded.order_id,
    lat = excluded.lat,
    lng = excluded.lng,
    heading = excluded.heading,
    speed = excluded.speed,
    accuracy = excluded.accuracy,
    updated_at = now()
  returning * into v_location;

  return v_location;
end;
$$;

-- Thống kê đơn hàng của driver
create or replace function public.get_driver_stats(
  p_driver_id uuid,
  p_date_from timestamptz default null,
  p_date_to timestamptz default null
)
returns jsonb
language plpgsql
security definer
as $$
declare
  v_stats jsonb;
begin
  -- Check driver owns this or is admin
  if p_driver_id != auth.uid() and not has_role('super_admin') then
    raise exception 'NOT_ALLOWED';
  end if;
  
  select jsonb_build_object(
    'total_orders', count(*) filter (where status = 'COMPLETED'),
    'today_orders', count(*) filter (
      where status = 'COMPLETED' 
      and completed_at::date = current_date
    ),
    'active_orders', count(*) filter (where status in ('ASSIGNED', 'PICKED_UP')),
    'total_earnings', coalesce(sum(delivery_fee) filter (where status = 'COMPLETED'), 0),
    'today_earnings', coalesce(sum(delivery_fee) filter (
      where status = 'COMPLETED' 
      and completed_at::date = current_date
    ), 0)
  ) into v_stats
  from public.orders
  where driver_id = p_driver_id
    and (p_date_from is null or created_at >= p_date_from)
    and (p_date_to is null or created_at <= p_date_to);
  
  return v_stats;
end;
$$;

-- ============================================
-- MERCHANT FUNCTIONS
-- ============================================

-- Set Menu Override
create or replace function public.set_menu_override(
  p_shop_id uuid,
  p_product_id uuid,
  p_price_override int default null,
  p_is_available boolean default true
)
returns public.shop_product_overrides
language plpgsql
security definer
as $$
declare
  v_override public.shop_product_overrides;
begin
  if not is_shop_owner(p_shop_id) and not has_role('super_admin') then
    raise exception 'NOT_ALLOWED';
  end if;

  insert into public.shop_product_overrides (shop_id, product_id, price_override, is_available)
  values (p_shop_id, p_product_id, p_price_override, p_is_available)
  on conflict (shop_id, product_id)
  do update set
    price_override = excluded.price_override,
    is_available = excluded.is_available,
    updated_at = now()
  returning * into v_override;

  return v_override;
end;
$$;

-- Thêm sản phẩm vào shop menu (từ catalog)
create or replace function public.add_product_to_shop(
  p_shop_id uuid,
  p_product_id uuid
)
returns public.shop_products
language plpgsql
security definer
as $$
declare
  v_shop_product public.shop_products;
begin
  if not is_shop_owner(p_shop_id) and not has_role('super_admin') then
    raise exception 'NOT_ALLOWED';
  end if;

  insert into public.shop_products (shop_id, product_id, is_listed)
  values (p_shop_id, p_product_id, true)
  on conflict (shop_id, product_id)
  do update set is_listed = true
  returning * into v_shop_product;

  return v_shop_product;
end;
$$;

-- Xóa/Ẩn sản phẩm khỏi shop menu
create or replace function public.remove_product_from_shop(
  p_shop_id uuid,
  p_product_id uuid
)
returns boolean
language plpgsql
security definer
as $$
begin
  if not is_shop_owner(p_shop_id) and not has_role('super_admin') then
    raise exception 'NOT_ALLOWED';
  end if;

  -- Thực tế ta sẽ set is_listed = false để giữ history, hoặc xóa hẳn. 
  -- MVP này chọn xóa hẳn junction record cho sạch.
  delete from public.shop_products
  where shop_id = p_shop_id and product_id = p_product_id;
  
  -- Xóa luôn override nếu có
  delete from public.shop_product_overrides
  where shop_id = p_shop_id and product_id = p_product_id;

  return true;
end;
$$;

-- Lấy shop của merchant hiện tại
create or replace function public.get_my_shop()
returns public.shops
language plpgsql
security definer
as $$
declare
  v_shop public.shops;
begin
  select * into v_shop
  from public.shops
  where owner_user_id = auth.uid()
    and status = 'active'
  limit 1;
  
  if v_shop is null then
    raise exception 'NO_SHOP_FOUND';
  end if;
  
  return v_shop;
end;
$$;

-- Lấy đơn hàng của shop (merchant)
create or replace function public.get_shop_orders(
  p_shop_id uuid,
  p_status text default null,
  p_limit int default 50
)
returns table (
  id uuid,
  order_number int,
  customer_id uuid,
  customer_name text,
  customer_phone text,
  status text,
  items_total int,
  delivery_fee int,
  total_amount int,
  discount_amount int,
  created_at timestamptz,
  confirmed_at timestamptz,
  pickup jsonb,
  dropoff jsonb,
  note text
)
language plpgsql
security definer
as $$
begin
  -- Check merchant owns this shop
  if not is_shop_owner(p_shop_id) and not has_role('super_admin') then
    raise exception 'NOT_ALLOWED';
  end if;
  
  return query
  select 
    o.id,
    o.order_number,
    o.customer_id,
    o.customer_name,
    o.customer_phone,
    o.status,
    o.items_total,
    o.delivery_fee,
    o.total_amount,
    o.discount_amount,
    o.created_at,
    o.confirmed_at,
    o.pickup,
    o.dropoff,
    o.note
  from public.orders o
  where o.shop_id = p_shop_id
    and (p_status is null or o.status = p_status)
    and o.status != 'CANCELED'
  order by o.created_at desc
  limit p_limit;
end;
$$;

-- Thống kê đơn hàng của shop
create or replace function public.get_shop_stats(
  p_shop_id uuid,
  p_date_from timestamptz default null,
  p_date_to timestamptz default null
)
returns jsonb
language plpgsql
security definer
as $$
declare
  v_stats jsonb;
begin
  if not is_shop_owner(p_shop_id) and not has_role('super_admin') then
    raise exception 'NOT_ALLOWED';
  end if;
  
  select jsonb_build_object(
    'total_orders', count(*),
    'pending_orders', count(*) filter (where status = 'PENDING_CONFIRMATION'),
    'preparing_orders', count(*) filter (where status = 'CONFIRMED'),
    'completed_orders', count(*) filter (where status = 'COMPLETED'),
    'total_revenue', coalesce(sum(total_amount) filter (where status = 'COMPLETED'), 0),
    'today_revenue', coalesce(sum(total_amount) filter (
      where status = 'COMPLETED' 
      and completed_at::date = current_date
    ), 0)
  ) into v_stats
  from public.orders
  where shop_id = p_shop_id
    and (p_date_from is null or created_at >= p_date_from)
    and (p_date_to is null or created_at <= p_date_to);
  
  return v_stats;
end;
$$;

-- Cập nhật profile shop (merchant)
create or replace function public.update_shop_profile(
  p_shop_id uuid,
  p_name text,
  p_phone text,
  p_address text,
  p_opening_hours text
)
returns public.shops
language plpgsql
security definer
as $$
declare
  v_shop public.shops;
begin
  if not is_shop_owner(p_shop_id) and not has_role('super_admin') then
    raise exception 'NOT_ALLOWED';
  end if;

  update public.shops
  set name = p_name,
      phone = p_phone,
      address = p_address,
      opening_hours = p_opening_hours,
      updated_at = now()
  where id = p_shop_id
  returning * into v_shop;

  return v_shop;
end;
$$;

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================

-- Get Config
create or replace function public.get_config(p_market_id text)
returns public.app_configs
language sql
stable
as $$
  select * from public.app_configs
  where market_id = p_market_id
  limit 1;
$$;

-- Get Fixed Price
create or replace function public.get_fixed_price(
  p_market_id text,
  p_service_type text,
  p_zone_name text
)
returns int
language sql
stable
as $$
  select price from public.fixed_pricing
  where market_id = p_market_id
    and service_type = p_service_type
    and zone_name = p_zone_name
  limit 1;
$$;

-- ============================================
-- NOTIFICATION FUNCTIONS
-- ============================================

-- Function để tạo notification (sẽ được gọi từ backend/service)
create or replace function public.create_notification(
  p_user_id uuid,
  p_title text,
  p_body text,
  p_type text,
  p_data jsonb default null
) returns uuid as $$
declare
  v_notification_id uuid;
begin
  insert into public.notifications (
    user_id, title, body, type, data
  ) values (
    p_user_id, p_title, p_body, p_type, p_data
  ) returning id into v_notification_id;

  -- TODO: Trigger FCM push notification từ backend
  -- (Cần implement trong backend service, không phải SQL)

  return v_notification_id;
end;
$$ language plpgsql security definer;

-- Function để tạo notification cho nhiều users (broadcast)
create or replace function public.create_broadcast_notification(
  p_user_ids uuid[],
  p_title text,
  p_body text,
  p_type text,
  p_data jsonb default null
) returns int as $$
declare
  v_count int;
begin
  insert into public.notifications (
    user_id, title, body, type, data
  )
  select unnest(p_user_ids), p_title, p_body, p_type, p_data;

  get diagnostics v_count = row_count;
  return v_count;
end;
$$ language plpgsql security definer;
