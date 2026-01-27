-- ============================================
-- CHỢ QUÊ MVP - SUPABASE SCHEMA
-- Version: 1.0
-- Run this in Supabase SQL Editor
-- ============================================

-- ============================================
-- 1. CORE TABLES
-- ============================================

-- Profiles (extends auth.users)
create table public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  phone text,
  full_name text,
  roles text[] not null default array['customer'],
  market_id text not null default 'default',
  driver_status text default 'offline', -- offline/online/busy
  device_id text,
  fcm_token text,
  is_guest boolean default false,
  status text not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index profiles_market_idx on public.profiles(market_id);
create index profiles_roles_idx on public.profiles using gin(roles);
create index profiles_driver_status_idx on public.profiles(driver_status) where 'driver' = any(roles);
create index profiles_device_idx on public.profiles(device_id);

-- Shops
create table public.shops (
  id uuid primary key default gen_random_uuid(),
  market_id text not null,
  name text not null,
  address text,
  phone text,
  owner_user_id uuid references public.profiles(user_id),
  rating double precision,
  opening_hours text,
  lat double precision,
  lng double precision,
  status text not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index shops_market_idx on public.shops(market_id);

-- Products (master catalog - admin manages)
create table public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  image_path text,
  base_price int not null,
  category text,
  status text not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Shop Products (which products each shop sells)
create table public.shop_products (
  shop_id uuid not null references public.shops(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  is_listed boolean not null default true,
  created_at timestamptz not null default now(),
  primary key (shop_id, product_id)
);

-- Shop Product Overrides (merchant can override price & availability)
create table public.shop_product_overrides (
  shop_id uuid not null references public.shops(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  price_override int,
  is_available boolean not null default true,
  updated_at timestamptz not null default now(),
  primary key (shop_id, product_id)
);

-- Preset Locations (for preset address mode)
create table public.preset_locations (
  id uuid primary key default gen_random_uuid(),
  market_id text not null,
  label text not null,
  address text,
  lat double precision not null,
  lng double precision not null,
  location_type text default 'general', -- general/restaurant/landmark
  status text not null default 'active',
  sort_order int default 0,
  created_at timestamptz not null default now()
);

create index preset_locations_market_idx on public.preset_locations(market_id, status);

-- Fixed Pricing (for fixed pricing mode)
create table public.fixed_pricing (
  id uuid primary key default gen_random_uuid(),
  market_id text not null,
  service_type text not null, -- food/ride/delivery
  zone_name text not null, -- "Nội xã", "Liên xã", etc
  price int not null,
  created_at timestamptz not null default now()
);

create index fixed_pricing_lookup_idx on public.fixed_pricing(market_id, service_type);

-- User Addresses (for user address management)
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

create index addresses_user_idx on public.addresses(user_id);
create index addresses_default_idx on public.addresses(user_id, is_default) where is_default = true;

-- Tạo index để tìm kiếm địa chỉ gần (nếu có PostGIS extension)
-- create index if not exists addresses_location_idx 
--   on public.addresses using gist (
--     point(lng, lat)
--   ) where lat is not null and lng is not null;

-- ============================================
-- 3. ORDERS
-- ============================================

create table public.orders (
  id uuid primary key default gen_random_uuid(),
  order_number serial,
  market_id text not null,
  service_type text not null, -- food/ride/delivery
  
  -- Actors
  customer_id uuid not null references public.profiles(user_id),
  driver_id uuid references public.profiles(user_id),
  shop_id uuid references public.shops(id),
  
  -- Status
  status text not null default 'PENDING_CONFIRMATION',
  
  -- Locations (JSONB: {label, address, lat, lng})
  pickup jsonb not null,
  dropoff jsonb not null,
  
  -- Pricing
  delivery_fee int not null default 0,
  items_total int not null default 0,
  total_amount int not null default 0,
  pricing_mode text default 'fixed',
  pricing_details jsonb default '{}',
  
  -- Customer info (for guest)
  customer_name text,
  customer_phone text,
  note text,
  
  -- Timestamps
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  confirmed_at timestamptz,
  assigned_at timestamptz,
  picked_up_at timestamptz,
  completed_at timestamptz,
  canceled_at timestamptz,
  
  -- Actors for actions
  confirmed_by uuid references public.profiles(user_id),
  assigned_by uuid references public.profiles(user_id),
  canceled_by uuid references public.profiles(user_id),
  cancel_reason text
);

create index orders_market_status_idx on public.orders(market_id, status);
create index orders_customer_idx on public.orders(customer_id);
create index orders_driver_idx on public.orders(driver_id);
create index orders_created_idx on public.orders(created_at desc);

-- Order Items (for food orders)
create table public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  product_id uuid references public.products(id),
  product_name text not null, -- snapshot
  quantity int not null default 1,
  unit_price int not null,
  subtotal int not null,
  note text,
  created_at timestamptz not null default now()
);

create index order_items_order_idx on public.order_items(order_id);

-- Order Events (audit log)
create table public.order_events (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  actor_id uuid references public.profiles(user_id),
  event_type text not null,
  from_status text,
  to_status text,
  meta jsonb default '{}',
  created_at timestamptz not null default now()
);

create index order_events_order_idx on public.order_events(order_id);

-- ============================================
-- 4. DRIVER LOCATION
-- ============================================

create table public.driver_locations (
  driver_id uuid primary key references public.profiles(user_id) on delete cascade,
  order_id uuid references public.orders(id) on delete set null,
  lat double precision not null,
  lng double precision not null,
  heading double precision,
  speed double precision,
  accuracy double precision,
  updated_at timestamptz not null default now()
);

-- ============================================
-- 5. APP CONFIG
-- ============================================

create table public.app_configs (
  id uuid primary key default gen_random_uuid(),
  market_id text not null unique,
  
  -- Version control
  min_app_version int default 1,
  max_app_version int,
  config_version int default 1,
  
  -- Kill switch
  kill_switch boolean default false,
  maintenance_message text,
  
  -- Feature flags
  flags jsonb not null default '{
    "auth_mode": "guest",
    "address_mode": "preset",
    "pricing_mode": "fixed",
    "tracking_mode": "status",
    "dispatch_mode": "admin"
  }',
  
  -- Rules
  rules jsonb not null default '{
    "guest_max_orders": 10,
    "guest_session_days": 30,
    "require_phone_for_order": true
  }',
  
  -- Limits
  limits jsonb not null default '{
    "location_interval_sec": 30,
    "location_distance_filter_m": 50,
    "order_timeout_minutes": 30
  }',
  
  updated_at timestamptz not null default now()
);

-- ============================================
-- 6. PROMOTIONS (Freeship + Voucher)
-- ============================================

-- Promotions table
create table public.promotions (
  id uuid primary key default gen_random_uuid(),
  market_id text not null,
  
  -- Identification
  code text unique,                    -- NULL = tự động apply (first_order)
  name text not null,                  -- "Freeship đơn đầu", "GIAM10K"
  description text,
  
  -- Type & Discount
  promo_type text not null,            -- 'first_order', 'voucher', 'all_orders'
  discount_type text not null,         -- 'freeship', 'fixed', 'percent'
  discount_value int not null,         -- VD: 15000 (freeship max), 10000 (fixed), 10 (percent)
  max_discount int,                    -- Cap cho percent: VD max 20000
  
  -- Conditions
  min_order_value int default 0,       -- Đơn tối thiểu để apply
  service_type text default 'food',    -- 'food' only for this app
  
  -- Usage limits
  max_total_uses int,                  -- NULL = unlimited
  max_uses_per_user int default 1,     -- Mỗi user dùng được bao nhiêu lần
  current_uses int default 0,
  
  -- Validity
  valid_from timestamptz default now(),
  valid_to timestamptz,
  status text default 'active',        -- 'active', 'paused', 'expired'
  
  -- Metadata
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index promotions_market_idx on public.promotions(market_id, status);
create index promotions_code_idx on public.promotions(code) where code is not null;
create index promotions_type_idx on public.promotions(promo_type, status);

-- User promotions (usage tracking)
create table public.user_promotions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  promotion_id uuid not null references public.promotions(id) on delete cascade,
  order_id uuid references public.orders(id) on delete set null,
  discount_applied int not null,       -- Số tiền thực tế được giảm
  used_at timestamptz default now(),
  
  -- Prevent duplicate usage based on promo rules
  unique(user_id, promotion_id, order_id)
);

create index user_promotions_user_idx on public.user_promotions(user_id);
create index user_promotions_promo_idx on public.user_promotions(promotion_id);

-- Link promotions into orders
alter table public.orders
  add column if not exists promotion_id uuid references public.promotions(id);

alter table public.orders
  add column if not exists promotion_code text;

alter table public.orders
  add column if not exists discount_amount int default 0;

-- Helper: check if user is eligible for first order promo
create or replace function public.is_first_order(p_user_id uuid)
returns boolean
language sql stable security definer
as $$
  select not exists (
    select 1 from public.orders
    where customer_id = p_user_id
      and status = 'COMPLETED'
  );
$$;

-- Helper: get applicable promotions for user
create or replace function public.get_available_promotions(
  p_user_id uuid,
  p_market_id text,
  p_order_value int
)
returns table (
  id uuid,
  code text,
  name text,
  discount_type text,
  discount_value int,
  max_discount int
)
language plpgsql security definer
as $$
begin
  return query
  select 
    p.id,
    p.code,
    p.name,
    p.discount_type,
    p.discount_value,
    p.max_discount
  from public.promotions p
  where p.market_id = p_market_id
    and p.status = 'active'
    and (p.valid_from is null or p.valid_from <= now())
    and (p.valid_to is null or p.valid_to > now())
    and (p.min_order_value <= p_order_value)
    and (p.max_total_uses is null or p.current_uses < p.max_total_uses)
    -- Check user hasn't exceeded their limit
    and (
      select count(*) from public.user_promotions up 
      where up.user_id = p_user_id and up.promotion_id = p.id
    ) < p.max_uses_per_user
    -- Special check for first_order type
    and (
      p.promo_type != 'first_order' 
      or is_first_order(p_user_id)
    );
end;
$$;

-- Helper: calculate discount amount
create or replace function public.calculate_discount(
  p_promotion_id uuid,
  p_delivery_fee int,
  p_items_total int
)
returns int
language plpgsql stable
as $$
declare
  v_promo public.promotions;
  v_discount int;
begin
  select * into v_promo from public.promotions where id = p_promotion_id;
  
  if v_promo is null then
    return 0;
  end if;
  
  case v_promo.discount_type
    when 'freeship' then
      -- Freeship: giảm tối đa = delivery_fee, nhưng không quá discount_value
      v_discount := least(p_delivery_fee, v_promo.discount_value);
    when 'fixed' then
      -- Fixed: giảm cố định
      v_discount := v_promo.discount_value;
    when 'percent' then
      -- Percent: % của tổng đơn, cap bởi max_discount
      v_discount := (p_items_total * v_promo.discount_value / 100);
      if v_promo.max_discount is not null then
        v_discount := least(v_discount, v_promo.max_discount);
      end if;
  end case;
  
  return coalesce(v_discount, 0);
end;
$$;

-- Apply promotion to order
create or replace function public.apply_promotion(
  p_order_id uuid,
  p_promotion_id uuid
)
returns public.orders
language plpgsql security definer
as $$
declare
  v_order public.orders;
  v_promo public.promotions;
  v_discount int;
begin
  -- Get order
  select * into v_order from public.orders where id = p_order_id for update;
  if v_order is null then
    raise exception 'ORDER_NOT_FOUND';
  end if;
  
  -- Check order belongs to current user
  if v_order.customer_id != auth.uid() then
    raise exception 'NOT_ALLOWED';
  end if;
  
  -- Get promotion
  select * into v_promo from public.promotions where id = p_promotion_id;
  if v_promo is null or v_promo.status != 'active' then
    raise exception 'INVALID_PROMOTION';
  end if;
  
  -- Calculate discount
  v_discount := calculate_discount(p_promotion_id, v_order.delivery_fee, v_order.items_total);
  
  -- Update order
  update public.orders
  set promotion_id = p_promotion_id,
      promotion_code = v_promo.code,
      discount_amount = v_discount,
      total_amount = delivery_fee + items_total - v_discount
  where id = p_order_id
  returning * into v_order;
  
  -- Track usage
  insert into public.user_promotions (user_id, promotion_id, order_id, discount_applied)
  values (auth.uid(), p_promotion_id, p_order_id, v_discount);
  
  -- Update promo usage count
  update public.promotions
  set current_uses = current_uses + 1
  where id = p_promotion_id;
  
  return v_order;
end;
$$;

-- Seed data: freeship first order + example voucher
insert into public.promotions (
  market_id, code, name, description,
  promo_type, discount_type, discount_value,
  max_uses_per_user, status
) values (
  'huyen_demo',
  null,  -- Auto-apply, không cần code
  'Freeship đơn đầu tiên',
  'Miễn phí giao hàng cho đơn hàng đầu tiên của bạn!',
  'first_order',
  'freeship',
  50000,  -- Max freeship 50k
  1,      -- Mỗi user chỉ 1 lần
  'active'
);

insert into public.promotions (
  market_id, code, name, description,
  promo_type, discount_type, discount_value,
  min_order_value, max_total_uses, max_uses_per_user, 
  valid_to, status
) values (
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
-- 7. VIEWS
-- ============================================

-- Effective menu (with overrides applied)
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

-- Available drivers
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
-- 8. RLS POLICIES
-- ============================================

-- ============================================
-- HELPER FUNCTIONS (must be defined AFTER tables exist)
-- ============================================

create or replace function public.has_role(target_role text)
returns boolean
language sql stable security definer
as $$
  select exists (
    select 1 from public.profiles
    where user_id = auth.uid()
      and target_role = any(roles)
      and status = 'active'
  );
$$;

create or replace function public.is_shop_owner(target_shop_id uuid)
returns boolean
language sql stable security definer
as $$
  select exists (
    select 1 from public.shops
    where id = target_shop_id
      and owner_user_id = auth.uid()
      and status = 'active'
  );
$$;

alter table public.profiles enable row level security;
alter table public.shops enable row level security;
alter table public.products enable row level security;
alter table public.shop_products enable row level security;
alter table public.shop_product_overrides enable row level security;
alter table public.preset_locations enable row level security;
alter table public.fixed_pricing enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.order_events enable row level security;
alter table public.driver_locations enable row level security;
alter table public.app_configs enable row level security;
alter table public.promotions enable row level security;
alter table public.user_promotions enable row level security;
alter table public.addresses enable row level security;

-- Profiles
create policy "Users read own profile" on public.profiles for select using (user_id = auth.uid());
create policy "Users update own profile" on public.profiles for update using (user_id = auth.uid());
create policy "Admin read all profiles" on public.profiles for select using (has_role('super_admin'));
create policy "Admin update all profiles" on public.profiles for update using (has_role('super_admin'));
create policy "Service role full access" on public.profiles for all using (auth.role() = 'service_role');

-- Shops
create policy "Anyone read active shops" on public.shops for select using (status = 'active');
create policy "Admin manage shops" on public.shops for all using (has_role('super_admin'));
create policy "Owner read own shop" on public.shops for select using (owner_user_id = auth.uid());
create policy "Merchant update own shop" on public.shops for update using (owner_user_id = auth.uid());

-- Products
create policy "Anyone read active products" on public.products for select using (status = 'active');
create policy "Admin manage products" on public.products for all using (has_role('super_admin'));

-- Shop Products
create policy "Anyone read shop products" on public.shop_products for select using (true);
create policy "Admin manage shop products" on public.shop_products for all using (has_role('super_admin'));
create policy "Merchant manage own shop products" on public.shop_products for all using (is_shop_owner(shop_id));

-- Shop Product Overrides
create policy "Anyone read overrides" on public.shop_product_overrides for select using (true);
create policy "Merchant update own shop overrides" on public.shop_product_overrides for update using (is_shop_owner(shop_id));
create policy "Merchant insert own shop overrides" on public.shop_product_overrides for insert with check (is_shop_owner(shop_id));
create policy "Admin manage overrides" on public.shop_product_overrides for all using (has_role('super_admin'));

-- Preset Locations
create policy "Anyone read preset locations" on public.preset_locations for select using (status = 'active');
create policy "Admin manage preset locations" on public.preset_locations for all using (has_role('super_admin'));

-- Fixed Pricing
create policy "Anyone read pricing" on public.fixed_pricing for select using (true);
create policy "Admin manage pricing" on public.fixed_pricing for all using (has_role('super_admin'));

-- Orders
create policy "Customer read own orders" on public.orders for select using (customer_id = auth.uid());
create policy "Driver read assigned orders" on public.orders for select using (driver_id = auth.uid());
create policy "Admin read all orders" on public.orders for select using (has_role('super_admin'));
create policy "Customer create orders" on public.orders for insert with check (customer_id = auth.uid());
create policy "Service role full access orders" on public.orders for all using (auth.role() = 'service_role');

-- Order Items
create policy "Read order items with order access" on public.order_items for select using (
  exists (select 1 from public.orders o where o.id = order_id and (o.customer_id = auth.uid() or o.driver_id = auth.uid() or has_role('super_admin')))
);
create policy "Insert order items with order" on public.order_items for insert with check (
  exists (select 1 from public.orders o where o.id = order_id and o.customer_id = auth.uid())
);

-- Order Events
create policy "Read events with order access" on public.order_events for select using (
  exists (select 1 from public.orders o where o.id = order_id and (o.customer_id = auth.uid() or o.driver_id = auth.uid() or has_role('super_admin')))
);

-- Driver Locations
create policy "Driver update own location" on public.driver_locations for all using (driver_id = auth.uid());
create policy "Admin read all locations" on public.driver_locations for select using (has_role('super_admin'));
create policy "Customer read driver location for their order" on public.driver_locations for select using (
  exists (select 1 from public.orders o where o.id = order_id and o.customer_id = auth.uid() and o.status in ('ASSIGNED', 'PICKED_UP'))
);

-- App Configs
create policy "Anyone read config" on public.app_configs for select using (true);
create policy "Admin manage config" on public.app_configs for all using (has_role('super_admin'));

-- Promotions
create policy "Anyone read active promotions" on public.promotions 
  for select using (status = 'active' and (valid_to is null or valid_to > now()));
create policy "Admin manage promotions" on public.promotions 
  for all using (has_role('super_admin'));

-- User Promotions
create policy "Users read own promotions" on public.user_promotions 
  for select using (user_id = auth.uid());
create policy "Admin read all user promotions" on public.user_promotions 
  for select using (has_role('super_admin'));
create policy "Service role full access user promotions" on public.user_promotions 
  for all using (auth.role() = 'service_role');

-- Addresses
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
-- 9. TRIGGERS
-- ============================================

-- Auto-update updated_at
create or replace function public.update_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger profiles_updated_at before update on public.profiles for each row execute function update_updated_at();
create trigger shops_updated_at before update on public.shops for each row execute function update_updated_at();
create trigger products_updated_at before update on public.products for each row execute function update_updated_at();
create trigger orders_updated_at before update on public.orders for each row execute function update_updated_at();
create trigger app_configs_updated_at before update on public.app_configs for each row execute function update_updated_at();
create trigger promotions_updated_at 
  before update on public.promotions 
  for each row execute function update_updated_at();
create trigger addresses_updated_at 
  before update on public.addresses 
  for each row execute function update_updated_at();

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (user_id, phone, full_name)
  values (new.id, new.phone, new.raw_user_meta_data->>'full_name');
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ============================================
-- 10. OPTIMIZATIONS (Constraints, Indexes, Triggers, ANALYZE)
-- ============================================

-- Nội dung bên dưới được gộp từ 02-SCHEMA-OPTIMIZED.sql

-- 1. CHECK CONSTRAINTS
alter table public.profiles 
  add constraint profiles_driver_status_check 
  check (driver_status in ('offline', 'online', 'busy'));

alter table public.profiles 
  add constraint profiles_status_check 
  check (status in ('active', 'inactive', 'suspended'));

alter table public.shops 
  add constraint shops_status_check 
  check (status in ('active', 'inactive', 'suspended'));

alter table public.products 
  add constraint products_status_check 
  check (status in ('active', 'inactive'));

alter table public.products 
  add constraint products_base_price_check 
  check (base_price > 0);

alter table public.orders 
  add constraint orders_status_check 
  check (status in (
    'PENDING_CONFIRMATION',
    'CONFIRMED',
    'ASSIGNED',
    'PICKED_UP',
    'COMPLETED',
    'CANCELED'
  ));

alter table public.orders 
  add constraint orders_service_type_check 
  check (service_type in ('food', 'ride', 'delivery'));

alter table public.orders 
  add constraint orders_pricing_mode_check 
  check (pricing_mode in ('fixed', 'gps'));

alter table public.orders 
  add constraint orders_amounts_check 
  check (
    delivery_fee >= 0 and
    items_total >= 0 and
    total_amount >= 0
  );

alter table public.order_items 
  add constraint order_items_positive_check 
  check (quantity > 0 and unit_price > 0 and subtotal > 0);

alter table public.preset_locations 
  add constraint preset_locations_coords_check 
  check (
    lat >= -90 and lat <= 90 and
    lng >= -180 and lng <= 180
  );

alter table public.preset_locations 
  add constraint preset_locations_status_check 
  check (status in ('active', 'inactive'));

alter table public.fixed_pricing 
  add constraint fixed_pricing_price_check 
  check (price > 0);

alter table public.fixed_pricing 
  add constraint fixed_pricing_service_type_check 
  check (service_type in ('food', 'ride', 'delivery'));

alter table public.driver_locations 
  add constraint driver_locations_coords_check 
  check (
    lat >= -90 and lat <= 90 and
    lng >= -180 and lng <= 180
  );

-- 2. ADD MISSING INDEXES
create index if not exists orders_market_status_created_idx 
  on public.orders(market_id, status, created_at desc);

create index if not exists orders_customer_status_created_idx 
  on public.orders(customer_id, status, created_at desc);

create index if not exists orders_driver_status_idx 
  on public.orders(driver_id, status) 
  where driver_id is not null;

create index if not exists orders_shop_created_idx 
  on public.orders(shop_id, created_at desc) 
  where shop_id is not null;

create index if not exists orders_promotion_idx 
  on public.orders(promotion_id) 
  where promotion_id is not null;

create index if not exists order_events_order_created_idx 
  on public.order_events(order_id, created_at);

create index if not exists order_events_actor_idx 
  on public.order_events(actor_id) 
  where actor_id is not null;

create index if not exists order_items_product_idx 
  on public.order_items(product_id) 
  where product_id is not null;

create index if not exists shop_products_shop_idx 
  on public.shop_products(shop_id);

create index if not exists shop_products_product_idx 
  on public.shop_products(product_id);

create index if not exists shop_product_overrides_shop_idx 
  on public.shop_product_overrides(shop_id);

create index if not exists driver_locations_order_idx 
  on public.driver_locations(order_id) 
  where order_id is not null;

create index if not exists driver_locations_updated_idx 
  on public.driver_locations(updated_at desc);

create index if not exists profiles_phone_idx 
  on public.profiles(phone) 
  where phone is not null;

create index if not exists profiles_driver_market_status_idx 
  on public.profiles(market_id, driver_status) 
  where 'driver' = any(roles) and status = 'active';

-- 3. OPTIMIZE EXISTING INDEXES
drop index if exists public.preset_locations_market_idx;
create index preset_locations_market_status_sort_idx 
  on public.preset_locations(market_id, status, sort_order) 
  where status = 'active';

drop index if exists public.fixed_pricing_lookup_idx;
create index fixed_pricing_lookup_idx 
  on public.fixed_pricing(market_id, service_type, zone_name);

-- 4. FUNCTION INDEXES
create index if not exists orders_customer_completed_idx 
  on public.orders(customer_id, status) 
  where status = 'COMPLETED';

-- 5. PARTIAL INDEXES
create index if not exists orders_active_idx 
  on public.orders(market_id, status, created_at desc) 
  where status not in ('COMPLETED', 'CANCELED');

create index if not exists orders_pending_idx 
  on public.orders(market_id, created_at) 
  where status = 'PENDING_CONFIRMATION';

create index if not exists orders_confirmed_idx 
  on public.orders(market_id, created_at) 
  where status = 'CONFIRMED';

create index if not exists driver_locations_active_idx 
  on public.driver_locations(driver_id, updated_at desc) 
  where order_id is not null;

-- 6. TRIGGER: ENSURE TOTAL AMOUNT CONSISTENCY
create or replace function public.validate_order_total()
returns trigger as $$
begin
  new.total_amount := new.delivery_fee + new.items_total - coalesce(new.discount_amount, 0);
  return new;
end;
$$ language plpgsql;

drop trigger if exists orders_validate_total on public.orders;
create trigger orders_validate_total
  before insert or update of delivery_fee, items_total, discount_amount
  on public.orders
  for each row
  execute function public.validate_order_total();

-- 7. COMMENTS
comment on table public.orders is 'Order records with state machine: PENDING_CONFIRMATION → CONFIRMED → ASSIGNED → PICKED_UP → COMPLETED';
comment on column public.orders.status is 'Order status following state machine';
comment on column public.orders.order_number is 'Sequential order number for display (serial)';
comment on column public.orders.pickup is 'JSONB: {label, address, lat, lng}';
comment on column public.orders.dropoff is 'JSONB: {label, address, lat, lng}';
comment on column public.profiles.driver_status is 'Driver availability: offline/online/busy';
comment on column public.profiles.roles is 'Array of roles: customer, driver, merchant, super_admin';
comment on index public.orders_market_status_created_idx is 'Optimized for admin dashboard queries';
comment on index public.orders_customer_status_created_idx is 'Optimized for customer order history';

-- 8. ANALYZE (optional, có thể comment nếu không muốn chạy mỗi lần)
analyze public.profiles;
analyze public.shops;
analyze public.products;
analyze public.orders;
analyze public.order_items;
analyze public.order_events;
analyze public.driver_locations;
analyze public.preset_locations;
analyze public.fixed_pricing;

-- ============================================
-- NOTIFICATIONS TABLE
-- ============================================

create table public.notifications (
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

create index notifications_user_idx on public.notifications(user_id, created_at desc);
create index notifications_unread_idx on public.notifications(user_id, is_read) where is_read = false;

-- RLS Policies
alter table public.notifications enable row level security;

create policy "Users read own notifications" on public.notifications 
  for select using (user_id = auth.uid());

create policy "Users update own notifications" on public.notifications 
  for update using (user_id = auth.uid());

create policy "Service role full access" on public.notifications 
  for all using (auth.role() = 'service_role');
