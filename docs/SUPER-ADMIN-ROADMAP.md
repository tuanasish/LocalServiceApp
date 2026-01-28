# SUPER ADMIN ROADMAP

> **Mục tiêu**: Hoàn thiện role Super Admin theo brief với đầy đủ quyền: config, menu, đơn, tài xế, shop  
> **Timeline ước tính**: 8-11 ngày  
> **Cập nhật**: 28/01/2026

---

## 1. TỔNG QUAN HIỆN TRẠNG

### Đã hoàn thành

- ✅ **Driver Management** (100%)
  - Driver list screen với filter (Pending/Approved/Rejected)
  - Driver detail screen với stats và order history
  - Driver monitoring screen với real-time location
  - Driver approval/rejection workflow
  - Provider: `driver_admin_provider.dart`
  - Repository: `driver_repository.dart`
  - RPC functions: `approve_driver`, `reject_driver`, `get_driver_stats`

- ✅ **System Overview Screen** (UI only)
  - Dashboard layout với stats cards
  - Quick actions shortcuts
  - Recent activity timeline (hardcoded data)

- ✅ **Merchant Management Screens** (UI only)
  - Merchant list screen với search và filter
  - Merchant detail screen với approve/reject actions (hardcoded data)

- ✅ **Menu Management Screens** (UI only)
  - Menu management screen với shop selector
  - Item editor screen với form create/edit (hardcoded data)

- ✅ **RPC Functions cho Orders**
  - `confirm_order(p_order_id)` - Xác nhận đơn hàng
  - `assign_driver(p_order_id, p_driver_id)` - Gán tài xế
  - `reassign_driver(p_order_id, p_new_driver_id, p_reason)` - Gán lại tài xế
  - `cancel_order_by_admin(p_order_id, p_reason)` - Hủy đơn hàng

### Còn thiếu

| Tính năng | Trạng thái | Mô tả |
|-----------|------------|-------|
| **Order Management** | ⚠️ RPC có, UI chưa kết nối | Cần screen để confirm/assign đơn hàng |
| **Merchant Management** | ⚠️ UI có, backend chưa kết nối | Cần RPC và provider để approve/reject merchants |
| **Product Management** | ⚠️ UI có, backend chưa kết nối | Cần RPC CRUD products và gán vào shops |
| **System Dashboard** | ⚠️ UI có, data hardcoded | Cần RPC lấy stats realtime |
| **Config Management** | ❌ Chưa có | Cần screen và RPC để quản lý feature flags |
| **Promotion Management** | ❌ Chưa có | Cần screen và RPC để quản lý vouchers |

---

## 2. PHASE 1: ADMIN ORDER MANAGEMENT

**Ưu tiên**: 🔴 Cao  
**Ước tính**: 2-3 ngày  
**Mục tiêu**: Admin có thể confirm và assign đơn hàng

### Tasks

1. **Tạo `admin_order_provider.dart`**
   - `pendingOrdersProvider` - Stream đơn chờ xác nhận (PENDING_CONFIRMATION)
   - `confirmedOrdersProvider` - Stream đơn chờ gán tài xế (CONFIRMED)
   - `activeOrdersProvider` - Stream đơn đang thực hiện (ASSIGNED, PICKED_UP)
   - `confirmOrderProvider` - FutureProvider cho action confirm
   - `assignDriverProvider` - FutureProvider cho action assign
   - `reassignDriverProvider` - FutureProvider cho action reassign
   - `cancelOrderProvider` - FutureProvider cho action cancel

2. **Tạo `admin_orders_screen.dart`**
   - Tab "Chờ xác nhận" - List đơn PENDING_CONFIRMATION
   - Tab "Chờ gán tài xế" - List đơn CONFIRMED
   - Tab "Đang thực hiện" - List đơn ASSIGNED/PICKED_UP
   - Order card hiển thị:
     - Order number, service type, shop name
     - Customer info (name, phone)
     - Pickup → Dropoff
     - Total amount, created time
     - Action buttons theo status
   - Driver picker dropdown (load từ `onlineDriversProvider`)
   - Pull to refresh
   - Loading và error states

3. **Tạo `admin_order_detail_screen.dart`**
   - Header với order number và status badge
   - Customer info card
   - Order items list (nếu là food order)
   - Location info (pickup/dropoff)
   - Pricing breakdown
   - Order timeline (từ `order_events`)
   - Action buttons:
     - Confirm (nếu PENDING_CONFIRMATION)
     - Assign Driver (nếu CONFIRMED)
     - Reassign Driver (nếu ASSIGNED/PICKED_UP)
     - Cancel (nếu chưa COMPLETED)

4. **Mở rộng `order_repository.dart`**
   - `getPendingOrders(marketId)` - Lấy đơn chờ xác nhận
   - `getConfirmedOrders(marketId)` - Lấy đơn chờ gán tài xế
   - `getActiveOrders(marketId)` - Lấy đơn đang thực hiện
   - `confirmOrder(orderId)` - Gọi RPC `confirm_order`
   - `assignDriver(orderId, driverId)` - Gọi RPC `assign_driver`
   - `reassignDriver(orderId, newDriverId, reason)` - Gọi RPC `reassign_driver`
   - `cancelOrderByAdmin(orderId, reason)` - Gọi RPC `cancel_order_by_admin`

5. **Routing**
   - Thêm route `/admin/orders` → `AdminOrdersScreen`
   - Thêm route `/admin/orders/:id` → `AdminOrderDetailScreen`

### Files cần tạo

```
lib/
├── providers/
│   └── admin_order_provider.dart
├── screens/admin/
│   ├── admin_orders_screen.dart
│   └── admin_order_detail_screen.dart
```

### RPC Functions

✅ Đã có sẵn trong `03-RPC-FUNCTIONS.sql`:
- `confirm_order(p_order_id uuid)`
- `assign_driver(p_order_id uuid, p_driver_id uuid)`
- `reassign_driver(p_order_id uuid, p_new_driver_id uuid, p_reason text)`
- `cancel_order_by_admin(p_order_id uuid, p_reason text)`

### Checklist

- [ ] Tạo `admin_order_provider.dart`
- [ ] Tạo `admin_orders_screen.dart`
- [ ] Tạo `admin_order_detail_screen.dart`
- [ ] Mở rộng `order_repository.dart`
- [ ] Thêm routes vào `app_router.dart`
- [ ] Test confirm order flow
- [ ] Test assign driver flow
- [ ] Test reassign driver flow
- [ ] Test cancel order flow

---

## 3. PHASE 2: MERCHANT MANAGEMENT

**Ưu tiên**: 🔴 Cao  
**Ước tính**: 1-2 ngày  
**Mục tiêu**: Admin có thể approve/reject merchants và quản lý shops

### Tasks

1. **Tạo RPC functions mới** (nếu chưa có)
   - `approve_merchant(shop_id uuid)` - Approve shop registration
   - `reject_merchant(shop_id uuid, reason text)` - Reject shop registration
   - `get_all_merchants(status_filter text)` - Lấy danh sách merchants với filter
   - `get_merchant_stats(shop_id uuid)` - Lấy stats của merchant

2. **Tạo `admin_merchant_provider.dart`**
   - `allMerchantsProvider` - Tất cả merchants
   - `pendingMerchantsProvider` - Merchants chờ approval
   - `activeMerchantsProvider` - Merchants đã active
   - `merchantDetailProvider(shopId)` - Chi tiết merchant
   - `approveMerchantProvider` - Action approve
   - `rejectMerchantProvider` - Action reject

3. **Kết nối `admin_merchant_list_screen.dart` với provider**
   - Load merchants từ API thay vì hardcoded
   - Implement search (theo tên shop, owner name, phone)
   - Filter tabs: All, Pending, Active
   - Merchant card với:
     - Shop name, owner info
     - Address, phone
     - Status badge
     - Order count, rating
     - Approve button (nếu pending)

4. **Kết nối `admin_merchant_details_screen.dart`**
   - Load chi tiết merchant từ API
   - Hiển thị đầy đủ thông tin:
     - Shop profile
     - Owner info
     - Statistics (orders, revenue, rating)
     - Order history
   - Action buttons:
     - Approve (nếu pending)
     - Reject (nếu pending)
     - Block account (nếu active)

5. **Mở rộng `merchant_repository.dart`**
   - `getAllMerchants(statusFilter)` - Lấy danh sách merchants
   - `getMerchantById(shopId)` - Lấy chi tiết merchant
   - `approveMerchant(shopId)` - Gọi RPC `approve_merchant`
   - `rejectMerchant(shopId, reason)` - Gọi RPC `reject_merchant`
   - `getMerchantStats(shopId)` - Gọi RPC `get_merchant_stats`

6. **Routing**
   - Thêm route `/admin/merchants` → `AdminMerchantListScreen`
   - Thêm route `/admin/merchants/:id` → `AdminMerchantDetailsScreen`

### Files cần tạo/cập nhật

```
lib/
├── providers/
│   └── admin_merchant_provider.dart
├── screens/admin/
│   ├── admin_merchant_list_screen.dart (cập nhật)
│   └── admin_merchant_details_screen.dart (cập nhật)
└── data/repositories/
    └── merchant_repository.dart (mở rộng)
```

### RPC Functions cần tạo

Thêm vào `03-RPC-FUNCTIONS.sql`:

```sql
-- Approve Merchant
create or replace function public.approve_merchant(p_shop_id uuid)
returns public.shops
language plpgsql security definer
as $$
declare
  v_shop public.shops;
begin
  if not has_role('super_admin') then
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

-- Reject Merchant
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
  if not has_role('super_admin') then
    raise exception 'NOT_ALLOWED';
  end if;

  update public.shops
  set status = 'inactive',
      updated_at = now()
  where id = p_shop_id
  returning * into v_shop;

  if v_shop is null then
    raise exception 'SHOP_NOT_FOUND';
  end if;

  -- TODO: Log rejection reason vào bảng audit nếu có

  return v_shop;
end;
$$;

-- Get All Merchants
create or replace function public.get_all_merchants(
  p_market_id text,
  p_status text default null
)
returns table (
  id uuid,
  name text,
  address text,
  phone text,
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
  if not has_role('super_admin') then
    raise exception 'NOT_ALLOWED';
  end if;

  return query
  select 
    s.id,
    s.name,
    s.address,
    s.phone,
    s.owner_user_id,
    p.full_name as owner_name,
    p.phone as owner_phone,
    s.status,
    s.rating,
    count(o.id) as order_count,
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
```

### Checklist

- [ ] Tạo RPC functions cho merchant management
- [ ] Tạo `admin_merchant_provider.dart`
- [ ] Cập nhật `admin_merchant_list_screen.dart` với real data
- [ ] Cập nhật `admin_merchant_details_screen.dart` với real data
- [ ] Mở rộng `merchant_repository.dart`
- [ ] Thêm routes vào `app_router.dart`
- [ ] Test approve merchant flow
- [ ] Test reject merchant flow
- [ ] Test search và filter

---

## 4. PHASE 3: MENU/PRODUCT MANAGEMENT

**Ưu tiên**: 🟡 Trung bình  
**Ước tính**: 2 ngày  
**Mục tiêu**: Admin có thể CRUD products trong catalog và gán vào shops

### Tasks

1. **Tạo RPC functions mới**
   - `admin_create_product(name, description, base_price, category, image_path)`
   - `admin_update_product(product_id, name, description, base_price, category, image_path)`
   - `admin_delete_product(product_id)` - Soft delete (set status = 'inactive')
   - `admin_assign_product_to_shop(shop_id, product_id)` - Gán product vào shop menu
   - `admin_remove_product_from_shop(shop_id, product_id)` - Xóa product khỏi shop menu
   - `get_all_products(category_filter, status_filter)` - Lấy danh sách products

2. **Tạo `admin_product_provider.dart`**
   - `allProductsProvider` - Tất cả products
   - `productsByCategoryProvider(category)` - Products theo category
   - `productDetailProvider(productId)` - Chi tiết product
   - `createProductProvider` - Action create
   - `updateProductProvider` - Action update
   - `deleteProductProvider` - Action delete
   - `assignProductToShopProvider` - Action assign to shop

3. **Kết nối `admin_menu_management_screen.dart`**
   - Load products từ API
   - Shop selector dropdown (load từ `allMerchantsProvider`)
   - Category tabs/filter
   - Product cards với:
     - Image, name, description
     - Base price, category
     - Status badge
     - Edit/Delete buttons
     - "Assign to Shop" button

4. **Kết nối `admin_item_editor_screen.dart`**
   - Form fields:
     - Name (required)
     - Description (optional)
     - Category (dropdown)
     - Base price (required, > 0)
     - Image upload (Supabase Storage)
     - Status toggle (active/inactive)
   - Live preview card
   - Action buttons:
     - Save (create/update)
     - Cancel
     - Delete (nếu edit mode)

5. **Mở rộng `product_repository.dart`**
   - `getAllProducts(categoryFilter, statusFilter)`
   - `getProductById(productId)`
   - `createProduct(name, description, basePrice, category, imagePath)`
   - `updateProduct(productId, ...)`
   - `deleteProduct(productId)`
   - `assignProductToShop(shopId, productId)`
   - `removeProductFromShop(shopId, productId)`

6. **Image Upload Service**
   - Tạo `image_upload_service.dart` hoặc mở rộng existing service
   - Upload product images lên Supabase Storage bucket `product-images`
   - Return public URL

7. **Routing**
   - Thêm route `/admin/menu` → `AdminMenuManagementScreen`
   - Thêm route `/admin/menu/edit/:id` → `AdminItemEditorScreen`
   - Thêm route `/admin/menu/new` → `AdminItemEditorScreen` (create mode)

### Files cần tạo/cập nhật

```
lib/
├── providers/
│   └── admin_product_provider.dart
├── screens/admin/
│   ├── admin_menu_management_screen.dart (cập nhật)
│   └── admin_item_editor_screen.dart (cập nhật)
├── data/repositories/
│   └── product_repository.dart (mở rộng)
└── services/
    └── image_upload_service.dart (tạo mới hoặc mở rộng)
```

### RPC Functions cần tạo

Thêm vào `03-RPC-FUNCTIONS.sql`:

```sql
-- Admin Create Product
create or replace function public.admin_create_product(
  p_name text,
  p_description text default null,
  p_base_price int,
  p_category text default null,
  p_image_path text default null
)
returns public.products
language plpgsql security definer
as $$
declare
  v_product public.products;
begin
  if not has_role('super_admin') then
    raise exception 'NOT_ALLOWED';
  end if;

  if p_base_price <= 0 then
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

-- Admin Update Product
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
  if not has_role('super_admin') then
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

-- Admin Delete Product (soft delete)
create or replace function public.admin_delete_product(p_product_id uuid)
returns boolean
language plpgsql security definer
as $$
begin
  if not has_role('super_admin') then
    raise exception 'NOT_ALLOWED';
  end if;

  update public.products
  set status = 'inactive',
      updated_at = now()
  where id = p_product_id;

  if not found then
    raise exception 'PRODUCT_NOT_FOUND';
  end if;

  return true;
end;
$$;

-- Admin Assign Product to Shop
create or replace function public.admin_assign_product_to_shop(
  p_shop_id uuid,
  p_product_id uuid
)
returns public.shop_products
language plpgsql security definer
as $$
declare
  v_shop_product public.shop_products;
begin
  if not has_role('super_admin') then
    raise exception 'NOT_ALLOWED';
  end if;

  insert into public.shop_products (shop_id, product_id, is_listed)
  values (p_shop_id, p_product_id, true)
  on conflict (shop_id, product_id)
  do update set is_listed = true
  returning * into v_shop_product;

  return v_shop_product;
end;
$$;

-- Get All Products (Admin)
create or replace function public.get_all_products(
  p_category text default null,
  p_status text default 'active'
)
returns table (
  id uuid,
  name text,
  description text,
  image_path text,
  base_price int,
  category text,
  status text,
  created_at timestamptz,
  updated_at timestamptz
)
language plpgsql security definer
as $$
begin
  if not has_role('super_admin') then
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
    p.created_at,
    p.updated_at
  from public.products p
  where (p_category is null or p.category = p_category)
    and (p_status is null or p.status = p_status)
  order by p.created_at desc;
end;
$$;
```

### Checklist

- [ ] Tạo RPC functions cho product management
- [ ] Tạo `admin_product_provider.dart`
- [ ] Cập nhật `admin_menu_management_screen.dart` với real data
- [ ] Cập nhật `admin_item_editor_screen.dart` với real data
- [ ] Mở rộng `product_repository.dart`
- [ ] Tạo/mở rộng `image_upload_service.dart`
- [ ] Setup Supabase Storage bucket `product-images`
- [ ] Thêm routes vào `app_router.dart`
- [ ] Test create product flow
- [ ] Test update product flow
- [ ] Test delete product flow
- [ ] Test assign product to shop flow

---

## 5. PHASE 4: SYSTEM DASHBOARD

**Ưu tiên**: 🟡 Trung bình  
**Ước tính**: 1 ngày  
**Mục tiêu**: Dashboard hiển thị realtime stats thay vì hardcoded data

### Tasks

1. **Tạo RPC function**
   - `get_admin_dashboard_stats(market_id)` - Trả về tổng hợp stats:
     ```json
     {
       "total_orders_today": 45,
       "total_revenue_today": 2500000,
       "pending_orders": 5,
       "confirmed_orders": 3,
       "active_orders": 12,
       "completed_orders_today": 30,
       "online_drivers": 8,
       "busy_drivers": 5,
       "offline_drivers": 2,
       "active_merchants": 20,
       "pending_merchants": 2,
       "new_customers_today": 3,
       "total_customers": 150
     }
     ```

2. **Tạo `admin_stats_provider.dart`**
   - `systemStatsProvider` - Tổng hợp stats (auto-refresh mỗi 30s)
   - `todayOrdersCountProvider` - Số đơn hôm nay
   - `todayRevenueProvider` - Doanh thu hôm nay
   - `activeDriversCountProvider` - Số tài xế online/busy
   - `activeMerchantsCountProvider` - Số merchants active
   - `pendingOrdersCountProvider` - Số đơn chờ xử lý

3. **Kết nối `admin_system_overview_screen.dart`**
   - Load stats từ API thay vì hardcoded
   - Stats cards:
     - Tổng đơn hôm nay
     - Doanh thu hôm nay
     - Đơn chờ xử lý
     - Tài xế online
     - Merchants active
   - Quick actions:
     - Xem đơn chờ xác nhận
     - Xem đơn chờ gán tài xế
     - Xem tài xế chờ duyệt
     - Xem merchants chờ duyệt
   - Recent activity timeline (load từ `order_events`)

4. **Mở rộng `order_repository.dart` hoặc tạo `admin_repository.dart`**
   - `getDashboardStats(marketId)` - Gọi RPC `get_admin_dashboard_stats`
   - `getRecentActivity(limit)` - Lấy recent order events

### Files cần tạo/cập nhật

```
lib/
├── providers/
│   └── admin_stats_provider.dart
├── screens/admin/
│   └── admin_system_overview_screen.dart (cập nhật)
└── data/repositories/
    └── admin_repository.dart (tạo mới hoặc mở rộng existing)
```

### RPC Function cần tạo

Thêm vào `03-RPC-FUNCTIONS.sql`:

```sql
-- Get Admin Dashboard Stats
create or replace function public.get_admin_dashboard_stats(
  p_market_id text
)
returns jsonb
language plpgsql security definer
as $$
declare
  v_stats jsonb;
begin
  if not has_role('super_admin') then
    raise exception 'NOT_ALLOWED';
  end if;

  select jsonb_build_object(
    'total_orders_today', count(*) filter (
      where created_at::date = current_date
    ),
    'total_revenue_today', coalesce(sum(total_amount) filter (
      where created_at::date = current_date 
        and status = 'COMPLETED'
    ), 0),
    'pending_orders', count(*) filter (where status = 'PENDING_CONFIRMATION'),
    'confirmed_orders', count(*) filter (where status = 'CONFIRMED'),
    'active_orders', count(*) filter (where status in ('ASSIGNED', 'PICKED_UP')),
    'completed_orders_today', count(*) filter (
      where completed_at::date = current_date
    ),
    'online_drivers', (
      select count(*) from public.profiles
      where market_id = p_market_id
        and 'driver' = any(roles)
        and driver_status = 'online'
        and status = 'active'
    ),
    'busy_drivers', (
      select count(*) from public.profiles
      where market_id = p_market_id
        and 'driver' = any(roles)
        and driver_status = 'busy'
        and status = 'active'
    ),
    'offline_drivers', (
      select count(*) from public.profiles
      where market_id = p_market_id
        and 'driver' = any(roles)
        and driver_status = 'offline'
        and status = 'active'
    ),
    'active_merchants', (
      select count(*) from public.shops
      where market_id = p_market_id
        and status = 'active'
    ),
    'pending_merchants', (
      select count(*) from public.shops
      where market_id = p_market_id
        and status = 'inactive'
    ),
    'new_customers_today', (
      select count(*) from public.profiles
      where market_id = p_market_id
        and created_at::date = current_date
        and 'customer' = any(roles)
    ),
    'total_customers', (
      select count(*) from public.profiles
      where market_id = p_market_id
        and 'customer' = any(roles)
        and status = 'active'
    )
  ) into v_stats
  from public.orders
  where market_id = p_market_id;

  return v_stats;
end;
$$;
```

### Checklist

- [ ] Tạo RPC function `get_admin_dashboard_stats`
- [ ] Tạo `admin_stats_provider.dart`
- [ ] Cập nhật `admin_system_overview_screen.dart` với real data
- [ ] Implement auto-refresh stats (mỗi 30s)
- [ ] Load recent activity timeline
- [ ] Test dashboard với real data

---

## 6. PHASE 5: CONFIG MANAGEMENT

**Ưu tiên**: 🟢 Thấp  
**Ước tính**: 1 ngày  
**Mục tiêu**: Admin có thể thay đổi feature flags và rules

### Tasks

1. **Tạo RPC function**
   - `admin_update_config(market_id, flags, rules, limits)` - Cập nhật app config

2. **Tạo `admin_config_screen.dart`**
   - Feature flags section:
     - `auth_mode`: Toggle giữa `guest` / `otp`
     - `address_mode`: Toggle giữa `preset` / `vietmap`
     - `pricing_mode`: Toggle giữa `fixed` / `gps`
     - `tracking_mode`: Toggle giữa `status` / `realtime`
     - `dispatch_mode`: Toggle giữa `admin` / `auto`
   - Rules section:
     - `guest_max_orders`: Number input
     - `guest_session_days`: Number input
     - `require_phone_for_order`: Toggle
   - Limits section:
     - `location_interval_sec`: Number input
     - `location_distance_filter_m`: Number input
     - `order_timeout_minutes`: Number input
   - Save button với confirmation dialog

3. **Tạo `admin_config_provider.dart`**
   - `appConfigProvider` - Load config hiện tại
   - `updateConfigProvider` - Action update

4. **Mở rộng `config_repository.dart`**
   - `updateConfig(marketId, flags, rules, limits)` - Gọi RPC `admin_update_config`

### Files cần tạo/cập nhật

```
lib/
├── providers/
│   └── admin_config_provider.dart
├── screens/admin/
│   └── admin_config_screen.dart
└── data/repositories/
    └── config_repository.dart (mở rộng)
```

### RPC Function cần tạo

Thêm vào `03-RPC-FUNCTIONS.sql`:

```sql
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
  if not has_role('super_admin') then
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
```

### Checklist

- [ ] Tạo RPC function `admin_update_config`
- [ ] Tạo `admin_config_provider.dart`
- [ ] Tạo `admin_config_screen.dart`
- [ ] Mở rộng `config_repository.dart`
- [ ] Thêm route `/admin/config` vào `app_router.dart`
- [ ] Test update config flow
- [ ] Test validation (số dương, enum values)

---

## 7. PHASE 6: PROMOTION MANAGEMENT

**Ưu tiên**: 🟢 Thấp  
**Ước tính**: 1-2 ngày  
**Mục tiêu**: Admin quản lý vouchers và promotions

### Tasks

1. **Tạo RPC functions mới**
   - `admin_create_promotion(...)` - Tạo promotion mới
   - `admin_update_promotion(promo_id, ...)` - Cập nhật promotion
   - `admin_pause_promotion(promo_id)` - Pause promotion
   - `admin_resume_promotion(promo_id)` - Resume promotion
   - `get_all_promotions(market_id, status_filter)` - Lấy danh sách promotions
   - `get_promotion_stats(promo_id)` - Lấy stats của promotion (usage count, revenue)

2. **Tạo `admin_promotion_screen.dart`**
   - List promotions với:
     - Code, name, description
     - Type (first_order, voucher, all_orders)
     - Discount type & value
     - Status badge
     - Usage stats (current_uses / max_total_uses)
     - Valid from/to dates
   - Create/Edit promotion form:
     - Code (optional, null = auto-apply)
     - Name, description
     - Type dropdown
     - Discount type & value
     - Max discount (cho percent)
     - Min order value
     - Max total uses
     - Max uses per user
     - Valid from/to dates
   - Action buttons:
     - Create new
     - Edit
     - Pause/Resume
     - View stats

3. **Tạo `admin_promotion_provider.dart`**
   - `allPromotionsProvider` - Tất cả promotions
   - `activePromotionsProvider` - Promotions active
   - `promotionDetailProvider(promoId)` - Chi tiết promotion
   - `promotionStatsProvider(promoId)` - Stats của promotion
   - `createPromotionProvider` - Action create
   - `updatePromotionProvider` - Action update
   - `pausePromotionProvider` - Action pause
   - `resumePromotionProvider` - Action resume

4. **Mở rộng `promotion_repository.dart`**
   - `getAllPromotions(marketId, statusFilter)`
   - `getPromotionById(promoId)`
   - `createPromotion(...)`
   - `updatePromotion(promoId, ...)`
   - `pausePromotion(promoId)`
   - `resumePromotion(promoId)`
   - `getPromotionStats(promoId)`

### Files cần tạo/cập nhật

```
lib/
├── providers/
│   └── admin_promotion_provider.dart
├── screens/admin/
│   └── admin_promotion_screen.dart
└── data/repositories/
    └── promotion_repository.dart (mở rộng)
```

### RPC Functions cần tạo

Thêm vào `03-RPC-FUNCTIONS.sql`:

```sql
-- Admin Create Promotion
create or replace function public.admin_create_promotion(
  p_market_id text,
  p_code text default null,
  p_name text,
  p_description text default null,
  p_promo_type text,
  p_discount_type text,
  p_discount_value int,
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
  if not has_role('super_admin') then
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
  if not has_role('super_admin') then
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

-- Admin Pause/Resume Promotion
create or replace function public.admin_toggle_promotion_status(
  p_promo_id uuid,
  p_status text -- 'active' or 'paused'
)
returns public.promotions
language plpgsql security definer
as $$
declare
  v_promo public.promotions;
begin
  if not has_role('super_admin') then
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
create or replace function public.get_all_promotions(
  p_market_id text,
  p_status text default null
)
returns table (
  id uuid,
  code text,
  name text,
  description text,
  promo_type text,
  discount_type text,
  discount_value int,
  max_discount int,
  min_order_value int,
  max_total_uses int,
  max_uses_per_user int,
  current_uses int,
  valid_from timestamptz,
  valid_to timestamptz,
  status text,
  created_at timestamptz
)
language plpgsql security definer
as $$
begin
  if not has_role('super_admin') then
    raise exception 'NOT_ALLOWED';
  end if;

  return query
  select 
    p.id,
    p.code,
    p.name,
    p.description,
    p.promo_type,
    p.discount_type,
    p.discount_value,
    p.max_discount,
    p.min_order_value,
    p.max_total_uses,
    p.max_uses_per_user,
    p.current_uses,
    p.valid_from,
    p.valid_to,
    p.status,
    p.created_at
  from public.promotions p
  where p.market_id = p_market_id
    and (p_status is null or p.status = p_status)
  order by p.created_at desc;
end;
$$;

-- Get Promotion Stats
create or replace function public.get_promotion_stats(p_promo_id uuid)
returns jsonb
language plpgsql security definer
as $$
declare
  v_stats jsonb;
begin
  if not has_role('super_admin') then
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
```

### Checklist

- [ ] Tạo RPC functions cho promotion management
- [ ] Tạo `admin_promotion_provider.dart`
- [ ] Tạo `admin_promotion_screen.dart`
- [ ] Mở rộng `promotion_repository.dart`
- [ ] Thêm route `/admin/promotions` vào `app_router.dart`
- [ ] Test create promotion flow
- [ ] Test update promotion flow
- [ ] Test pause/resume promotion flow
- [ ] Test promotion stats

---

## 8. ROUTING UPDATES

Cập nhật `app_router.dart` để thêm các routes admin:

```dart
GoRoute(
  path: '/admin',
  builder: (context, state) => AdminSystemOverviewScreen(),
  routes: [
    // Orders
    GoRoute(
      path: 'orders',
      builder: (context, state) => AdminOrdersScreen(),
    ),
    GoRoute(
      path: 'orders/:id',
      builder: (context, state) {
        final orderId = state.pathParameters['id']!;
        return AdminOrderDetailScreen(orderId: orderId);
      },
    ),
    // Merchants
    GoRoute(
      path: 'merchants',
      builder: (context, state) => AdminMerchantListScreen(),
    ),
    GoRoute(
      path: 'merchants/:id',
      builder: (context, state) {
        final shopId = state.pathParameters['id']!;
        return AdminMerchantDetailsScreen(shopId: shopId);
      },
    ),
    // Drivers
    GoRoute(
      path: 'drivers',
      builder: (context, state) => AdminDriverListScreen(),
    ),
    GoRoute(
      path: 'drivers/:id',
      builder: (context, state) {
        final driverId = state.pathParameters['id']!;
        return AdminDriverDetailScreen(driverId: driverId);
      },
    ),
    GoRoute(
      path: 'drivers/monitoring',
      builder: (context, state) => AdminDriverMonitoringScreen(),
    ),
    // Menu/Products
    GoRoute(
      path: 'menu',
      builder: (context, state) => AdminMenuManagementScreen(),
    ),
    GoRoute(
      path: 'menu/new',
      builder: (context, state) => AdminItemEditorScreen(),
    ),
    GoRoute(
      path: 'menu/edit/:id',
      builder: (context, state) {
        final productId = state.pathParameters['id']!;
        return AdminItemEditorScreen(productId: productId);
      },
    ),
    // Config
    GoRoute(
      path: 'config',
      builder: (context, state) => AdminConfigScreen(),
    ),
    // Promotions
    GoRoute(
      path: 'promotions',
      builder: (context, state) => AdminPromotionScreen(),
    ),
  ],
),
```

---

## 9. DATABASE MIGRATIONS

### SQL Files cần tạo

1. **`migrations/YYYYMMDD_add_admin_merchant_rpcs.sql`**
   - `approve_merchant`
   - `reject_merchant`
   - `get_all_merchants`

2. **`migrations/YYYYMMDD_add_admin_product_rpcs.sql`**
   - `admin_create_product`
   - `admin_update_product`
   - `admin_delete_product`
   - `admin_assign_product_to_shop`
   - `get_all_products`

3. **`migrations/YYYYMMDD_add_admin_stats_rpc.sql`**
   - `get_admin_dashboard_stats`

4. **`migrations/YYYYMMDD_add_admin_config_rpc.sql`**
   - `admin_update_config`

5. **`migrations/YYYYMMDD_add_admin_promotion_rpcs.sql`**
   - `admin_create_promotion`
   - `admin_update_promotion`
   - `admin_toggle_promotion_status`
   - `get_all_promotions`
   - `get_promotion_stats`

### Supabase Storage Setup

Tạo bucket `product-images` cho product images:
- Public access: true
- Allowed MIME types: image/jpeg, image/png, image/webp
- Max file size: 5MB

---

## 10. TIMELINE ƯỚC TÍNH

| Phase | Tasks | Ước tính | Độ ưu tiên |
|-------|-------|----------|------------|
| **Phase 1** | Order Management | 2-3 ngày | 🔴 Cao |
| **Phase 2** | Merchant Management | 1-2 ngày | 🔴 Cao |
| **Phase 3** | Product Management | 2 ngày | 🟡 Trung bình |
| **Phase 4** | System Dashboard | 1 ngày | 🟡 Trung bình |
| **Phase 5** | Config Management | 1 ngày | 🟢 Thấp |
| **Phase 6** | Promotion Management | 1-2 ngày | 🟢 Thấp |
| **Tổng** | | **8-11 ngày** | |

### Thứ tự triển khai đề xuất

1. **Week 1**: Phase 1 + Phase 2 (Order + Merchant Management)
2. **Week 2**: Phase 3 + Phase 4 (Product + Dashboard)
3. **Week 3**: Phase 5 + Phase 6 (Config + Promotion) + Testing & Polish

---

## 11. TESTING CHECKLIST

### Phase 1: Order Management
- [ ] Admin có thể xem danh sách đơn chờ xác nhận
- [ ] Admin có thể confirm đơn hàng
- [ ] Admin có thể gán tài xế cho đơn đã confirm
- [ ] Admin có thể reassign tài xế
- [ ] Admin có thể hủy đơn hàng với lý do
- [ ] Real-time updates khi đơn thay đổi status

### Phase 2: Merchant Management
- [ ] Admin có thể xem danh sách merchants
- [ ] Admin có thể search và filter merchants
- [ ] Admin có thể approve merchant
- [ ] Admin có thể reject merchant với lý do
- [ ] Admin có thể xem chi tiết merchant với stats

### Phase 3: Product Management
- [ ] Admin có thể tạo product mới
- [ ] Admin có thể upload image cho product
- [ ] Admin có thể update product
- [ ] Admin có thể delete product (soft delete)
- [ ] Admin có thể gán product vào shop
- [ ] Product hiển thị đúng trong shop menu

### Phase 4: System Dashboard
- [ ] Dashboard hiển thị stats realtime
- [ ] Auto-refresh stats mỗi 30s
- [ ] Recent activity timeline load đúng
- [ ] Quick actions navigate đúng screens

### Phase 5: Config Management
- [ ] Admin có thể update feature flags
- [ ] Admin có thể update rules
- [ ] Admin có thể update limits
- [ ] Config changes được apply ngay

### Phase 6: Promotion Management
- [ ] Admin có thể tạo promotion mới
- [ ] Admin có thể update promotion
- [ ] Admin có thể pause/resume promotion
- [ ] Admin có thể xem promotion stats

---

## 12. NOTES & CONSIDERATIONS

### Security
- Tất cả RPC functions phải check `has_role('super_admin')`
- RLS policies đã được setup sẵn trong schema
- Admin routes nên có middleware check role trước khi access

### Performance
- Sử dụng StreamProvider cho real-time data (orders, drivers)
- Cache stats dashboard (refresh mỗi 30s thay vì mỗi lần load)
- Pagination cho list screens (orders, merchants, products)

### Error Handling
- Tất cả error messages phải tiếng Việt
- Hiển thị SnackBar với error message
- Loading states cho tất cả async operations

### UI/UX
- Consistent design với design system hiện có
- Empty states cho tất cả list screens
- Loading skeletons thay vì spinner
- Pull to refresh cho list screens

---

## 13. DEPENDENCIES

### Existing Dependencies (đã có)
- `flutter_riverpod` - State management
- `supabase_flutter` - Backend
- `go_router` - Routing (nếu đã setup)

### New Dependencies (có thể cần)
- `image_picker` - Chọn image từ device
- `cached_network_image` - Cache product images (đã có)
- `intl` - Format dates/numbers (đã có)

---

**Cập nhật lần cuối**: 28/01/2026  
**Người tạo**: AI Assistant  
**Status**: 📋 Planning Complete - Ready for Implementation
