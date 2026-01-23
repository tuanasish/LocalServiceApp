# CHỢ QUÊ MVP - ROADMAP 4 TUẦN

---

## TỔNG QUAN

| Tuần | Focus | Deliverable |
|------|-------|-------------|
| 1 | Setup + Auth + Config | Supabase ready, Guest login, Config cache |
| 2 | Customer Flow | Tạo đơn, xem đơn, hủy đơn |
| 3 | Admin + Driver | Dispatch flow hoàn chỉnh |
| 4 | Polish + Test | Bug fix, optimize, soft launch |

---

## TUẦN 1: FOUNDATION

### Ngày 1-2: Supabase Setup
- [ ] Tạo Supabase project
- [ ] Chạy `02-SCHEMA.sql`
- [ ] Chạy `03-RPC-FUNCTIONS.sql`
- [ ] Chạy `04-SEED-DATA.sql`
- [ ] Test RLS policies trong Supabase Dashboard
- [ ] Setup Storage bucket cho images

### Ngày 3-4: Flutter Project
- [ ] Tạo Flutter project
- [ ] Setup dependencies (pubspec.yaml)
- [ ] Integrate `supabase_flutter`
- [ ] Tạo folder structure
- [ ] Setup Riverpod providers
- [ ] Test connection

### Ngày 5-6: Auth + Config
- [ ] Guest auth flow (anonymous sign in)
- [ ] Profile creation trigger
- [ ] Config repository + cache
- [ ] Network status banner
- [ ] Error handling base

### Ngày 7: Review
- [ ] Code review
- [ ] Test mạng yếu (throttle)
- [ ] Fix bugs

**Checkpoint:** Guest có thể login, config được cache

---

## TUẦN 2: CUSTOMER FLOW

### Ngày 8-9: Home Screen
- [ ] 3 service buttons (Food/Ride/Delivery)
- [ ] User profile header
- [ ] Network status indicator
- [ ] Navigation setup

### Ngày 10-11: Create Order - Basic
- [ ] Preset location dropdown (pickup)
- [ ] Preset location dropdown (dropoff)
- [ ] Customer name/phone input
- [ ] Note input
- [ ] Fixed price display
- [ ] Submit order (RPC)

### Ngày 12-13: Create Order - Food
- [ ] Shop list screen
- [ ] Shop menu screen (from v_shop_menu)
- [ ] Cart management
- [ ] Order items
- [ ] Checkout flow

### Ngày 14: Order Management
- [ ] My orders list
- [ ] Order detail screen
- [ ] Status display (stepper)
- [ ] Cancel order (only PENDING)
- [ ] Pull to refresh

**Checkpoint:** Customer có thể tạo đơn Food/Ride/Delivery, xem và hủy đơn

---

## TUẦN 3: ADMIN + DRIVER

### Ngày 15-16: Admin Dashboard
- [ ] Admin login (role check)
- [ ] Tab: Pending orders
- [ ] Confirm order button
- [ ] Tab: Confirmed orders
- [ ] Driver dropdown
- [ ] Assign button

### Ngày 17-18: Driver App
- [ ] Driver login (role check)
- [ ] Go Online/Offline toggle
- [ ] My assigned orders list
- [ ] Order detail screen
- [ ] Update status buttons:
  - ASSIGNED → PICKED_UP
  - PICKED_UP → COMPLETED

### Ngày 19-20: Location Tracking (Basic)
- [ ] Request location permission
- [ ] Get current location
- [ ] Update driver_locations (when active order)
- [ ] Android foreground service setup

### Ngày 21: Integration Test
- [ ] Full flow test: Customer → Admin → Driver
- [ ] Test error scenarios
- [ ] Test offline behavior

**Checkpoint:** Full dispatch flow works end-to-end

---

## TUẦN 4: POLISH + LAUNCH

### Ngày 22-23: Bug Fixes
- [ ] Fix critical bugs from testing
- [ ] Improve error messages
- [ ] Loading states
- [ ] Empty states

### Ngày 24-25: Optimization
- [ ] Performance audit
- [ ] Memory leaks
- [ ] Network optimization
- [ ] Cache tuning

### Ngày 26-27: Device Testing
- [ ] Test on Samsung
- [ ] Test on Xiaomi (battery optimization guide)
- [ ] Test on old Android
- [ ] Test on iPhone

### Ngày 28: Release Prep
- [ ] App icons
- [ ] Splash screen
- [ ] Version check
- [ ] Build release APK
- [ ] Internal testing

**Checkpoint:** Ready for soft launch in 1 huyện

---

## VIBE CODING PROMPTS

### Prompt 1: Setup Supabase Client

```
Tạo file lib/data/datasources/supabase_client.dart cho app Flutter.

Yêu cầu:
- Singleton pattern
- Getter cho SupabaseClient instance
- Getter cho current user
- Method check isAuthenticated
- Method signInAnonymously (cho Guest)
- Method signOut
- Error handling với try-catch

Sử dụng package supabase_flutter.
Không thêm logic khác ngoài yêu cầu.
```

### Prompt 2: Config Repository

```
Tạo ConfigRepository cho app Chợ Quê.

Chức năng:
1. fetchConfig(marketId) - gọi RPC get_config
2. Cache config vào SharedPreferences
3. Load từ cache nếu network fail
4. TTL 15 phút cho cache

Input: market_id (String)
Output: AppConfig model

Xử lý:
- Timeout 10s
- Retry 1 lần nếu fail
- Fallback về cache nếu retry fail
- Throw error rõ ràng

Model AppConfig đã có sẵn với fields: flags, rules, limits (Map<String, dynamic>).
```

### Prompt 3: Create Order Screen

```
Tạo CreateOrderScreen cho dịch vụ Ride (xe ôm) trong app Chợ Quê.

UI requirements:
- Header: "Đặt xe ôm"
- Dropdown pickup: load từ preset_locations
- Dropdown dropoff: load từ preset_locations
- TextField: Tên (required)
- TextField: Số điện thoại (required, validate 10 số)
- TextField: Ghi chú (optional)
- Text: Hiển thị phí giao hàng (load từ fixed_pricing)
- Button: "Đặt xe" (full width, bottom fixed)

Behavior:
- Validate trước khi submit
- Loading state khi submit
- Gọi orderRepository.createOrder()
- Success: navigate to OrderDetailScreen
- Error: hiện SnackBar với message

Style:
- Nút to, chữ rõ
- Padding 16
- Font size 16 cho input, 18 cho button

Sử dụng Riverpod cho state management.
```

### Prompt 4: Order Status Stepper

```
Tạo OrderStatusStepper widget hiển thị trạng thái đơn hàng.

Input: OrderStatus currentStatus

Các bước:
1. Chờ xác nhận (PENDING_CONFIRMATION)
2. Đã xác nhận (CONFIRMED)
3. Đã gán tài xế (ASSIGNED)
4. Đã lấy hàng (PICKED_UP)
5. Hoàn thành (COMPLETED)

UI:
- Vertical stepper
- Icon check cho bước đã qua
- Icon circle cho bước hiện tại (với animation pulse)
- Icon circle outline cho bước chưa tới
- Màu xanh lá cho completed
- Màu cam cho current
- Màu xám cho upcoming
- Text status name bên cạnh icon

Nếu status = CANCELED, hiển thị icon X màu đỏ với text "Đã hủy".
```

### Prompt 5: Admin Order List

```
Tạo AdminOrdersScreen hiển thị danh sách đơn chờ xử lý.

Features:
1. Tabs: "Chờ xác nhận" | "Chờ gán tài xế"
2. Pull to refresh
3. Order card hiển thị:
   - Order number
   - Service type (Food/Ride/Delivery)
   - Pickup → Dropoff
   - Created time (relative: "5 phút trước")
   - Total amount
4. Tab 1: Button "Xác nhận" cho mỗi card
5. Tab 2: Dropdown chọn driver + Button "Gán"

Behavior:
- Load orders theo market_id của admin
- Tab 1: filter status = PENDING_CONFIRMATION
- Tab 2: filter status = CONFIRMED
- Xác nhận: gọi orderRepository.confirmOrder()
- Gán: gọi orderRepository.assignDriver()
- Refresh list sau mỗi action
- Show loading overlay khi processing

Error handling:
- Hiện SnackBar với error message
- Không navigate away khi error

Sử dụng Riverpod.
```

### Prompt 6: Driver Home Screen

```
Tạo DriverHomeScreen cho app tài xế Chợ Quê.

Layout:
1. Header: Avatar + Tên + Status badge (Online/Offline/Busy)
2. Toggle switch: "Sẵn sàng nhận đơn"
3. Stats card: "Đơn hôm nay: X | Thu nhập: XXX đ"
4. Section: "Đơn đang thực hiện" (nếu có)
5. Order cards với button update status

Toggle behavior:
- ON: gọi driverRepository.goOnline()
- OFF: gọi driverRepository.goOffline()
- Nếu có đơn active, không cho OFF (hiện dialog)

Order card actions:
- ASSIGNED: Button "Đã lấy hàng" → status = PICKED_UP
- PICKED_UP: Button "Hoàn thành" → status = COMPLETED

UI notes:
- Badge màu: Online=xanh, Offline=xám, Busy=cam
- Card highlight cho đơn đang thực hiện
- Confirmation dialog trước khi update status

Sử dụng Riverpod.
```

### Prompt 7: Location Service

```
Tạo LocationService cho app Chợ Quê.

Chức năng:
1. checkPermission() - kiểm tra permission
2. requestPermission() - request nếu chưa có
3. getCurrentLocation() - lấy vị trí hiện tại
4. startTracking(orderId) - bắt đầu tracking cho driver
5. stopTracking() - dừng tracking
6. uploadLocation(orderId, position) - upload lên server

Cấu hình tracking:
- Interval: 30 seconds
- Distance filter: 50 meters
- Accuracy: high

Android:
- Sử dụng geolocator package
- Foreground notification khi tracking
- Notification title: "Chợ Quê - Đang giao hàng"

Error handling:
- Permission denied: return null, không crash
- Location unavailable: retry 2 lần
- Upload fail: queue locally, retry later

Singleton pattern.
```

---

## HARD RULES CHO VIBE CODING

1. **KHÔNG thêm feature ngoài brief**
2. **KHÔNG dùng package lạ** - chỉ dùng list trong pubspec.yaml
3. **MỌI mutation order phải qua RPC** - không update trực tiếp
4. **MỌI error phải có message tiếng Việt**
5. **LUÔN có loading state**
6. **LUÔN có empty state**
7. **LUÔN xử lý timeout** (10s default)
8. **KHÔNG dùng connectivity để quyết định có Internet** - luôn try request
9. **Commit nhỏ, PR nhỏ** - 1 feature = 1 PR
10. **Test trên mạng yếu** trước khi merge

---

## CHECKLIST RELEASE

### Code Quality
- [ ] Không có TODO/FIXME còn sót
- [ ] Không có console.log/print debug
- [ ] Error messages tiếng Việt
- [ ] Loading states đầy đủ

### Security
- [ ] RLS enabled trên tất cả bảng
- [ ] Không có hardcoded secrets
- [ ] API keys trong .env

### Android
- [ ] minSdkVersion >= 21
- [ ] targetSdkVersion = 34
- [ ] Permissions đầy đủ
- [ ] Foreground service type = location
- [ ] ProGuard rules (nếu cần)

### iOS
- [ ] iOS 12.0+
- [ ] Info.plist location descriptions
- [ ] Background modes enabled
- [ ] Capabilities: Push Notifications

### Testing
- [ ] Test trên Samsung
- [ ] Test trên Xiaomi
- [ ] Test trên iPhone
- [ ] Test mạng yếu (3G)
- [ ] Test offline → online

### Release
- [ ] Version code increment
- [ ] Changelog
- [ ] APK signed
- [ ] TestFlight ready (iOS)
