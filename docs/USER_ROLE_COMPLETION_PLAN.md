# 🎯 Kế hoạch Hoàn thiện User Role — Chợ Quê

> **Mục tiêu:** Biến 100% dữ liệu giả thành dữ liệu thật từ Supabase. Mọi chức năng của vai trò **Customer (User)** phải hoạt động end-to-end.

---

## 📊 Tổng quan Hiện trạng

| Module | Trạng thái | % Hoàn thành |
|--------|-----------|--------------|
| Auth & Profile | ✅ Xong | 95% |
| Home & Discover | ⚠️ Đang làm | 60% |
| Store Detail & Menu | ⚠️ Dữ liệu giả | 40% |
| Giỏ hàng (Cart) | ⚠️ Provider có, chưa kết nối | 30% |
| Checkout | ⚠️ Dữ liệu giả | 20% |
| Đặt hàng & Thanh toán | ❌ Chưa làm | 0% |
| Lịch sử đơn hàng | ⚠️ Dữ liệu giả | 30% |
| Theo dõi đơn hàng | ❌ Chưa làm | 0% |
| Thông báo | ⚠️ Dữ liệu giả | 20% |
| Địa chỉ | ⚠️ Provider có, chưa kết nối | 50% |
| Thanh toán Online | ❌ Chưa làm | 0% |

---

## 🏗️ Kiến trúc Dữ liệu Supabase

### Bảng Cần Sử dụng

```
profiles          ✅ Đã có
addresses         ✅ Đã có RLS
merchants         ✅ Đã có
products          ✅ Đã có
orders            ✅ Đã có
order_items       ✅ Đã có
notifications     ⚠️ Cần kiểm tra
payments          ❌ Cần tạo (nếu cần)
reviews           ❌ Cần tạo
favorites         ❌ Cần tạo
```

---

## 📋 GIAI ĐOẠN 1: Kết nối Dữ liệu Cơ bản
> **Ưu tiên: CAO** | Thời gian: 2-3 ngày

### 1.1 Store Detail — Dữ liệu thật
- [ ] Kết nối `StoreDetailMenuScreen` với `merchantDetailProvider`
- [ ] Kết nối menu với `shopMenuProvider`
- [ ] Hiển thị rating, giờ mở cửa, khoảng cách thực

### 1.2 Cart Logic — Hoàn thiện
- [ ] Kết nối `MenuItemCard.onAddTap` với `cartProvider`
- [ ] Cập nhật `CartSummaryBar` để đọc từ `cartProvider`
- [ ] Thêm animation khi thêm/xóa món
- [ ] Badge số lượng trên icon giỏ hàng ở Header

### 1.3 Checkout — Dữ liệu thật
- [ ] Kết nối `CheckoutFixedFeeScreen` với `cartProvider`
- [ ] Hiển thị danh sách món thực tế
- [ ] Kết nối với `addressProvider` để chọn địa chỉ
- [ ] Tính toán phí giao hàng thực

---

## 📋 GIAI ĐOẠN 2: Đặt hàng & Theo dõi
> **Ưu tiên: CAO** | Thời gian: 3-4 ngày

### 2.1 Tạo Đơn hàng
- [ ] Tạo `OrderNotifier` để xử lý đặt hàng
- [ ] Gọi `orderRepository.createOrder()` khi đặt hàng
- [ ] Xử lý các trạng thái: pending → confirmed → preparing → delivering → completed
- [ ] Hiển thị màn hình thành công với mã đơn hàng

### 2.2 Lịch sử Đơn hàng — Dữ liệu thật
- [ ] Kết nối `OrderHistoryScreen` với `myOrdersProvider`
- [ ] Filter theo trạng thái thực tế
- [ ] Pull-to-refresh để cập nhật
- [ ] Tap vào đơn → màn hình chi tiết

### 2.3 Theo dõi Đơn hàng Real-time
- [ ] Tạo `orderTrackingProvider` với Supabase Realtime
- [ ] Cập nhật `SimpleOrderTrackingScreen` với dữ liệu live
- [ ] Hiển thị timeline: Đặt hàng → Xác nhận → Đang nấu → Đang giao → Hoàn thành
- [ ] Push notification khi trạng thái thay đổi

---

## 📋 GIAI ĐOẠN 3: Địa chỉ & Thông báo
> **Ưu tiên: TRUNG BÌNH** | Thời gian: 2-3 ngày

### 3.1 Hệ thống Địa chỉ
- [ ] Kết nối `SavedAddressesScreen` với `addressProvider`
- [ ] Kết nối `AddAddressScreen` với `addressProvider.addAddress()`
- [ ] Thêm tính năng chọn địa chỉ mặc định
- [ ] (Nâng cao) Tích hợp Map picker với Google Maps

### 3.2 Thông báo — Dữ liệu thật
- [ ] Tạo bảng `notifications` trong Supabase (nếu chưa có)
- [ ] Tạo `NotificationModel` và `NotificationRepository`
- [ ] Tạo `notificationsProvider`
- [ ] Kết nối `NotificationsScreen` với provider
- [ ] Đánh dấu đã đọc khi tap
- [ ] Badge số thông báo chưa đọc trên Bottom Nav

---

## 📋 GIAI ĐOẠN 4: Tính năng Nâng cao
> **Ưu tiên: THẤP** | Thời gian: 3-5 ngày

### 4.1 Thanh toán Online (Mô phỏng)
- [ ] Tạo màn hình chọn phương thức thanh toán
- [ ] Xử lý 3 loại: COD, Ví điện tử (mô phỏng), Thẻ (mô phỏng)
- [ ] Cập nhật trạng thái thanh toán trong đơn hàng

### 4.2 Đánh giá & Yêu thích
- [ ] Tạo bảng `reviews` và `favorites`
- [ ] Thêm nút đánh giá sau khi hoàn thành đơn
- [ ] Thêm nút yêu thích cửa hàng
- [ ] Hiển thị danh sách yêu thích trong Profile

### 4.3 Tìm kiếm & Lọc
- [ ] Kết nối `AppSearchBar` với `productSearchProvider`
- [ ] Thêm màn hình kết quả tìm kiếm
- [ ] Lọc theo: Khoảng cách, Rating, Giá, Danh mục

### 4.4 Voucher & Khuyến mãi
- [ ] Tạo bảng `vouchers` trong Supabase
- [ ] Màn hình danh sách voucher
- [ ] Áp dụng voucher khi checkout
- [ ] Tính toán giảm giá

---

## 🔧 Chi tiết Kỹ thuật

### Models Cần Tạo/Cập nhật

```dart
// lib/models/notification.dart
class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type; // order, promo, system
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data;
}

// lib/models/review.dart
class ReviewModel {
  final String id;
  final String userId;
  final String merchantId;
  final String orderId;
  final int rating;
  final String? comment;
  final DateTime createdAt;
}

// lib/models/voucher.dart
class VoucherModel {
  final String id;
  final String code;
  final String title;
  final double discountPercent;
  final double? maxDiscount;
  final double? minOrderValue;
  final DateTime expiresAt;
}
```

### Providers Cần Tạo

```dart
// Notifications
final notificationsProvider = FutureProvider<List<NotificationModel>>(...);
final unreadCountProvider = Provider<int>(...);

// Reviews
final merchantReviewsProvider = FutureProvider.family<List<ReviewModel>, String>(...);
final myReviewsProvider = FutureProvider<List<ReviewModel>>(...);

// Favorites
final favoritesProvider = FutureProvider<List<String>>(...); // merchant IDs
final isFavoriteProvider = Provider.family<bool, String>(...);

// Vouchers
final availableVouchersProvider = FutureProvider<List<VoucherModel>>(...);
```

---

## 📱 Thứ tự Thực hiện Đề xuất

```
Tuần 1:
├── Ngày 1-2: Store Detail + Menu (dữ liệu thật)
├── Ngày 3-4: Cart Logic hoàn chỉnh
└── Ngày 5: Checkout connected

Tuần 2:
├── Ngày 1-2: Order creation flow
├── Ngày 3: Order history (dữ liệu thật)
└── Ngày 4-5: Real-time order tracking

Tuần 3:
├── Ngày 1-2: Address system complete
├── Ngày 3: Notifications system
└── Ngày 4-5: Polish & Testing

Tuần 4 (Optional):
├── Reviews & Favorites
├── Search & Filter
└── Voucher system
```

---

## ✅ Định nghĩa Hoàn thành (Definition of Done)

Mỗi tính năng được coi là **Hoàn thành** khi:

1. ✅ Dữ liệu được lấy từ Supabase, không có hardcode
2. ✅ Loading states được xử lý (shimmer/skeleton)
3. ✅ Error states được xử lý (thông báo lỗi thân thiện)
4. ✅ Empty states được xử lý (UI khi không có dữ liệu)
5. ✅ Pull-to-refresh hoạt động (nếu có thể áp dụng)
6. ✅ Không có lỗi khi chạy `flutter analyze`
7. ✅ Đã test trên emulator/thiết bị thật

---

## 🚀 Bước Tiếp theo

**Khuyến nghị bắt đầu với:**
1. **Store Detail + Menu** — Vì đây là điểm chạm đầu tiên với sản phẩm
2. **Cart Logic** — Tiếp nối tự nhiên từ menu
3. **Checkout + Order creation** — Hoàn thành luồng mua hàng

> Bạn muốn tôi bắt đầu thực hiện từ phần nào?
