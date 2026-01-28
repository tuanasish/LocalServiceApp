-- Migration: Add toggle_shop_status RPC function
-- Date: 2026-01-27
-- Description: Cho phép merchant toggle shop status (active/inactive) để mở/đóng cửa hàng

-- Toggle shop status (active/inactive) - Merchant mở/đóng cửa hàng
create or replace function public.toggle_shop_status(
  p_shop_id uuid,
  p_status text -- 'active' hoặc 'inactive'
)
returns public.shops
language plpgsql
security definer
as $$
declare
  v_shop public.shops;
begin
  -- Kiểm tra merchant có quyền sở hữu shop không
  if not is_shop_owner(p_shop_id) and not has_role('super_admin') then
    raise exception 'NOT_ALLOWED';
  end if;
  
  -- Validate status
  if p_status not in ('active', 'inactive') then
    raise exception 'INVALID_STATUS';
  end if;
  
  -- Update status
  update public.shops
  set status = p_status,
      updated_at = now()
  where id = p_shop_id
  returning * into v_shop;
  
  if v_shop is null then
    raise exception 'SHOP_NOT_FOUND';
  end if;
  
  return v_shop;
end;
$$;
