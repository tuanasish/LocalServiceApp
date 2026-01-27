-- ============================================
-- MIGRATION: Tất cả thay đổi SQL trong cuộc trò chuyện này
-- ============================================
-- Chạy file này trên Supabase SQL Editor nếu database đã được tạo trước đó
-- File này chỉ thêm các thành phần mới, không ảnh hưởng đến dữ liệu hiện có
-- 
-- Nội dung migration:
-- 1. Tạo bảng addresses với lat/lng (cho user address management)
-- 2. Thêm indexes, RLS policies, và triggers cho addresses
-- 3. Đảm bảo các Merchant RPC functions đã được tạo
--    (set_menu_override, get_my_shop, get_shop_orders, get_shop_stats)
-- 
-- Lưu ý: Các RPC functions sử dụng CREATE OR REPLACE nên an toàn khi chạy lại
-- ============================================

-- ============================================
-- 1. TẠO BẢNG ADDRESSES
-- ============================================

-- Tạo bảng addresses (nếu chưa tồn tại)
create table if not exists public.addresses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  label text not null,
  details text not null,
  lat double precision,
  lng double precision,
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Thêm lat/lng vào bảng addresses (nếu bảng đã tồn tại nhưng chưa có lat/lng)
alter table public.addresses
  add column if not exists lat double precision,
  add column if not exists lng double precision;

-- ============================================
-- 2. TẠO INDEXES
-- ============================================

create index if not exists addresses_user_idx on public.addresses(user_id);
create index if not exists addresses_default_idx on public.addresses(user_id, is_default) where is_default = true;

-- Index cho tìm kiếm địa chỉ gần (nếu có PostGIS extension)
-- Uncomment nếu bạn đã cài PostGIS extension:
-- create index if not exists addresses_location_idx 
--   on public.addresses using gist (
--     point(lng, lat)
--   ) where lat is not null and lng is not null;

-- ============================================
-- 3. ENABLE ROW LEVEL SECURITY
-- ============================================

alter table public.addresses enable row level security;

-- ============================================
-- 4. TẠO RLS POLICIES
-- ============================================

-- Xóa policies cũ nếu tồn tại (để tránh conflict khi chạy lại)
drop policy if exists "Users read own addresses" on public.addresses;
drop policy if exists "Users insert own addresses" on public.addresses;
drop policy if exists "Users update own addresses" on public.addresses;
drop policy if exists "Users delete own addresses" on public.addresses;
drop policy if exists "Admin read all addresses" on public.addresses;
drop policy if exists "Service role full access addresses" on public.addresses;

-- Tạo lại policies
create policy "Users read own addresses" on public.addresses 
  for select using (user_id = auth.uid());
create policy "Users insert own addresses" on public.addresses 
  for insert with check (user_id = auth.uid());
create policy "Users update own addresses" on public.addresses 
  for update using (user_id = auth.uid());
create policy "Users delete own addresses" on public.addresses 
  for delete using (user_id = auth.uid());
create policy "Admin read all addresses" on public.addresses 
  for select using (has_role('super_admin'));
create policy "Service role full access addresses" on public.addresses 
  for all using (auth.role() = 'service_role');

-- ============================================
-- 5. TẠO TRIGGER
-- ============================================

-- Kiểm tra xem function update_updated_at đã tồn tại chưa
-- (Function này đã có trong schema gốc, chỉ cần tạo trigger mới)

drop trigger if exists addresses_updated_at on public.addresses;
create trigger addresses_updated_at 
  before update on public.addresses 
  for each row execute function public.update_updated_at();

-- ============================================
-- 6. MERCHANT RPC FUNCTIONS
-- ============================================
-- Đảm bảo các merchant RPC functions đã được tạo
-- (Nếu đã chạy 03-RPC-FUNCTIONS.sql thì có thể bỏ qua phần này)

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
-- 7. THÊM COLUMNS VÀO BẢNG SHOPS
-- ============================================
-- Thêm rating, opening_hours, lat, lng vào bảng shops

alter table public.shops
  add column if not exists rating double precision,
  add column if not exists opening_hours text,
  add column if not exists lat double precision,
  add column if not exists lng double precision;

-- ============================================
-- 8. SỬA LỖI SECURITY DEFINER VIEW
-- ============================================

-- ============================================
-- 9. TẠO BẢNG NOTIFICATIONS
-- ============================================

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  title text not null,
  body text not null,
  type text not null,
  is_read boolean not null default false,
  data jsonb,
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
-- Sửa các view có SECURITY DEFINER property (lỗi bảo mật)
-- Chuyển sang SECURITY INVOKER (mặc định, an toàn hơn)

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
-- ✅ Bảng addresses đã được tạo với đầy đủ columns (bao gồm lat/lng)
-- ✅ Indexes đã được tạo để tối ưu query
-- ✅ RLS policies đã được thiết lập để bảo mật
-- ✅ Trigger đã được tạo để tự động cập nhật updated_at
-- ✅ Merchant RPC functions đã được đảm bảo tồn tại:
--    - set_menu_override: Cập nhật giá và availability của sản phẩm
--    - get_my_shop: Lấy shop của merchant hiện tại
--    - get_shop_orders: Lấy danh sách đơn hàng của shop
--    - get_shop_stats: Lấy thống kê đơn hàng của shop
-- ✅ Thêm columns vào bảng shops:
--    - rating: Điểm đánh giá trung bình
--    - opening_hours: Giờ mở cửa
--    - lat, lng: Tọa độ cửa hàng
-- ✅ Sửa lỗi Security Definer View:
--    - v_shop_menu: Đã chuyển sang SECURITY INVOKER
--    - v_available_drivers: Đã chuyển sang SECURITY INVOKER
-- 
-- LƯU Ý:
-- - Các địa chỉ cũ (nếu có) sẽ có lat/lng = NULL
-- - Có thể geocode sau hoặc để user cập nhật qua map picker trong app
-- - Các RPC functions sử dụng CREATE OR REPLACE nên an toàn khi chạy lại
-- 
-- KIỂM TRA SAU KHI CHẠY:
-- SELECT * FROM public.addresses LIMIT 1;  -- Kiểm tra bảng đã tồn tại
-- SELECT routine_name FROM information_schema.routines WHERE routine_schema = 'public' AND routine_name LIKE '%shop%';  -- Kiểm tra merchant functions
-- SELECT * FROM pg_views WHERE schemaname = 'public' AND viewname IN ('v_shop_menu', 'v_available_drivers');  -- Kiểm tra views đã được sửa
-- 
-- ============================================
