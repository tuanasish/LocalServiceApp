-- =====================================================
-- PHASE 2: ADMIN MERCHANT MANAGEMENT RPC FUNCTIONS
-- =====================================================
-- Execute this script in Supabase SQL Editor
-- =====================================================

-- 1. Approve Merchant
-- Sets shop status to 'active'
create or replace function public.approve_merchant(p_shop_id uuid)
returns public.shops
language plpgsql security definer
as $$
declare
  v_shop public.shops;
begin
  -- Check if caller has super_admin role
  if not exists (
    select 1 from public.profiles
    where user_id = auth.uid() and role = 'super_admin'
  ) then
    raise exception 'NOT_ALLOWED';
  end if;

  update public.shops
  set status = 'active',
      updated_at = now()
  where id = p_shop_id
  returning * into v_shop;

  if v_shop is null then
    raise exception 'SHOP_NOT_FOUND';
  end if;

  return v_shop;
end;
$$;

-- 2. Reject Merchant
-- Sets shop status to 'rejected' and logs the reason
create or replace function public.reject_merchant(
  p_shop_id uuid,
  p_reason text
)
returns public.shops
language plpgsql security definer
as $$
declare
  v_shop public.shops;
begin
  -- Check if caller has super_admin role
  if not exists (
    select 1 from public.profiles
    where user_id = auth.uid() and role = 'super_admin'
  ) then
    raise exception 'NOT_ALLOWED';
  end if;

  update public.shops
  set status = 'rejected',
      updated_at = now()
  where id = p_shop_id
  returning * into v_shop;

  if v_shop is null then
    raise exception 'SHOP_NOT_FOUND';
  end if;

  -- Log rejection reason (optional - if audit table exists)
  -- insert into public.shop_audit_logs (shop_id, action, reason, created_by)
  -- values (p_shop_id, 'REJECTED', p_reason, auth.uid());

  return v_shop;
end;
$$;

-- 3. Get All Merchants for Admin
-- Returns merchants with owner info and order count
create or replace function public.get_all_merchants(
  p_market_id text,
  p_status text default null
)
returns table (
  id uuid,
  name text,
  address text,
  phone text,
  image_url text,
  owner_user_id uuid,
  owner_name text,
  owner_phone text,
  status text,
  rating double precision,
  order_count bigint,
  created_at timestamptz
)
language plpgsql security definer
as $$
begin
  -- Check if caller has super_admin role
  if not exists (
    select 1 from public.profiles
    where user_id = auth.uid() and role = 'super_admin'
  ) then
    raise exception 'NOT_ALLOWED';
  end if;

  return query
  select 
    s.id,
    s.name,
    s.address,
    s.phone,
    s.image_url,
    s.owner_user_id,
    p.full_name as owner_name,
    p.phone as owner_phone,
    s.status,
    s.rating,
    coalesce(count(o.id), 0)::bigint as order_count,
    s.created_at
  from public.shops s
  left join public.profiles p on p.user_id = s.owner_user_id
  left join public.orders o on o.shop_id = s.id
  where s.market_id = p_market_id
    and (p_status is null or s.status = p_status)
  group by s.id, p.full_name, p.phone
  order by s.created_at desc;
end;
$$;

-- 4. Get Merchant Stats
-- Returns statistics for a specific merchant
create or replace function public.get_merchant_stats(p_shop_id uuid)
returns table (
  total_orders bigint,
  completed_orders bigint,
  total_revenue bigint,
  avg_rating double precision,
  products_count bigint
)
language plpgsql security definer
as $$
begin
  -- Check if caller has super_admin role
  if not exists (
    select 1 from public.profiles
    where user_id = auth.uid() and role = 'super_admin'
  ) then
    raise exception 'NOT_ALLOWED';
  end if;

  return query
  select 
    coalesce(count(o.id), 0)::bigint as total_orders,
    coalesce(count(o.id) filter (where o.status = 'COMPLETED'), 0)::bigint as completed_orders,
    coalesce(sum(o.total_amount) filter (where o.status = 'COMPLETED'), 0)::bigint as total_revenue,
    (select s.rating from public.shops s where s.id = p_shop_id) as avg_rating,
    (select count(*) from public.shop_menus sm where sm.shop_id = p_shop_id)::bigint as products_count
  from public.orders o
  where o.shop_id = p_shop_id;
end;
$$;

-- Grant execute permissions
grant execute on function public.approve_merchant(uuid) to authenticated;
grant execute on function public.reject_merchant(uuid, text) to authenticated;
grant execute on function public.get_all_merchants(text, text) to authenticated;
grant execute on function public.get_merchant_stats(uuid) to authenticated;
