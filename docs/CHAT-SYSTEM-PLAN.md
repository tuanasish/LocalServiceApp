# 💬 Kế hoạch Hoàn thiện Chat System - Chợ Quê

> **Mục tiêu:** Kết nối UI chat hiện có với backend Supabase, cho phép customer và driver chat real-time trong quá trình giao hàng.

---

## 📊 Tổng quan Hiện trạng

| Component | Trạng thái | % Hoàn thành |
|-----------|-----------|--------------|
| Chat UI Screen | ✅ Đã có | 100% |
| Chat Model | ❌ Chưa có | 0% |
| Chat Repository | ❌ Chưa có | 0% |
| Chat Provider | ❌ Chưa có | 0% |
| Database Schema | ❌ Chưa có | 0% |
| Real-time Stream | ❌ Chưa có | 0% |

---

## 🏗️ Kiến trúc Database

### Bảng `messages`

```sql
CREATE TABLE public.messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  sender_id uuid NOT NULL REFERENCES public.profiles(user_id) ON DELETE CASCADE,
  receiver_id uuid NOT NULL REFERENCES public.profiles(user_id) ON DELETE CASCADE,
  content text NOT NULL,
  message_type text NOT NULL DEFAULT 'text' CHECK (message_type IN ('text', 'system', 'location')),
  is_read boolean NOT NULL DEFAULT false,
  read_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX messages_order_idx ON public.messages(order_id, created_at DESC);
CREATE INDEX messages_sender_idx ON public.messages(sender_id, created_at DESC);
CREATE INDEX messages_receiver_idx ON public.messages(receiver_id, is_read, created_at DESC);
CREATE INDEX messages_unread_idx ON public.messages(receiver_id, is_read) WHERE is_read = false;

-- RLS Policies
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Users chỉ đọc được messages của orders họ liên quan
CREATE POLICY "Users read own order messages" ON public.messages
  FOR SELECT USING (
    sender_id = auth.uid() OR receiver_id = auth.uid()
  );

-- Users chỉ gửi được messages cho orders họ liên quan
CREATE POLICY "Users send own order messages" ON public.messages
  FOR INSERT WITH CHECK (
    sender_id = auth.uid() AND (
      EXISTS (
        SELECT 1 FROM public.orders o
        WHERE o.id = order_id
        AND (o.customer_id = auth.uid() OR o.driver_id = auth.uid())
      )
    )
  );

-- Users chỉ update được messages của mình (mark as read)
CREATE POLICY "Users update own messages" ON public.messages
  FOR UPDATE USING (receiver_id = auth.uid());

-- Service role full access
CREATE POLICY "Service role full access" ON public.messages
  FOR ALL USING (auth.role() = 'service_role');
```

### RPC Functions

```sql
-- Lấy messages của một order
CREATE OR REPLACE FUNCTION public.get_order_messages(
  p_order_id uuid
)
RETURNS TABLE (
  id uuid,
  sender_id uuid,
  receiver_id uuid,
  content text,
  message_type text,
  is_read boolean,
  created_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    m.id,
    m.sender_id,
    m.receiver_id,
    m.content,
    m.message_type,
    m.is_read,
    m.created_at
  FROM public.messages m
  WHERE m.order_id = p_order_id
  ORDER BY m.created_at ASC;
END;
$$;

-- Đánh dấu messages đã đọc
CREATE OR REPLACE FUNCTION public.mark_messages_as_read(
  p_order_id uuid,
  p_receiver_id uuid
)
RETURNS int
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_count int;
BEGIN
  UPDATE public.messages
  SET is_read = true,
      read_at = now()
  WHERE order_id = p_order_id
    AND receiver_id = p_receiver_id
    AND is_read = false;
  
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;
```

---

## 📋 GIAI ĐOẠN 1: Database & Models

### 1.1 Tạo Database Schema
- [ ] Tạo bảng `messages` với indexes và RLS policies
- [ ] Tạo RPC functions: `get_order_messages`, `mark_messages_as_read`
- [ ] Test RLS policies trong Supabase Dashboard

### 1.2 Tạo Chat Model
- [ ] Tạo `lib/data/models/chat_message_model.dart`
- [ ] Fields: `id`, `orderId`, `senderId`, `receiverId`, `content`, `messageType`, `isRead`, `createdAt`
- [ ] Methods: `fromJson`, `toJson`, `isFromCurrentUser` helper

---

## 📋 GIAI ĐOẠN 2: Repository & Provider

### 2.1 Chat Repository
- [ ] Tạo `lib/data/repositories/chat_repository.dart`
- [ ] Methods:
  - `getOrderMessages(String orderId)`: Lấy danh sách messages
  - `sendMessage(String orderId, String receiverId, String content)`: Gửi tin nhắn
  - `markAsRead(String orderId)`: Đánh dấu đã đọc
  - `streamMessages(String orderId)`: Stream real-time messages
  - `getUnreadCount(String orderId)`: Đếm tin nhắn chưa đọc

### 2.2 Chat Provider
- [ ] Tạo `chatRepositoryProvider` trong `app_providers.dart`
- [ ] Tạo `orderMessagesProvider` (FutureProvider.family)
- [ ] Tạo `orderMessagesStreamProvider` (StreamProvider.family)
- [ ] Tạo `orderUnreadCountProvider` (FutureProvider.family)

---

## 📋 GIAI ĐOẠN 3: UI Integration

### 3.1 Cập nhật CustomerDriverChatScreen
- [ ] Convert từ `StatefulWidget` sang `ConsumerStatefulWidget`
- [ ] Kết nối với `orderMessagesStreamProvider` để hiển thị messages real-time
- [ ] Kết nối `_buildInputBar` với `chatRepository.sendMessage`
- [ ] Cập nhật `_buildHeader` để hiển thị thông tin driver/customer thật
- [ ] Thêm loading state khi gửi message
- [ ] Thêm error handling
- [ ] Auto scroll to bottom khi có message mới
- [ ] Mark as read khi mở chat

### 3.2 Navigation Integration
- [ ] Cập nhật `simple_order_tracking_screen.dart` để navigate đến chat
- [ ] Pass `orderId` và `driverId`/`customerId` vào chat screen
- [ ] Thêm button "Chat với tài xế" trong order tracking

---

## 📋 GIAI ĐOẠN 4: Advanced Features (Optional)

### 4.1 System Messages
- [ ] Tự động gửi system message khi order status thay đổi
- [ ] Hiển thị system messages với style khác (centered, muted)

### 4.2 Location Sharing
- [ ] Thêm button "Chia sẻ vị trí" trong chat
- [ ] Gửi location message với type='location'
- [ ] Hiển thị location trên map trong chat bubble

### 4.3 Phone Call Integration
- [ ] Kết nối button phone trong header với `url_launcher`
- [ ] Gọi điện trực tiếp từ chat screen

---

## 🔧 Chi tiết Kỹ thuật

### ChatMessageModel

```dart
class ChatMessageModel {
  final String id;
  final String orderId;
  final String senderId;
  final String receiverId;
  final String content;
  final String messageType; // 'text', 'system', 'location'
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  const ChatMessageModel({
    required this.id,
    required this.orderId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.messageType = 'text',
    this.isRead = false,
    required this.createdAt,
    this.readAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      senderId: json['sender_id'] as String,
      receiverId: json['receiver_id'] as String,
      content: json['content'] as String,
      messageType: json['message_type'] as String? ?? 'text',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      readAt: json['read_at'] != null 
          ? DateTime.parse(json['read_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'message_type': messageType,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
    };
  }

  bool isFromUser(String userId) => senderId == userId;
  bool isSystemMessage() => messageType == 'system';
}
```

### ChatRepository

```dart
class ChatRepository {
  final SupabaseClient _client;

  ChatRepository(this._client);

  factory ChatRepository.instance() {
    return ChatRepository(Supabase.instance.client);
  }

  /// Lấy messages của order
  Future<List<ChatMessageModel>> getOrderMessages(String orderId) async {
    final response = await _client.rpc(
      'get_order_messages',
      params: {'p_order_id': orderId},
    ).timeout(AppConstants.apiTimeout);

    return (response as List)
        .map((json) => ChatMessageModel.fromJson(json))
        .toList();
  }

  /// Gửi message
  Future<ChatMessageModel> sendMessage({
    required String orderId,
    required String receiverId,
    required String content,
    String messageType = 'text',
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final response = await _client
        .from('messages')
        .insert({
          'order_id': orderId,
          'sender_id': userId,
          'receiver_id': receiverId,
          'content': content.trim(),
          'message_type': messageType,
        })
        .select()
        .single()
        .timeout(AppConstants.apiTimeout);

    return ChatMessageModel.fromJson(response);
  }

  /// Stream messages real-time
  Stream<List<ChatMessageModel>> streamMessages(String orderId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('order_id', orderId)
        .order('created_at', ascending: true)
        .map((data) => (data as List)
            .map((json) => ChatMessageModel.fromJson(json))
            .toList());
  }

  /// Đánh dấu đã đọc
  Future<int> markAsRead(String orderId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final response = await _client.rpc(
      'mark_messages_as_read',
      params: {
        'p_order_id': orderId,
        'p_receiver_id': userId,
      },
    ).timeout(AppConstants.apiTimeout);

    return response as int;
  }

  /// Đếm tin nhắn chưa đọc
  Future<int> getUnreadCount(String orderId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return 0;

    final response = await _client
        .from('messages')
        .select('id')
        .eq('order_id', orderId)
        .eq('receiver_id', userId)
        .eq('is_read', false)
        .timeout(AppConstants.apiTimeout);

    return (response as List).length;
  }
}
```

---

## 📱 Thứ tự Thực hiện

```
Ngày 1:
├── Sáng: Tạo database schema (bảng messages, RPC functions)
├── Chiều: Tạo ChatMessageModel và ChatRepository
└── Tối: Test repository với Supabase

Ngày 2:
├── Sáng: Tạo providers (chatRepositoryProvider, orderMessagesStreamProvider)
├── Chiều: Cập nhật CustomerDriverChatScreen - kết nối với providers
└── Tối: Test real-time stream và gửi message

Ngày 3:
├── Sáng: Navigation integration (từ order tracking vào chat)
├── Chiều: Mark as read, unread count, error handling
└── Tối: Polish UI, loading states, empty states

Ngày 4 (Optional):
├── System messages
├── Location sharing
└── Phone call integration
```

---

## ✅ Definition of Done

Mỗi tính năng được coi là **Hoàn thành** khi:

1. ✅ Database schema đã tạo và test RLS policies
2. ✅ Repository methods hoạt động đúng với Supabase
3. ✅ Real-time stream cập nhật messages tự động
4. ✅ UI hiển thị messages từ database, không có mock data
5. ✅ Gửi message thành công và hiển thị ngay lập tức
6. ✅ Mark as read hoạt động khi mở chat
7. ✅ Loading states được xử lý (sending indicator)
8. ✅ Error states được xử lý (thông báo lỗi thân thiện)
9. ✅ Auto scroll to bottom khi có message mới
10. ✅ Không có lỗi khi chạy `flutter analyze`
11. ✅ Đã test trên emulator/thiết bị thật

---

## 🚀 Bước Tiếp theo

**Sau khi hoàn thành Chat System:**
1. **Reviews & Ratings** - Cho phép customer đánh giá sau khi nhận hàng
2. **Favorites** - Lưu cửa hàng yêu thích
3. **Reorder** - Đặt lại đơn hàng cũ nhanh chóng
4. **Search Enhancement** - Tìm kiếm sản phẩm/cửa hàng nâng cao

---

*Tài liệu tạo: 26/01/2026*
