# CHỢ QUÊ MVP - BRIEF LOCKED v1.1

> **Scope**: 1 huyện | **Timeline**: 4 tuần | **Team**: 1-2 dev + AI  
> **Updated**: 22/01/2026 - Simplified to Food Delivery only + Promotions

---

## 1. SẢN PHẨM

**Chợ Quê** = App giao đồ ăn cho nông thôn Việt Nam

### Dịch vụ MVP (Chỉ Food Delivery)
| Service | Mô tả | Flow |
|---------|-------|------|
| **Food** | Đặt đồ ăn từ quán | Chọn quán → Chọn món → Đặt → Giao |

### Tính năng Growth
| Feature | Mô tả |
|---------|-------|
| **Freeship đơn đầu** | Tự động miễn phí ship cho customer mới |
| **Voucher code** | Nhập mã giảm giá (GIAM10K, SALE20...) |
| **Excel import** | Admin import menu từ file CSV/Excel |

### Nguyên tắc thiết kế
- **Đơn giản**: Nút to, chữ rõ, ít bước
- **Mạng yếu**: Offline-first, cache, retry
- **Chi phí thấp**: Preset locations, fixed pricing

---

## 2. STACK ĐÃ CHỐT

| Layer | Tech | Package |
|-------|------|---------|
| Client | Flutter | `flutter 3.x` |
| Backend | Supabase | `supabase_flutter` |
| Map | VietMap | `vietmap_flutter_gl` |
| GPS | Geolocator | `geolocator` |
| Push | FCM | `firebase_messaging` |

---

## 3. VAI TRÒ & QUYỀN

| Vai trò | Quyền MVP |
|---------|-----------|
| **Super Admin** | Toàn quyền: config, menu, đơn, tài xế, shop |
| **Merchant** | Chỉ: override giá, bật/tắt món của shop mình |
| **Driver** | Chỉ: xem đơn được gán, update status, gửi location |
| **Customer** | Chỉ: tạo đơn, xem đơn mình, hủy khi PENDING |

---

## 4. FEATURE FLAGS (Remote Config)

| Flag | Options | MVP Default |
|------|---------|-------------|
| `auth_mode` | `guest` / `otp` | `guest` |
| `address_mode` | `preset` / `vietmap` | `preset` |
| `pricing_mode` | `fixed` / `gps` | `fixed` |
| `tracking_mode` | `status` / `realtime` | `status` |
| `dispatch_mode` | `admin` / `auto` | `admin` |

---

## 5. STATE MACHINE - ĐƠN HÀNG

```
PENDING_CONFIRMATION
    │
    ├─[Customer cancel]──→ CANCELED
    │
    └─[Admin confirm]──→ CONFIRMED
                              │
                              ├─[Admin cancel]──→ CANCELED
                              │
                              └─[Admin assign]──→ ASSIGNED
                                                     │
                                                     ├─[Admin cancel/reassign]
                                                     │
                                                     └─[Driver pickup]──→ PICKED_UP
                                                                              │
                                                                              └─[Driver arrive]──→ COMPLETED
```

**Trạng thái Driver:**
```
OFFLINE ←→ ONLINE ←→ BUSY (có đơn active)
```

---

## 6. USER FLOWS

### Customer Flow
```
1. Mở app → Home (3 nút: Food/Ride/Delivery)
2. Chọn service
3. Chọn điểm đón (preset dropdown hoặc VietMap)
4. Chọn điểm trả
5. [Food] Chọn quán → Chọn món
6. Xem giá → Xác nhận
7. Theo dõi trạng thái
8. [Có thể hủy nếu PENDING_CONFIRMATION]
```

### Driver Flow
```
1. Đăng nhập
2. Bật Online
3. Nhận notification khi được gán đơn
4. Xem chi tiết đơn
5. Cập nhật: PICKED_UP → COMPLETED
6. [Nếu bật tracking] Gửi location mỗi 30s
```

### Admin Flow
```
1. Đăng nhập
2. Tab Pending: Xem đơn mới → Confirm
3. Tab Confirmed: Chọn driver → Assign
4. Tab Active: Giám sát, can thiệp nếu cần
5. Menu: CRUD products, assign to shops
```

---

## 7. OUT OF SCOPE (MVP)

❌ Live map tracking cho customer  
❌ Auto-dispatch (gần nhất)  
❌ Chat  
❌ Rating/Review  
❌ Thanh toán online  
❌ Multi-drop  
❌ Scheduled orders  
❌ Ride service (xe ôm)  
❌ Delivery service (giao hàng hộ)  

---

## 8. ACCEPTANCE CRITERIA

### Must Pass
- [ ] Guest tạo đơn thành công
- [ ] Customer hủy được khi PENDING, không hủy được sau CONFIRMED
- [ ] Admin confirm → assign → driver thấy đơn
- [ ] Driver update status đúng thứ tự
- [ ] Mạng yếu: app không crash, có retry
- [ ] Offline: hiện cached data, không block UI

### Performance
- [ ] App load < 3s on 3G
- [ ] Order create < 5s
- [ ] Status update < 2s

---

## 9. COST ESTIMATE (10K MAU)

| Service | Cost/month |
|---------|------------|
| Supabase Free | $0 |
| VietMap | ~2-3M VND |
| FCM | $0 |
| SMS (nếu OTP) | ~500 VND/OTP |
| **TOTAL** | **~3M VND** |

---

## 10. RISKS & MITIGATION

| Risk | Mitigation |
|------|------------|
| VietMap API down | Fallback to preset-only |
| SMS OTP fail | Start with Guest mode |
| Driver GPS drain | Distance filter 50m, interval 30s |
| Xiaomi/Huawei kill app | Guide user to whitelist |
