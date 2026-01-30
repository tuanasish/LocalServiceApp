-- =====================================================
-- PHASE 6: ADMIN PROMOTION MANAGEMENT RPC FUNCTIONS
-- =====================================================

-- Admin Create Promotion
create or replace function public.admin_create_promotion(
  p_market_id text,
  p_code text default null,
  p_name text default null,
  p_description text default null,
  p_promo_type text default 'voucher',
  p_discount_type text default 'fixed',
  p_discount_value int default 0,
  p_max_discount int default null,
  p_min_order_value int default 0,
  p_service_type text default 'food',
  p_max_total_uses int default null,
  p_max_uses_per_user int default 1,
  p_valid_from timestamptz default now(),
  p_valid_to timestamptz default null
)
returns public.promotions
language plpgsql security definer
as $$
declare
  v_promo public.promotions;
begin
  -- Check if caller has super_admin role
  if not exists (
    select 1 from public.profiles
    where user_id = auth.uid() and role = 'super_admin'
  ) then
    raise exception 'NOT_ALLOWED';
  end if;

  -- Validate
  if p_discount_value <= 0 then
    raise exception 'INVALID_DISCOUNT_VALUE';
  end if;

  if p_promo_type not in ('first_order', 'voucher', 'all_orders') then
    raise exception 'INVALID_PROMO_TYPE';
  end if;

  if p_discount_type not in ('freeship', 'fixed', 'percent') then
    raise exception 'INVALID_DISCOUNT_TYPE';
  end if;

  insert into public.promotions (
    market_id, code, name, description,
    promo_type, discount_type, discount_value, max_discount,
    min_order_value, service_type,
    max_total_uses, max_uses_per_user,
    valid_from, valid_to, status
  ) values (
    p_market_id, p_code, p_name, p_description,
    p_promo_type, p_discount_type, p_discount_value, p_max_discount,
    p_min_order_value, p_service_type,
    p_max_total_uses, p_max_uses_per_user,
    p_valid_from, p_valid_to, 'active'
  )
  returning * into v_promo;

  return v_promo;
end;
$$;

-- Admin Update Promotion
create or replace function public.admin_update_promotion(
  p_promo_id uuid,
  p_name text default null,
  p_description text default null,
  p_discount_value int default null,
  p_max_discount int default null,
  p_min_order_value int default null,
  p_max_total_uses int default null,
  p_max_uses_per_user int default null,
  p_valid_from timestamptz default null,
  p_valid_to timestamptz default null,
  p_status text default null
)
returns public.promotions
language plpgsql security definer
as $$
declare
  v_promo public.promotions;
begin
  -- Check if caller has super_admin role
  if not exists (
    select 1 from public.profiles
    where user_id = auth.uid() and role = 'super_admin'
  ) then
    raise exception 'NOT_ALLOWED';
  end if;

  update public.promotions
  set 
    name = coalesce(p_name, name),
    description = coalesce(p_description, description),
    discount_value = coalesce(p_discount_value, discount_value),
    max_discount = coalesce(p_max_discount, max_discount),
    min_order_value = coalesce(p_min_order_value, min_order_value),
    max_total_uses = coalesce(p_max_total_uses, max_total_uses),
    max_uses_per_user = coalesce(p_max_uses_per_user, max_uses_per_user),
    valid_from = coalesce(p_valid_from, valid_from),
    valid_to = coalesce(p_valid_to, valid_to),
    status = coalesce(p_status, status),
    updated_at = now()
  where id = p_promo_id
  returning * into v_promo;

  if v_promo is null then
    raise exception 'PROMOTION_NOT_FOUND';
  end if;

  return v_promo;
end;
$$;

-- Admin Toggle Promotion Status (Pause/Resume)
create or replace function public.admin_toggle_promotion_status(
  p_promo_id uuid,
  p_status text
)
returns public.promotions
language plpgsql security definer
as $$
declare
  v_promo public.promotions;
begin
  -- Check if caller has super_admin role
  if not exists (
    select 1 from public.profiles
    where user_id = auth.uid() and role = 'super_admin'
  ) then
    raise exception 'NOT_ALLOWED';
  end if;

  if p_status not in ('active', 'paused') then
    raise exception 'INVALID_STATUS';
  end if;

  update public.promotions
  set status = p_status,
      updated_at = now()
  where id = p_promo_id
  returning * into v_promo;

  if v_promo is null then
    raise exception 'PROMOTION_NOT_FOUND';
  end if;

  return v_promo;
end;
$$;

-- Get All Promotions (Admin)
create or replace function public.admin_get_all_promotions(
  p_market_id text,
  p_status text default null
)
returns setof public.promotions
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
  select *
  from public.promotions p
  where p.market_id = p_market_id
    and (p_status is null or p.status = p_status)
  order by p.created_at desc;
end;
$$;

-- Get Promotion Stats
create or replace function public.admin_get_promotion_stats(p_promo_id uuid)
returns jsonb
language plpgsql security definer
as $$
declare
  v_stats jsonb;
begin
  -- Check if caller has super_admin role
  if not exists (
    select 1 from public.profiles
    where user_id = auth.uid() and role = 'super_admin'
  ) then
    raise exception 'NOT_ALLOWED';
  end if;

  select jsonb_build_object(
    'total_uses', count(*),
    'total_discount_applied', coalesce(sum(discount_applied), 0),
    'unique_users', count(distinct user_id),
    'revenue_impact', (
      select coalesce(sum(total_amount), 0)
      from public.orders
      where promotion_id = p_promo_id
        and status = 'COMPLETED'
    )
  ) into v_stats
  from public.user_promotions
  where promotion_id = p_promo_id;

  return v_stats;
end;
$$;

-- Grant execute permissions
grant execute on function public.admin_create_promotion(text, text, text, text, text, text, int, int, int, text, int, int, timestamptz, timestamptz) to authenticated;
grant execute on function public.admin_update_promotion(uuid, text, text, int, int, int, int, int, timestamptz, timestamptz, text) to authenticated;
grant execute on function public.admin_toggle_promotion_status(uuid, text) to authenticated;
grant execute on function public.admin_get_all_promotions(text, text) to authenticated;
grant execute on function public.admin_get_promotion_stats(uuid) to authenticated;
