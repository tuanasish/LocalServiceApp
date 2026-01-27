-- ============================================
-- CHẠY FILE NÀY TRONG SUPABASE SQL EDITOR
-- ============================================
-- File này bao gồm TẤT CẢ các thay đổi SQL mới:
-- 1. Bảng notifications (từ PUSH-NOTIFICATION-FCM-PLAN)
-- 2. RPC functions cho notifications
-- ============================================

-- ============================================
-- 1. TẠO BẢNG NOTIFICATIONS
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

-- ============================================
-- 2. TẠO INDEXES
-- ============================================

create index if not exists notifications_user_idx on public.notifications(user_id, created_at desc);
create index if not exists notifications_unread_idx on public.notifications(user_id, is_read) where is_read = false;

-- ============================================
-- 3. RLS POLICIES
-- ============================================

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
-- 4. RPC FUNCTIONS CHO NOTIFICATIONS
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
-- HOÀN TẤT
-- ============================================
-- 
-- KIỂM TRA SAU KHI CHẠY:
-- 
-- 1. Kiểm tra bảng đã tồn tại:
--    SELECT * FROM public.notifications LIMIT 1;
-- 
-- 2. Kiểm tra functions đã được tạo:
--    SELECT routine_name FROM information_schema.routines 
--    WHERE routine_schema = 'public' 
--    AND routine_name LIKE '%notification%';
-- 
-- 3. Kiểm tra indexes:
--    SELECT indexname FROM pg_indexes 
--    WHERE tablename = 'notifications';
-- 
-- 4. Kiểm tra RLS policies:
--    SELECT * FROM pg_policies 
--    WHERE tablename = 'notifications';
-- 
-- ============================================
