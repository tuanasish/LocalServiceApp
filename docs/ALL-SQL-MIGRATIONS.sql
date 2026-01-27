-- ============================================
-- TẤT CẢ SQL MIGRATIONS - CHẠY MỘT LẦN
-- ============================================
-- File này chứa TẤT CẢ các thay đổi SQL trong cuộc trò chuyện này
-- Chạy file này trong Supabase SQL Editor để cập nhật database
-- ============================================

-- ============================================
-- 1. THÊM COLUMNS VÀO BẢNG SHOPS
-- ============================================

alter table public.shops
  add column if not exists rating double precision,
  add column if not exists opening_hours text,
  add column if not exists lat double precision,
  add column if not exists lng double precision;

-- ============================================
-- 2. TẠO BẢNG NOTIFICATIONS
-- ============================================

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  title text not null,
  body text not null,
  type text not null, -- 'order', 'promo', 'system'
  is_read boolean not null default false,
  data jsonb, -- Additional data: {order_id, promotion_id, etc.}
  created_at timestamptz not null default now(),
  read_at timestamptz
);

create index if not exists notifications_user_idx on public.notifications(user_id, created_at desc);
create index if not exists notifications_unread_idx on public.notifications(user_id, is_read) where is_read = false;

alter table public.notifications enable row level security;

drop policy if exists "Users read own notifications" on public.notifications;
drop policy if exists "Users update own notifications" on public.notifications;
drop policy if exists "Service role full access" on public.notifications;

create policy "Users read own notifications" on public.notifications 
  for select using (user_id = auth.uid());

create policy "Users update own notifications" on public.notifications 
  for update using (user_id = auth.uid());

create policy "Service role full access" on public.notifications 
  for all using (auth.role() = 'service_role');

-- ============================================
-- 3. MERCHANT RPC FUNCTIONS
-- ============================================

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

-- ============================================
-- 4. DRIVER RPC FUNCTIONS
-- ============================================

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
-- 5. NOTIFICATION RPC FUNCTIONS
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

-- ============================================
-- 6. SỬA VIEWS - SECURITY INVOKER
-- ============================================

-- Sửa view v_shop_menu: Reset security_invoker về mặc định
alter view if exists public.v_shop_menu set (security_invoker = on);

-- Nếu ALTER VIEW không hoạt động, tạo lại view
create or replace view public.v_shop_menu as
select
  sp.shop_id,
  p.id as product_id,
  p.name,
  p.description,
  p.image_path,
  p.category,
  p.base_price,
  coalesce(o.price_override, p.base_price) as effective_price,
  coalesce(o.is_available, true) as is_available,
  sp.is_listed
from public.shop_products sp
join public.products p on p.id = sp.product_id and p.status = 'active'
left join public.shop_product_overrides o on o.shop_id = sp.shop_id and o.product_id = sp.product_id
where sp.is_listed = true;

-- Sửa view v_available_drivers: Reset security_invoker về mặc định
alter view if exists public.v_available_drivers set (security_invoker = on);

-- Nếu ALTER VIEW không hoạt động, tạo lại view
create or replace view public.v_available_drivers as
select 
  p.user_id,
  p.full_name,
  p.phone,
  p.market_id,
  dl.lat,
  dl.lng,
  dl.updated_at as location_updated_at
from public.profiles p
left join public.driver_locations dl on dl.driver_id = p.user_id
where 'driver' = any(p.roles)
  and p.status = 'active'
  and p.driver_status = 'online';

-- ============================================
-- HOÀN TẤT
-- ============================================
-- 
-- TÓM TẮT CÁC THAY ĐỔI:
-- ✅ Thêm columns vào bảng shops: rating, opening_hours, lat, lng
-- ✅ Tạo bảng notifications với indexes và RLS policies
-- ✅ Tạo Merchant RPC functions: get_my_shop, get_shop_orders, get_shop_stats
-- ✅ Tạo Driver RPC function: get_driver_stats
-- ✅ Tạo Notification RPC functions: create_notification, create_broadcast_notification
-- ✅ Sửa views: v_shop_menu, v_available_drivers (SECURITY INVOKER)
-- 
-- KIỂM TRA SAU KHI CHẠY:
-- SELECT column_name FROM information_schema.columns WHERE table_name = 'shops' AND column_name IN ('rating', 'opening_hours', 'lat', 'lng');
-- SELECT * FROM public.notifications LIMIT 1;
-- SELECT routine_name FROM information_schema.routines WHERE routine_schema = 'public' AND routine_name IN ('get_my_shop', 'get_shop_orders', 'get_shop_stats', 'get_driver_stats', 'create_notification', 'create_broadcast_notification');
-- SELECT viewname FROM pg_views WHERE schemaname = 'public' AND viewname IN ('v_shop_menu', 'v_available_drivers');
-- ============================================
