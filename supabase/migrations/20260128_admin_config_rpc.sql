-- =====================================================
-- PHASE 5: ADMIN CONFIG MANAGEMENT RPC FUNCTIONS
-- =====================================================

-- Admin Update Config
create or replace function public.admin_update_config(
  p_market_id text,
  p_flags jsonb default null,
  p_rules jsonb default null,
  p_limits jsonb default null
)
returns public.app_configs
language plpgsql security definer
as $$
declare
  v_config public.app_configs;
begin
  -- Check if caller has super_admin role
  if not exists (
    select 1 from public.profiles
    where user_id = auth.uid() and role = 'super_admin'
  ) then
    raise exception 'NOT_ALLOWED';
  end if;

  update public.app_configs
  set 
    flags = coalesce(p_flags, flags),
    rules = coalesce(p_rules, rules),
    limits = coalesce(p_limits, limits),
    config_version = config_version + 1,
    updated_at = now()
  where market_id = p_market_id
  returning * into v_config;

  if v_config is null then
    raise exception 'CONFIG_NOT_FOUND';
  end if;

  return v_config;
end;
$$;

-- Admin Get Config (for editing)
create or replace function public.admin_get_config(p_market_id text)
returns public.app_configs
language plpgsql security definer
as $$
declare
  v_config public.app_configs;
begin
  -- Check if caller has super_admin role
  if not exists (
    select 1 from public.profiles
    where user_id = auth.uid() and role = 'super_admin'
  ) then
    raise exception 'NOT_ALLOWED';
  end if;

  select * into v_config
  from public.app_configs
  where market_id = p_market_id;

  if v_config is null then
    raise exception 'CONFIG_NOT_FOUND';
  end if;

  return v_config;
end;
$$;

-- Grant execute permissions
grant execute on function public.admin_update_config(text, jsonb, jsonb, jsonb) to authenticated;
grant execute on function public.admin_get_config(text) to authenticated;
