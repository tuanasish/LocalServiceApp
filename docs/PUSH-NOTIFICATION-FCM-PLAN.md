# Kế hoạch Push Notification System với FCM

## Tổng quan

Triển khai hệ thống push notification với Firebase Cloud Messaging (FCM) để gửi thông báo real-time cho user về:
- **Order updates**: Đơn hàng được xác nhận, đang giao, hoàn thành
- **Promotions**: Khuyến mãi mới, voucher
- **System**: Thông báo hệ thống, cửa hàng mới

## Hiện trạng

### Đã có
- Database: `profiles` table đã có `fcm_token` và `device_id` columns
- Models: `ProfileModel` và `UserProfile` đã có `fcmToken` field
- Auth: `AuthNotifier.updateFcmToken()` method đã có nhưng chưa được gọi
- UI: `NotificationsScreen` đã có UI với filters nhưng đang hardcode data

### Chưa có
- Firebase/FCM packages chưa được thêm vào `pubspec.yaml`
- Firebase initialization chưa có trong `main.dart`
- Bảng `notifications` chưa có trong database
- `NotificationModel` và `NotificationRepository` chưa có
- `NotificationService` để handle FCM chưa có
- Providers cho notifications chưa có
- Logic xử lý notification khi app mở/đóng chưa có

## Chi tiết triển khai

### 1. Thêm Firebase/FCM Dependencies

**File**: `choque/pubspec.yaml`

Thêm các packages cần thiết:

```yaml
dependencies:
  # ... existing dependencies
  firebase_core: ^3.6.0
  firebase_messaging: ^15.1.3
  flutter_local_notifications: ^18.0.1  # For local notifications
```

### 2. Tạo Notifications Table trong Database

**File**: `docs/02-SCHEMA.sql` (thêm vào cuối file)

```sql
-- ============================================
-- NOTIFICATIONS TABLE
-- ============================================

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  title text not null,
  body text not null,
  type text not null, -- 'order', 'promo', 'system'
  is_read boolean not null default false,
  data jsonb, -- Additional data: {order_id, promotion_id, etc.}
  created_at timestamptz not null default now(),
  read_at timestamptz
);

create index notifications_user_idx on public.notifications(user_id, created_at desc);
create index notifications_unread_idx on public.notifications(user_id, is_read) where is_read = false;

-- RLS Policies
alter table public.notifications enable row level security;

create policy "Users read own notifications" on public.notifications 
  for select using (user_id = auth.uid());

create policy "Users update own notifications" on public.notifications 
  for update using (user_id = auth.uid());

create policy "Service role full access" on public.notifications 
  for all using (auth.role() = 'service_role');
```

**File**: `docs/MIGRATION-ALL-CHANGES.sql` (thêm vào cuối)

```sql
-- ============================================
-- 9. TẠO BẢNG NOTIFICATIONS
-- ============================================

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  title text not null,
  body text not null,
  type text not null,
  is_read boolean not null default false,
  data jsonb,
  created_at timestamptz not null default now(),
  read_at timestamptz
);

create index if not exists notifications_user_idx on public.notifications(user_id, created_at desc);
create index if not exists notifications_unread_idx on public.notifications(user_id, is_read) where is_read = false;

alter table public.notifications enable row level security;

drop policy if exists "Users read own notifications" on public.notifications;
drop policy if exists "Users update own notifications" on public.notifications;
drop policy if exists "Service role full access" on public.notifications;

create policy "Users read own notifications" on public.notifications 
  for select using (user_id = auth.uid());

create policy "Users update own notifications" on public.notifications 
  for update using (user_id = auth.uid());

create policy "Service role full access" on public.notifications 
  for all using (auth.role() = 'service_role');
```

### 3. Tạo NotificationModel

**File**: `choque/lib/data/models/notification_model.dart` (tạo mới)

```dart
/// Notification Model
/// 
/// Ánh xạ bảng `notifications` trong Supabase.
class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type; // 'order', 'promo', 'system'
  final bool isRead;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final DateTime? readAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.isRead = false,
    this.data,
    required this.createdAt,
    this.readAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: json['type'] as String,
      isRead: json['is_read'] as bool? ?? false,
      data: json['data'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      readAt: json['read_at'] != null 
          ? DateTime.parse(json['read_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type,
      'is_read': isRead,
      'data': data,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    String? type,
    bool? isRead,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }
}
```

### 4. Tạo NotificationRepository

**File**: `choque/lib/data/repositories/notification_repository.dart` (tạo mới)

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import '../../config/constants.dart';

/// Notification Repository
/// 
/// Xử lý các thao tác liên quan đến notifications.
class NotificationRepository {
  final SupabaseClient _client;

  NotificationRepository(this._client);

  factory NotificationRepository.instance() {
    return NotificationRepository(Supabase.instance.client);
  }

  /// Lấy danh sách notifications của user
  Future<List<NotificationModel>> getMyNotifications({
    String? type,
    int limit = 50,
  }) async {
    var query = _client
        .from('notifications')
        .select()
        .order('created_at', ascending: false)
        .limit(limit)
        .timeout(AppConstants.apiTimeout);

    if (type != null && type != 'Tất cả') {
      query = query.eq('type', type.toLowerCase());
    }

    final response = await query;
    return (response as List)
        .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Đánh dấu notification là đã đọc
  Future<void> markAsRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({
          'is_read': true,
          'read_at': DateTime.now().toIso8601String(),
        })
        .eq('id', notificationId)
        .timeout(AppConstants.apiTimeout);
  }

  /// Đánh dấu tất cả notifications là đã đọc
  Future<void> markAllAsRead() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client
        .from('notifications')
        .update({
          'is_read': true,
          'read_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', userId)
        .eq('is_read', false)
        .timeout(AppConstants.apiTimeout);
  }

  /// Đếm số notifications chưa đọc
  Future<int> getUnreadCount() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return 0;

    final response = await _client
        .from('notifications')
        .select('id', const FetchOptions(count: CountOption.exact))
        .eq('user_id', userId)
        .eq('is_read', false)
        .timeout(AppConstants.apiTimeout);

    return response.count ?? 0;
  }

  /// Stream notifications real-time
  Stream<List<NotificationModel>> streamNotifications() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return Stream.value([]);
    }

    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) {
          return (data as List)
              .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
              .toList();
        });
  }
}
```

### 5. Tạo NotificationService

**File**: `choque/lib/services/notification_service.dart` (tạo mới)

```dart
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/supabase_client.dart';
import '../providers/auth_provider.dart';

/// Notification Service
/// 
/// Xử lý FCM push notifications và local notifications.
class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Initialize FCM và Local Notifications
  static Future<void> initialize(WidgetRef ref) async {
    if (_initialized) return;

    // Request permissions
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      return; // User denied permissions
    }

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Get FCM token và lưu vào database
    final token = await _firebaseMessaging.getToken();
    if (token != null) {
      await ref.read(authNotifierProvider.notifier).updateFcmToken(token);
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      ref.read(authNotifierProvider.notifier).updateFcmToken(newToken);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundMessage(message, ref);
    });

    // Handle background messages (khi app đóng)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message, ref);
    });

    // Check if app opened from notification
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage, ref);
    }

    _initialized = true;
  }

  /// Handle notification khi app đang mở (foreground)
  static Future<void> _handleForegroundMessage(
    RemoteMessage message,
    WidgetRef ref,
  ) async {
    // Hiển thị local notification
    await _showLocalNotification(message);

    // Invalidate providers để refresh
    ref.invalidate(notificationsProvider(null));
    ref.invalidate(unreadNotificationsCountProvider);
  }

  /// Handle khi user tap vào notification
  static void _onNotificationTapped(NotificationResponse response) {
    // Navigate to appropriate screen based on notification data
    // Có thể dùng GoRouter hoặc Navigator
  }

  /// Handle notification tap (từ FCM)
  static void _handleNotificationTap(RemoteMessage message, WidgetRef ref) {
    final data = message.data;
    final type = data['type'] as String?;

    // Navigate based on type
    // if (type == 'order') {
    //   final orderId = data['order_id'];
    //   // Navigate to order tracking
    // }
  }

  /// Hiển thị local notification
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final androidDetails = AndroidNotificationDetails(
      'choque_notifications',
      'Chợ Quê Notifications',
      channelDescription: 'Thông báo từ Chợ Quê',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Thông báo',
      message.notification?.body ?? '',
      details,
      payload: message.data.toString(),
    );
  }

  /// Subscribe to topic (optional - cho broadcast notifications)
  static Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  /// Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }
}

/// Background message handler (phải là top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background message
  // Có thể lưu vào database hoặc xử lý logic khác
}
```

### 6. Cập nhật main.dart

**File**: `choque/lib/main.dart`

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
// ... other imports
import 'services/notification_service.dart';

// Background message handler (top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Handle background message
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Register background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  // Load environment variables
  await dotenv.load(fileName: '.env');
  
  // ... existing initialization code
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // Initialize notification service sau khi app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.initialize(ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    
    return MaterialApp.router(
      title: 'Chợ Quê',
      routerConfig: router,
      // ... existing code
    );
  }
}
```

### 7. Tạo Notification Providers

**File**: `choque/lib/providers/app_providers.dart`

Thêm vào cuối file:

```dart
// ============================================
// NOTIFICATION PROVIDERS
// ============================================

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(supabaseClientProvider));
});

/// Danh sách notifications của user
final notificationsProvider = FutureProvider.family<List<NotificationModel>, String?>((ref, type) async {
  return ref.watch(notificationRepositoryProvider).getMyNotifications(type: type);
});

/// Stream notifications real-time
final notificationsStreamProvider = StreamProvider<List<NotificationModel>>((ref) {
  return ref.watch(notificationRepositoryProvider).streamNotifications();
});

/// Số lượng notifications chưa đọc
final unreadNotificationsCountProvider = FutureProvider<int>((ref) async {
  return ref.watch(notificationRepositoryProvider).getUnreadCount();
});
```

### 8. Cập nhật NotificationsScreen

**File**: `choque/lib/screens/notifications/notifications_screen.dart`

Chuyển từ `StatefulWidget` sang `ConsumerStatefulWidget` và kết nối với providers:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_providers.dart';
import '../../data/models/notification_model.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  int _selectedFilter = 0;
  final Map<int, String?> _filterTypes = {
    0: null, // 'Tất cả'
    1: 'order', // 'Đơn hàng'
    2: 'promo', // 'Khuyến mãi'
    3: 'system', // 'Hệ thống'
  };

  @override
  Widget build(BuildContext context) {
    final filterType = _filterTypes[_selectedFilter];
    final notificationsAsync = ref.watch(notificationsProvider(filterType));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilterTabs(),
            Expanded(
              child: notificationsAsync.when(
                data: (notifications) {
                  if (notifications.isEmpty) {
                    return _buildEmptyState();
                  }
                  return RefreshIndicator(
                    onRefresh: () => ref.refresh(notificationsProvider(filterType).future),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildNotificationItem(notifications[index]),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _buildErrorState(error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    // Map type to icon và color
    IconData icon;
    Color color;
    switch (notification.type) {
      case 'order':
        icon = Icons.local_shipping_outlined;
        color = AppColors.primary;
        break;
      case 'promo':
        icon = Icons.local_offer_outlined;
        color = const Color(0xFFF59E0B);
        break;
      case 'system':
        icon = Icons.info_outline;
        color = AppColors.textSecondary;
        break;
      default:
        icon = Icons.notifications_outlined;
        color = AppColors.primary;
    }

    return GestureDetector(
      onTap: () async {
        // Đánh dấu đã đọc
        if (!notification.isRead) {
          await ref.read(notificationRepositoryProvider).markAsRead(notification.id);
          ref.invalidate(notificationsProvider(_filterTypes[_selectedFilter]));
          ref.invalidate(unreadNotificationsCountProvider);
        }

        // Navigate based on type
        if (notification.type == 'order' && notification.data?['order_id'] != null) {
          context.push('/orders/${notification.data!['order_id']}');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: notification.isRead 
              ? null 
              : Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatTime(notification.createdAt),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }

  Future<void> _markAllAsRead() async {
    await ref.read(notificationRepositoryProvider).markAllAsRead();
    ref.invalidate(notificationsProvider(_filterTypes[_selectedFilter]));
    ref.invalidate(unreadNotificationsCountProvider);
  }
}
```

### 9. Cập nhật Bottom Nav để hiển thị Badge

**File**: `choque/lib/screens/main_shell.dart` hoặc `choque/lib/ui/widgets/app_bottom_nav_bar.dart`

Thêm badge cho notifications icon:

```dart
final unreadCountAsync = ref.watch(unreadNotificationsCountProvider);

// Trong navigation item
Badge(
  label: unreadCountAsync.when(
    data: (count) => count > 0 ? Text(count.toString()) : const SizedBox.shrink(),
    loading: () => const SizedBox.shrink(),
    error: (_, __) => const SizedBox.shrink(),
  ),
  isLabelVisible: unreadCountAsync.valueOrNull != null && unreadCountAsync.value! > 0,
  child: Icon(Icons.notifications_outlined),
)
```

### 10. Tạo RPC Function để tạo Notification (Backend)

**File**: `docs/03-RPC-FUNCTIONS.sql` (thêm vào cuối)

```sql
-- ============================================
-- NOTIFICATION FUNCTIONS
-- ============================================

-- Function để tạo notification (sẽ được gọi từ backend/service)
create or replace function public.create_notification(
  p_user_id uuid,
  p_title text,
  p_body text,
  p_type text,
  p_data jsonb default null
) returns uuid as $$
declare
  v_notification_id uuid;
begin
  insert into public.notifications (
    user_id, title, body, type, data
  ) values (
    p_user_id, p_title, p_body, p_type, p_data
  ) returning id into v_notification_id;

  -- TODO: Trigger FCM push notification từ backend
  -- (Cần implement trong backend service, không phải SQL)

  return v_notification_id;
end;
$$ language plpgsql security definer;

-- Function để tạo notification cho nhiều users (broadcast)
create or replace function public.create_broadcast_notification(
  p_user_ids uuid[],
  p_title text,
  p_body text,
  p_type text,
  p_data jsonb default null
) returns int as $$
declare
  v_count int;
begin
  insert into public.notifications (
    user_id, title, body, type, data
  )
  select unnest(p_user_ids), p_title, p_body, p_type, p_data;

  get diagnostics v_count = row_count;
  return v_count;
end;
$$ language plpgsql security definer;
```

**Lưu ý**: FCM push notification thực tế cần được gửi từ backend service (Node.js, Python, etc.) sử dụng Firebase Admin SDK, không thể gửi trực tiếp từ SQL.

### 11. Android Configuration

**File**: `choque/android/app/build.gradle`

Thêm vào `dependencies`:

```gradle
dependencies {
    // ... existing dependencies
    implementation platform('com.google.firebase:firebase-bom:33.7.0')
    implementation 'com.google.firebase:firebase-messaging'
}
```

**File**: `choque/android/app/src/main/AndroidManifest.xml`

Đảm bảo có permissions:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

### 12. iOS Configuration

**File**: `choque/ios/Runner/Info.plist`

Thêm:

```xml
<key>FirebaseAppDelegateProxyEnabled</key>
<false/>
```

Và cấu hình notification permissions trong `AppDelegate.swift`.

## Thứ tự thực hiện

1. **Bước 1**: Thêm Firebase packages vào `pubspec.yaml` và chạy `flutter pub get`
2. **Bước 2**: Tạo notifications table trong database (SQL migration)
3. **Bước 3**: Tạo `NotificationModel` và `NotificationRepository`
4. **Bước 4**: Tạo `NotificationService` với FCM setup
5. **Bước 5**: Cập nhật `main.dart` để initialize Firebase và NotificationService
6. **Bước 6**: Tạo notification providers trong `app_providers.dart`
7. **Bước 7**: Cập nhật `NotificationsScreen` để dùng providers
8. **Bước 8**: Thêm badge unread count vào Bottom Nav
9. **Bước 9**: Configure Android và iOS cho FCM
10. **Bước 10**: Test với Firebase Console

## Lưu ý quan trọng

1. **Firebase Setup**: Cần tạo Firebase project và download `google-services.json` (Android) và `GoogleService-Info.plist` (iOS)

2. **FCM Token**: Token sẽ được tự động lưu vào database khi user login

3. **Backend Integration**: Để gửi push notifications, cần có backend service sử dụng Firebase Admin SDK:
   - Khi order status thay đổi → gọi backend API
   - Backend tạo notification trong database
   - Backend gửi FCM push notification đến user's FCM token

4. **Notification Types**:
   - `order`: Order updates (confirmed, picked up, completed)
   - `promo`: Promotions, vouchers
   - `system`: System notifications, new shops

5. **Data Payload**: Notification data có thể chứa `order_id`, `promotion_id` để navigate đến đúng screen

6. **Testing**: Có thể test bằng Firebase Console → Cloud Messaging → Send test message

## Files cần tạo/sửa

- `choque/pubspec.yaml` - Thêm Firebase packages
- `docs/02-SCHEMA.sql` - Thêm notifications table
- `docs/MIGRATION-ALL-CHANGES.sql` - Thêm migration cho notifications
- `docs/03-RPC-FUNCTIONS.sql` - Thêm notification RPC functions
- `choque/lib/data/models/notification_model.dart` - Tạo mới
- `choque/lib/data/repositories/notification_repository.dart` - Tạo mới
- `choque/lib/services/notification_service.dart` - Tạo mới
- `choque/lib/main.dart` - Initialize Firebase và NotificationService
- `choque/lib/providers/app_providers.dart` - Thêm notification providers
- `choque/lib/screens/notifications/notifications_screen.dart` - Kết nối với providers
- `choque/lib/ui/widgets/app_bottom_nav_bar.dart` hoặc `main_shell.dart` - Thêm badge
- `choque/android/app/build.gradle` - Thêm Firebase dependencies
- `choque/android/app/src/main/AndroidManifest.xml` - Permissions
- `choque/ios/Runner/Info.plist` - Firebase config

## Backend Service (Optional - cho gửi notifications)

Cần có backend service để:
1. Listen order status changes từ Supabase
2. Tạo notification trong database
3. Gửi FCM push notification đến user

Có thể implement bằng:
- Supabase Edge Functions
- Node.js/Python service với Firebase Admin SDK
- Supabase Database Webhooks → External API
