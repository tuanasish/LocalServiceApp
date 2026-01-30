-- =====================================================
-- PHASE 3: ADMIN PRODUCT MANAGEMENT RPC FUNCTIONS
-- Using correct table names: shop_products, shop_product_overrides
-- =====================================================

-- 1. Admin Create Product
create or replace function public.admin_create_product(
  p_name text,
  p_description text default null,
  p_base_price int default 0,
  p_category text default null,
  p_image_path text default null
)
returns public.products
language plpgsql security definer
as $$
declare
  v_product public.products;
begin
  -- Check if caller has super_admin role
  if not exists (
    select 1 from public.profiles
    where user_id = auth.uid() and role = 'super_admin'
  ) then
    raise exception 'NOT_ALLOWED';
  end if;

  if p_base_price < 0 then
    raise exception 'INVALID_PRICE';
  end if;

  insert into public.products (
    name, description, base_price, category, image_path, status
  ) values (
    p_name, p_description, p_base_price, p_category, p_image_path, 'active'
  )
  returning * into v_product;

  return v_product;
end;
$$;

-- 2. Admin Update Product
create or replace function public.admin_update_product(
  p_product_id uuid,
  p_name text default null,
  p_description text default null,
  p_base_price int default null,
  p_category text default null,
  p_image_path text default null,
  p_status text default null
)
returns public.products
language plpgsql security definer
as $$
declare
  v_product public.products;
begin
  -- Check if caller has super_admin role
  if not exists (
    select 1 from public.profiles
    where user_id = auth.uid() and role = 'super_admin'
  ) then
    raise exception 'NOT_ALLOWED';
  end if;

  update public.products
  set 
    name = coalesce(p_name, name),
    description = coalesce(p_description, description),
    base_price = coalesce(p_base_price, base_price),
    category = coalesce(p_category, category),
    image_path = coalesce(p_image_path, image_path),
    status = coalesce(p_status, status),
    updated_at = now()
  where id = p_product_id
  returning * into v_product;

  if v_product is null then
    raise exception 'PRODUCT_NOT_FOUND';
  end if;

  return v_product;
end;
$$;

-- 3. Admin Delete Product (soft delete)
create or replace function public.admin_delete_product(p_product_id uuid)
returns public.products
language plpgsql security definer
as $$
declare
  v_product public.products;
begin
  -- Check if caller has super_admin role
  if not exists (
    select 1 from public.profiles
    where user_id = auth.uid() and role = 'super_admin'
  ) then
    raise exception 'NOT_ALLOWED';
  end if;

  update public.products
  set status = 'inactive',
      updated_at = now()
  where id = p_product_id
  returning * into v_product;

  if v_product is null then
    raise exception 'PRODUCT_NOT_FOUND';
  end if;

  return v_product;
end;
$$;

-- 4. Admin Get All Products (with optional filtering)
create or replace function public.admin_get_all_products(
  p_status_filter text default null,
  p_category_filter text default null
)
returns table (
  id uuid,
  name text,
  description text,
  image_path text,
  base_price int,
  category text,
  status text,
  shop_count bigint,
  created_at timestamptz,
  updated_at timestamptz
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
    p.id,
    p.name,
    p.description,
    p.image_path,
    p.base_price,
    p.category,
    p.status,
    coalesce((select count(*) from public.shop_products sp where sp.product_id = p.id), 0)::bigint as shop_count,
    p.created_at,
    p.updated_at
  from public.products p
  where (p_status_filter is null or p.status = p_status_filter)
    and (p_category_filter is null or p.category = p_category_filter)
  order by p.category nulls last, p.name;
end;
$$;

-- 5. Admin Assign Product to Shop
create or replace function public.admin_assign_product_to_shop(
  p_shop_id uuid,
  p_product_id uuid,
  p_custom_price int default null
)
returns json
language plpgsql security definer
as $$
declare
  v_base_price int;
begin
  -- Check if caller has super_admin role
  if not exists (
    select 1 from public.profiles
    where user_id = auth.uid() and role = 'super_admin'
  ) then
    raise exception 'NOT_ALLOWED';
  end if;

  -- Get base price if custom price not provided
  select base_price into v_base_price
  from public.products
  where id = p_product_id;
    
  if v_base_price is null then
    raise exception 'PRODUCT_NOT_FOUND';
  end if;

  -- Insert into shop_products
  insert into public.shop_products (shop_id, product_id, is_listed)
  values (p_shop_id, p_product_id, true)
  on conflict (shop_id, product_id)
  do update set is_listed = true;

  -- Handle custom price override
  if p_custom_price is not null then
    insert into public.shop_product_overrides (shop_id, product_id, price_override, is_available)
    values (p_shop_id, p_product_id, p_custom_price, true)
    on conflict (shop_id, product_id)
    do update set 
      price_override = p_custom_price,
      is_available = true,
      updated_at = now();
  end if;

  return json_build_object('success', true, 'shop_id', p_shop_id, 'product_id', p_product_id);
end;
$$;

-- 6. Admin Remove Product from Shop
create or replace function public.admin_remove_product_from_shop(
  p_shop_id uuid,
  p_product_id uuid
)
returns boolean
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

  -- Remove from shop_products
  delete from public.shop_products
  where shop_id = p_shop_id and product_id = p_product_id;

  -- Also remove override if exists
  delete from public.shop_product_overrides
  where shop_id = p_shop_id and product_id = p_product_id;

  return true;
end;
$$;

-- Grant execute permissions
grant execute on function public.admin_create_product(text, text, int, text, text) to authenticated;
grant execute on function public.admin_update_product(uuid, text, text, int, text, text, text) to authenticated;
grant execute on function public.admin_delete_product(uuid) to authenticated;
grant execute on function public.admin_get_all_products(text, text) to authenticated;
grant execute on function public.admin_assign_product_to_shop(uuid, uuid, int) to authenticated;
grant execute on function public.admin_remove_product_from_shop(uuid, uuid) to authenticated;
