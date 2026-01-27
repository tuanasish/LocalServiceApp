# Thiết lập VietMap cho App Giao Đồ Ăn (Flutter + Supabase)

**Khu vực triển khai:** Huyện Nga Sơn, Thanh Hóa  
**Stack:** Flutter + Supabase + VietMap

---

## 1. Mục tiêu
- Hiển thị bản đồ cho khu vực Nga Sơn
- Chọn địa điểm giao/nhận (search + pin)
- Tính tuyến đường & ETA
- Theo dõi realtime vị trí shipper bằng Supabase

---

## 2. Cài đặt bản đồ VietMap cho Flutter

### 2.1. Thêm dependency
```yaml
dependencies:
  vietmap_flutter_gl: ^4.1.0
```
> Version tham chiếu theo pub.dev (publisher: maps.vietmap.vn)

---

### 2.2. Cấu hình Android
- `minSdkVersion: 24`
- Thêm JitPack vào `android/build.gradle`
```gradle
maven { url 'https://jitpack.io' }
```

---

### 2.3. Cấu hình iOS
- iOS minimum: `12.0`
- Thêm quyền location vào `Info.plist`
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Cần vị trí để giao đồ ăn</string>
```

---

### 2.4. Hiển thị bản đồ (widget tối giản)
```dart
import 'package:flutter/material.dart';
import 'package:vietmap_flutter_gl/vietmap_flutter_gl.dart';

class NgaSonMapPage extends StatefulWidget {
  const NgaSonMapPage({super.key});

  @override
  State<NgaSonMapPage> createState() => _NgaSonMapPageState();
}

class _NgaSonMapPageState extends State<NgaSonMapPage> {
  static const ngaSon = LatLng(20.00333, 105.97583);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Map - Nga Sơn')),
      body: VietmapGL(
        styleString:
          'https://maps.vietmap.vn/maps/styles/tm/style.json?apikey=YOUR_API_KEY',
        initialCameraPosition:
          const CameraPosition(target: ngaSon, zoom: 12),
      ),
    );
  }
}
```

---

## 3. Tìm kiếm địa chỉ & định tuyến (API Plugin)

### 3.1. Thêm plugin API
```yaml
dependencies:
  vietmap_flutter_plugin: ^1.0.0
```

---

### 3.2. Khởi tạo API
```dart
import 'package:vietmap_flutter_plugin/vietmap_flutter_plugin.dart';

Future<void> initVietmap() async {
  Vietmap.getInstance('YOUR_API_KEY');
}
```

---

### 3.3. Autocomplete địa chỉ (nhập địa điểm giao)
```dart
Future<void> searchAddress(String query) async {
  final result = await Vietmap.autocomplete(
    VietMapAutoCompleteParams(textSearch: query),
  );

  result.fold(
    (err) => print(err),
    (data) => print(data),
  );
}
```

---

## 4. Thiết kế Supabase cho app giao đồ ăn

### 4.1. Bảng `orders`
| field | type | note |
|------|-----|------|
| id | uuid | PK |
| pickup_lat | double | quán |
| pickup_lng | double | |
| drop_lat | double | khách |
| drop_lng | double | |
| status | text | pending / delivering / done |
| created_at | timestamp | |

---

### 4.2. Bảng `couriers`
| field | type | note |
|------|-----|------|
| id | uuid | shipper id |
| last_lat | double | realtime |
| last_lng | double | realtime |
| updated_at | timestamp | |

---

### 4.3. Luồng realtime
- App shipper: update vị trí mỗi 3–5s hoặc theo khoảng cách
- App khách/admin: subscribe bảng `couriers`
- Cập nhật marker trên bản đồ khi có event

---

## 5. Gợi ý kiến trúc tổng thể
```
Flutter App
 ├── VietMap GL (Map + Marker + Route)
 ├── VietMap API (Search / Route / ETA)
 ├── Supabase Auth
 ├── Supabase Realtime (shipper tracking)
 └── Supabase DB (orders, couriers)
```

---

## 6. Lỗi thường gặp
- **Map trắng:** sai API key hoặc hết quota
- **Android build fail:** thiếu JitPack hoặc SDK < 24
- **Không realtime:** chưa bật Realtime cho table Supabase
- **Marker lệch:** lat/lng đảo ngược

---

## 7. Bước tiếp theo (khuyến nghị)
- Vẽ route line cho shipper → khách
- Tính ETA & phí ship theo km
- Cache tile + debounce search
- Tách app Shipper / Customer nếu scale lớn

---

> Tài liệu tham khảo chính thức:
- SDK Flutter Map: https://maps.vietmap.vn/docs/sdk-mobile/Flutter/map/
- Flutter API Plugin: https://maps.vietmap.vn/docs/sdk-mobile/Flutter/api-plugin/
- Map API Overview: https://maps.vietmap.vn/docs/map-api/overview/

