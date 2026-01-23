-- ============================================
-- CHỢ QUÊ MVP - SEED DATA
-- Version: 1.0
-- Sample data for "huyen_demo" market
-- ============================================

-- ============================================
-- 1. APP CONFIG
-- ============================================

insert into public.app_configs (market_id, flags, rules, limits) values (
  'huyen_demo',
  '{
    "auth_mode": "guest",
    "address_mode": "preset",
    "pricing_mode": "fixed",
    "tracking_mode": "status",
    "dispatch_mode": "admin"
  }'::jsonb,
  '{
    "guest_max_orders": 10,
    "guest_session_days": 30,
    "require_phone_for_order": true
  }'::jsonb,
  '{
    "location_interval_sec": 30,
    "location_distance_filter_m": 50,
    "order_timeout_minutes": 30
  }'::jsonb
);

-- ============================================
-- 2. PRESET LOCATIONS
-- ============================================

insert into public.preset_locations (market_id, label, address, lat, lng, location_type, sort_order) values
-- Trung tâm
('huyen_demo', 'Chợ Huyện', 'Chợ trung tâm huyện', 21.0285, 105.8542, 'landmark', 1),
('huyen_demo', 'UBND Huyện', 'Trụ sở UBND huyện', 21.0290, 105.8550, 'landmark', 2),
('huyen_demo', 'Bệnh viện Huyện', 'Bệnh viện đa khoa huyện', 21.0275, 105.8530, 'landmark', 3),
('huyen_demo', 'Trường THPT', 'Trường THPT Huyện', 21.0300, 105.8560, 'landmark', 4),
('huyen_demo', 'Bến xe', 'Bến xe khách huyện', 21.0260, 105.8520, 'landmark', 5),

-- Xã A
('huyen_demo', 'UBND Xã A', 'Trụ sở UBND xã A', 21.0350, 105.8600, 'landmark', 10),
('huyen_demo', 'Chợ Xã A', 'Chợ xã A', 21.0355, 105.8605, 'landmark', 11),
('huyen_demo', 'Trường Tiểu học Xã A', 'Trường TH xã A', 21.0345, 105.8595, 'landmark', 12),

-- Xã B  
('huyen_demo', 'UBND Xã B', 'Trụ sở UBND xã B', 21.0200, 105.8480, 'landmark', 20),
('huyen_demo', 'Chợ Xã B', 'Chợ xã B', 21.0205, 105.8485, 'landmark', 21),
('huyen_demo', 'Đình làng Xã B', 'Đình làng xã B', 21.0195, 105.8475, 'landmark', 22),

-- Quán ăn
('huyen_demo', 'Quán Cơm Bà Năm', '123 Đường chính, TT Huyện', 21.0288, 105.8545, 'restaurant', 30),
('huyen_demo', 'Quán Phở Ông Bảy', '45 Đường chợ, TT Huyện', 21.0282, 105.8540, 'restaurant', 31),
('huyen_demo', 'Quán Bún Chị Hoa', '67 Ngõ 2, TT Huyện', 21.0292, 105.8548, 'restaurant', 32);

-- ============================================
-- 3. FIXED PRICING
-- ============================================

-- Food delivery
insert into public.fixed_pricing (market_id, service_type, zone_name, price) values
('huyen_demo', 'food', 'Nội thị trấn', 10000),
('huyen_demo', 'food', 'Liên xã gần', 15000),
('huyen_demo', 'food', 'Liên xã xa', 25000);

-- Ride
insert into public.fixed_pricing (market_id, service_type, zone_name, price) values
('huyen_demo', 'ride', 'Nội thị trấn', 15000),
('huyen_demo', 'ride', 'Liên xã gần', 25000),
('huyen_demo', 'ride', 'Liên xã xa', 40000);

-- Delivery
insert into public.fixed_pricing (market_id, service_type, zone_name, price) values
('huyen_demo', 'delivery', 'Nội thị trấn', 12000),
('huyen_demo', 'delivery', 'Liên xã gần', 20000),
('huyen_demo', 'delivery', 'Liên xã xa', 30000);

-- ============================================
-- 4. SAMPLE PRODUCTS
-- ============================================

insert into public.products (id, name, description, base_price, category, status) values
-- Cơm
('11111111-1111-1111-1111-111111111111', 'Cơm sườn', 'Cơm sườn nướng + canh + rau', 35000, 'Cơm', 'active'),
('11111111-1111-1111-1111-111111111112', 'Cơm gà', 'Cơm gà rán + canh + rau', 35000, 'Cơm', 'active'),
('11111111-1111-1111-1111-111111111113', 'Cơm rang', 'Cơm rang dưa bò', 30000, 'Cơm', 'active'),

-- Phở/Bún
('22222222-2222-2222-2222-222222222221', 'Phở bò', 'Phở bò tái nạm', 40000, 'Phở/Bún', 'active'),
('22222222-2222-2222-2222-222222222222', 'Phở gà', 'Phở gà ta', 40000, 'Phở/Bún', 'active'),
('22222222-2222-2222-2222-222222222223', 'Bún chả', 'Bún chả Hà Nội', 35000, 'Phở/Bún', 'active'),
('22222222-2222-2222-2222-222222222224', 'Bún riêu', 'Bún riêu cua', 35000, 'Phở/Bún', 'active'),

-- Đồ uống
('33333333-3333-3333-3333-333333333331', 'Trà đá', 'Trà đá', 5000, 'Đồ uống', 'active'),
('33333333-3333-3333-3333-333333333332', 'Nước mía', 'Nước mía ép', 15000, 'Đồ uống', 'active'),
('33333333-3333-3333-3333-333333333333', 'Cà phê đen', 'Cà phê đen đá', 15000, 'Đồ uống', 'active'),
('33333333-3333-3333-3333-333333333334', 'Cà phê sữa', 'Cà phê sữa đá', 20000, 'Đồ uống', 'active');

-- ============================================
-- 5. SAMPLE SHOPS
-- ============================================

-- Note: owner_user_id sẽ được set sau khi có user thật
insert into public.shops (id, market_id, name, address, phone, status) values
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'huyen_demo', 'Quán Cơm Bà Năm', '123 Đường chính, TT Huyện', '0901234567', 'active'),
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'huyen_demo', 'Quán Phở Ông Bảy', '45 Đường chợ, TT Huyện', '0901234568', 'active'),
('cccccccc-cccc-cccc-cccc-cccccccccccc', 'huyen_demo', 'Quán Bún Chị Hoa', '67 Ngõ 2, TT Huyện', '0901234569', 'active');

-- ============================================
-- 6. SHOP PRODUCTS (assign products to shops)
-- ============================================

-- Quán Cơm Bà Năm - bán cơm + đồ uống
insert into public.shop_products (shop_id, product_id) values
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111'),
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111112'),
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111113'),
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '33333333-3333-3333-3333-333333333331'),
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '33333333-3333-3333-3333-333333333333'),
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '33333333-3333-3333-3333-333333333334');

-- Quán Phở Ông Bảy - bán phở + đồ uống
insert into public.shop_products (shop_id, product_id) values
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '22222222-2222-2222-2222-222222222221'),
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '22222222-2222-2222-2222-222222222222'),
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '33333333-3333-3333-3333-333333333331'),
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '33333333-3333-3333-3333-333333333333');

-- Quán Bún Chị Hoa - bán bún + đồ uống
insert into public.shop_products (shop_id, product_id) values
('cccccccc-cccc-cccc-cccc-cccccccccccc', '22222222-2222-2222-2222-222222222223'),
('cccccccc-cccc-cccc-cccc-cccccccccccc', '22222222-2222-2222-2222-222222222224'),
('cccccccc-cccc-cccc-cccc-cccccccccccc', '33333333-3333-3333-3333-333333333331'),
('cccccccc-cccc-cccc-cccc-cccccccccccc', '33333333-3333-3333-3333-333333333332');

-- ============================================
-- 7. TEST USERS (create via Supabase Auth first)
-- ============================================

-- After creating users in Supabase Auth, run:
-- UPDATE public.profiles SET roles = array['super_admin'] WHERE phone = 'admin_phone';
-- UPDATE public.profiles SET roles = array['driver'] WHERE phone = 'driver_phone';
-- UPDATE public.profiles SET roles = array['merchant'], market_id = 'huyen_demo' WHERE phone = 'merchant_phone';
-- UPDATE public.shops SET owner_user_id = (select user_id from profiles where phone = 'merchant_phone') WHERE id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
