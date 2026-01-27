-- ============================================
-- CHỢ QUÊ - REVIEWS AND FAVORITES SCHEMA
-- Description: Tables for shop reviews and user favorites
-- ============================================

-- 1. Table for Shop Reviews
create table if not exists public.shop_reviews (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid not null references public.shops(id) on delete cascade,
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  order_id uuid references public.orders(id) on delete set null,
  rating int not null check (rating >= 1 and rating <= 5),
  comment text,
  is_anonymous boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 2. Table for User Favorites
create table if not exists public.user_favorites (
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  shop_id uuid not null references public.shops(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, shop_id)
);

-- 3. RLS Policies for Reviews
alter table public.shop_reviews enable row level security;

drop policy if exists "Anyone can view shop reviews" on public.shop_reviews;
create policy "Anyone can view shop reviews" on public.shop_reviews 
  for select using (true);

drop policy if exists "Users can manage their own reviews" on public.shop_reviews;
create policy "Users can manage their own reviews" on public.shop_reviews 
  for all using (user_id = auth.uid());

-- 4. RLS Policies for Favorites
alter table public.user_favorites enable row level security;

drop policy if exists "Users can view their own favorites" on public.user_favorites;
create policy "Users can view their own favorites" on public.user_favorites 
  for select using (user_id = auth.uid());

drop policy if exists "Users can manage their own favorites" on public.user_favorites;
create policy "Users can manage their own favorites" on public.user_favorites 
  for all using (user_id = auth.uid());

-- 5. Aggregated ratings on shops
alter table public.shops 
  add column if not exists review_count int default 0;

-- 6. Trigger to update shop rating
create or replace function public.update_shop_rating()
returns trigger as $$
begin
  update public.shops
  set 
    rating = (select avg(rating) from public.shop_reviews where shop_id = coalesce(new.shop_id, old.shop_id)),
    review_count = (select count(*) from public.shop_reviews where shop_id = coalesce(new.shop_id, old.shop_id))
  where id = coalesce(new.shop_id, old.shop_id);
  return null;
end;
$$ language plpgsql security definer;

drop trigger if exists on_review_change on public.shop_reviews;
create trigger on_review_change
  after insert or update or delete on public.shop_reviews
  for each row execute function public.update_shop_rating();
