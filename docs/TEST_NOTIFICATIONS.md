# Hướng dẫn Kiểm tra Thông báo (Test Push Notifications)

Dưới đây là các bước để bạn kiểm tra xem hệ thống thông báo đã hoạt động chưa.

## Bước 1: Khởi động App và Lấy Token
1. Chạy app trên điện thoại hoặc giả lập.
2. Đăng nhập bằng tài khoản **Tài xế (Driver)**.
3. Khi app mở, nó sẽ yêu cầu quyền thông báo. Hãy nhấn **Cho phép (Allow)**.
4. App sẽ tự động gửi FCM Token lên bảng `fcm_tokens` trong Supabase.

## Bước 2: Kiểm tra Database
1. Mở Supabase Dashboard -> Table Editor.
2. Kiểm tra bảng `fcm_tokens`. Bạn sẽ thấy một dòng mới chứa `user_id` của bạn và một đoạn code `token` dài. Nếu thấy dòng này nghĩa là App đã kết nối thành công với Firebase và Supabase.

## Bước 3: Test bắn thông báo bằng SQL (Dễ nhất)
Bạn có thể giả lập hệ thống bắn thông báo bằng cách chạy lệnh SQL sau trong **Supabase SQL Editor**:

```sql
-- Thay 'ID_CUA_BAN' bằng user_id của tài khoản driver bạn đang dùng
INSERT INTO public.notifications (
  user_id,
  type,
  title,
  body,
  data
) VALUES (
  'ID_CUA_BAN', -- <--- Copy user_id từ bảng profiles vào đây
  'system_alert',
  'Thông báo Test',
  'Đây là thông báo kiểm tra từ hệ thống!',
  '{"test": true}'
);
```

**Kết quả mong đợi:**
- Trên App: Icon chuông sẽ hiện số 1 đỏ.
- Nhấn vào chuông: Bạn sẽ thấy thông báo này trong danh sách.

## Bước 4: Test Triggers (Thực tế)
Thử thực hiện các hành động thực tế để xem trigger có chạy không:
1. **Gán đơn hàng:** Cập nhật một đơn hàng trong bảng `orders`, set `driver_id` là ID của bạn và set `status = 'assigned'`.
2. **Duyệt tài xế:** Cập nhật bảng `profiles`, thay đổi `driver_approval_status` từ `pending` sang `approved`.

## Bước 5: Test Push thực tế (Cần Edge Function)
Để nhận được thông báo "nổi" lên màn hình điện thoại (Push Notification), chúng ta cần deploy Edge Function `send-notification`. Nếu bạn muốn tôi làm phần này ngay bây giờ, hãy báo tôi nhé!

---
**Lưu ý:** Hiện tại bạn có thể test phần "Thông báo trong app" (In-app notifications) ngay lập tức sau khi chạy app.
