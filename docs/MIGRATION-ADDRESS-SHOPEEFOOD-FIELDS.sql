-- Migration: Thêm các field ShopeeFood-style vào bảng addresses
-- Date: 2026-01-26
-- Description: Thêm address_type, building, gate, driver_note, recipient_name, recipient_phone

-- 1. Thêm các columns mới vào bảng addresses
alter table public.addresses 
  add column if not exists address_type text default 'other' check (address_type in ('home', 'work', 'other')),
  add column if not exists building text,
  add column if not exists gate text,
  add column if not exists driver_note text,
  add column if not exists recipient_name text,
  add column if not exists recipient_phone text;

-- 2. Cập nhật comment cho các columns
comment on column public.addresses.address_type is 'Loại địa chỉ: home (Nhà riêng), work (Công ty), other (Khác)';
comment on column public.addresses.building is 'Tòa nhà, số tầng';
comment on column public.addresses.gate is 'Cổng';
comment on column public.addresses.driver_note is 'Ghi chú cho tài xế';
comment on column public.addresses.recipient_name is 'Tên người nhận';
comment on column public.addresses.recipient_phone is 'Số điện thoại người nhận';

-- 3. Tạo index cho address_type nếu cần (optional)
-- create index if not exists addresses_type_idx on public.addresses(user_id, address_type);
