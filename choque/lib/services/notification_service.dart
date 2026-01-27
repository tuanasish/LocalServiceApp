import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../routing/app_router.dart';
import '../providers/app_providers.dart';

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

  /// Handle khi user tap vào notification (local notification)
  /// Lưu ý: Method này được gọi từ isolate riêng, không có access đến ref
  /// Navigation sẽ được handle bởi FCM handlers (_handleNotificationTap)
  /// Local notification chỉ hiển thị, FCM sẽ handle tap
  static void _onNotificationTapped(NotificationResponse response) {
    // Local notification tap sẽ trigger FCM handler
    // Nếu cần navigate từ local notification, có thể dùng navigator key
    // Tạm thời không cần xử lý ở đây vì FCM handlers đã xử lý
  }

  /// Handle notification tap (từ FCM)
  static void _handleNotificationTap(RemoteMessage message, WidgetRef ref) {
    final data = message.data;
    if (data.isEmpty) return;
    
    final type = data['type'] as String?;
    if (type == null) return;

    // Lấy router từ ref (cần access GoRouter)
    // Vì đây là static method, cần pass router hoặc dùng global navigator key
    final router = ref.read(appRouterProvider);
    
    // Navigate based on type
    switch (type) {
      case 'order':
        final orderId = data['order_id'] as String?;
        if (orderId != null) {
          router.push('/orders/$orderId');
        }
        break;
      case 'promo':
        // Navigate to promotions screen nếu có
        router.push('/notifications');
        break;
      case 'system':
      default:
        // Navigate to notifications screen
        router.push('/notifications');
        break;
    }
    
    // Invalidate providers để refresh
    ref.invalidate(notificationsProvider(null));
    ref.invalidate(unreadNotificationsCountProvider);
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

// Background message handler được định nghĩa trong main.dart
// Không cần định nghĩa lại ở đây
