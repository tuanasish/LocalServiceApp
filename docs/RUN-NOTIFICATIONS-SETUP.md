# Hướng dẫn chạy SQL Migration cho Notifications

## Cách 1: Chạy trong Supabase Dashboard (Khuyến nghị)

1. Mở Supabase Dashboard: https://supabase.com/dashboard
2. Chọn project của bạn (ref: `ipdwpzgbznphkmdewjdl`)
3. Vào **SQL Editor** (menu bên trái)
4. Click **New Query**
5. Copy toàn bộ nội dung file `docs/NOTIFICATIONS-SETUP.sql`
6. Paste vào SQL Editor
7. Click **Run** hoặc nhấn `Ctrl+Enter`

## Cách 2: Sử dụng Supabase CLI

```bash
# Nếu bạn đã cài Supabase CLI
supabase db push --file docs/NOTIFICATIONS-SETUP.sql
```

## Nội dung sẽ được tạo:

✅ **Bảng `notifications`** với các columns:
- `id` (uuid, primary key)
- `user_id` (uuid, foreign key to profiles)
- `title` (text)
- `body` (text)
- `type` (text: 'order', 'promo', 'system')
- `is_read` (boolean)
- `data` (jsonb)
- `created_at` (timestamptz)
- `read_at` (timestamptz)

✅ **Indexes**:
- `notifications_user_idx` - Tối ưu query theo user và thời gian
- `notifications_unread_idx` - Tối ưu query unread notifications

✅ **RLS Policies**:
- Users chỉ đọc được notifications của mình
- Users chỉ update được notifications của mình
- Service role có full access

✅ **RPC Functions**:
- `create_notification()` - Tạo notification cho 1 user
- `create_broadcast_notification()` - Tạo notification cho nhiều users

## Kiểm tra sau khi chạy:

```sql
-- Kiểm tra bảng đã tồn tại
SELECT * FROM public.notifications LIMIT 1;

-- Kiểm tra functions đã được tạo
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
  AND routine_name LIKE '%notification%';

-- Kiểm tra indexes
SELECT indexname 
FROM pg_indexes 
WHERE schemaname = 'public' 
  AND tablename = 'notifications';
```

## Lưu ý:

- File SQL sử dụng `CREATE IF NOT EXISTS` và `DROP POLICY IF EXISTS` nên an toàn khi chạy lại
- Không ảnh hưởng đến dữ liệu hiện có
- FCM push notification cần được implement trong backend service (không thể gửi từ SQL)
