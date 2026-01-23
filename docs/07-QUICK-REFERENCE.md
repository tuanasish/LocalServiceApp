# CHỢ QUÊ MVP - QUICK REFERENCE

## 🚀 Quick Start

```bash
# 1. Supabase Setup
# - Create project at supabase.com
# - Run SQL files in order: 02 → 03 → 04
# - Get URL + anon key

# 2. Flutter Setup
flutter create cho_que --org com.choque
cd cho_que
# Copy pubspec.yaml dependencies
flutter pub get

# 3. Configure
# - Update lib/config/constants.dart with Supabase credentials
# - Update VietMap API key
```

---

## 📊 Database Quick Ref

### Tables
| Table | Purpose |
|-------|---------|
| profiles | Users (extends auth.users) |
| shops | Restaurants/stores |
| products | Menu items (admin managed) |
| shop_products | Which products each shop sells |
| shop_product_overrides | Price/availability overrides |
| preset_locations | Fixed address list |
| fixed_pricing | Price by zone |
| orders | Order records |
| order_items | Food order items |
| order_events | Audit log |
| driver_locations | Real-time driver GPS |
| app_configs | Feature flags & settings |

### Key Views
| View | Purpose |
|------|---------|
| v_shop_menu | Menu with effective prices |
| v_available_drivers | Online drivers with location |

---

## 🔌 RPC Functions

### Customer
```dart
// Create order
await supabase.rpc('create_order', params: {...});

// Cancel (only PENDING)
await supabase.rpc('cancel_order_by_customer', params: {
  'p_order_id': orderId,
  'p_reason': reason,
});
```

### Admin
```dart
// Confirm
await supabase.rpc('confirm_order', params: {'p_order_id': orderId});

// Assign driver
await supabase.rpc('assign_driver', params: {
  'p_order_id': orderId,
  'p_driver_id': driverId,
});

// Reassign
await supabase.rpc('reassign_driver', params: {
  'p_order_id': orderId,
  'p_new_driver_id': newDriverId,
  'p_reason': reason,
});

// Cancel
await supabase.rpc('cancel_order_by_admin', params: {
  'p_order_id': orderId,
  'p_reason': reason,
});
```

### Driver
```dart
// Go online
await supabase.rpc('driver_go_online');

// Go offline
await supabase.rpc('driver_go_offline');

// Update status
await supabase.rpc('update_order_status', params: {
  'p_order_id': orderId,
  'p_new_status': 'PICKED_UP', // or 'COMPLETED'
});

// Update location
await supabase.rpc('update_driver_location', params: {
  'p_order_id': orderId,
  'p_lat': lat,
  'p_lng': lng,
});
```

### Merchant
```dart
// Override price/availability
await supabase.rpc('set_menu_override', params: {
  'p_shop_id': shopId,
  'p_product_id': productId,
  'p_price_override': 40000, // or null to use base
  'p_is_available': true,
});
```

---

## 📱 Order Status Flow

```
PENDING_CONFIRMATION → CONFIRMED → ASSIGNED → PICKED_UP → COMPLETED
         ↓                ↓           ↓          ↓
      CANCELED         CANCELED   CANCELED   CANCELED
   (by customer)     (by admin)  (by admin) (by admin)
```

### Who Can Do What
| Action | Who |
|--------|-----|
| Create order | Customer |
| Cancel PENDING | Customer |
| Confirm | Admin |
| Assign driver | Admin |
| Reassign | Admin |
| Cancel (any) | Admin |
| Update to PICKED_UP | Driver |
| Update to COMPLETED | Driver |

---

## 🔐 Roles Check

```dart
// In Flutter - check role from profile
final profile = await supabase.from('profiles')
    .select('roles')
    .eq('user_id', userId)
    .single();

final roles = List<String>.from(profile['roles']);
final isAdmin = roles.contains('super_admin');
final isDriver = roles.contains('driver');
final isMerchant = roles.contains('merchant');
```

---

## ⚙️ Config Flags

```dart
// Fetch config
final config = await supabase.rpc('get_config', params: {
  'p_market_id': 'huyen_demo'
});

// Access flags
final authMode = config['flags']['auth_mode']; // 'guest' or 'otp'
final addressMode = config['flags']['address_mode']; // 'preset' or 'vietmap'
final pricingMode = config['flags']['pricing_mode']; // 'fixed' or 'gps'
final trackingMode = config['flags']['tracking_mode']; // 'status' or 'realtime'
```

---

## 🚨 Error Codes

| Code | Message VN | Action |
|------|------------|--------|
| NOT_ALLOWED | Bạn không có quyền | Show message |
| INVALID_STATUS | Không thể thực hiện | Refresh order |
| CANNOT_CANCEL | Chỉ hủy khi chờ xác nhận | Show message |
| ORDER_NOT_FOUND | Không tìm thấy đơn | Go back |
| DRIVER_NOT_FOUND | Không tìm thấy tài xế | Admin retry |
| HAS_ACTIVE_ORDERS | Hoàn thành đơn trước | Show message |
| TIMEOUT | Kết nối chậm | Retry button |

---

## 📦 Key Packages

```yaml
# Must have
supabase_flutter: ^2.3.0
flutter_riverpod: ^2.4.9
geolocator: ^11.0.0
vietmap_flutter_gl: ^1.0.0
shared_preferences: ^2.2.2
connectivity_plus: ^5.0.2

# Optional
firebase_messaging: ^14.7.10  # Push notifications
hive_flutter: ^1.1.0          # Local cache
```

---

## 📍 Location Quick Ref

```dart
// Check permission
final permission = await Geolocator.checkPermission();

// Request permission
await Geolocator.requestPermission();

// Get current location
final position = await Geolocator.getCurrentPosition(
  desiredAccuracy: LocationAccuracy.high,
  timeLimit: Duration(seconds: 10),
);

// Stream location (for driver tracking)
Geolocator.getPositionStream(
  locationSettings: AndroidSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 50,
    intervalDuration: Duration(seconds: 30),
    foregroundNotificationConfig: ForegroundNotificationConfig(
      notificationTitle: 'Chợ Quê',
      notificationText: 'Đang giao hàng',
    ),
  ),
).listen((position) {
  // Upload to server
});
```

---

## 🎯 File Checklist

| File | Purpose | Status |
|------|---------|--------|
| 01-BRIEF-LOCKED.md | Product requirements | ✅ |
| 02-SCHEMA.sql | Database tables + RLS | ✅ |
| 03-RPC-FUNCTIONS.sql | Server functions | ✅ |
| 04-SEED-DATA.sql | Sample data | ✅ |
| 05-FLUTTER-STRUCTURE.md | Code organization | ✅ |
| 06-ROADMAP-4-WEEKS.md | Timeline + prompts | ✅ |
| 07-QUICK-REFERENCE.md | This file | ✅ |

---

## ✅ Daily Standup Template

```
Hôm qua:
- [ ] Task completed

Hôm nay:
- [ ] Task planned

Blockers:
- None / [Issue description]
```

---

## 🐛 Debug Checklist

### Supabase không connect
- [ ] Check URL + anon key
- [ ] Check network
- [ ] Check RLS policies

### RPC trả về error
- [ ] Check function exists
- [ ] Check parameter names (p_xxx)
- [ ] Check role permissions

### Location không lấy được
- [ ] Check permissions in manifest/plist
- [ ] Check runtime permission granted
- [ ] Check GPS enabled on device

### Foreground service bị kill (Android)
- [ ] Check foregroundServiceType in manifest
- [ ] Guide user to disable battery optimization
- [ ] Check Xiaomi/Huawei specific settings
