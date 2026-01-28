import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../data/models/notification_model.dart';

/// Notification Handler Service
/// Handles different types of notifications and navigation
class NotificationHandlerService {
  final GoRouter _router;

  NotificationHandlerService(this._router);

  /// Handle notification received (foreground)
  void handleNotificationReceived(RemoteMessage message) {
    if (kDebugMode) {
      print('[NotificationHandler] Received: ${message.notification?.title}');
      print('[NotificationHandler] Data: ${message.data}');
    }

    // You can add custom logic here, e.g., show in-app notification
    // or update badge count
  }

  /// Handle notification tapped (background/terminated)
  void handleNotificationTapped(RemoteMessage message) {
    if (kDebugMode) {
      print('[NotificationHandler] Tapped: ${message.data}');
    }

    final type = message.data['type'] as String?;
    if (type == null) return;

    try {
      final notificationType = NotificationType.fromString(type);
      _navigateBasedOnType(notificationType, message.data);
    } catch (e) {
      if (kDebugMode) {
        print('[NotificationHandler] Unknown notification type: $type');
      }
    }
  }

  /// Navigate based on notification type
  void _navigateBasedOnType(
    NotificationType type,
    Map<String, dynamic> data,
  ) {
    switch (type) {
      case NotificationType.orderAssigned:
      case NotificationType.orderCanceled:
      case NotificationType.orderCompleted:
      case NotificationType.paymentReceived:
        _navigateToOrder(data);
        break;

      case NotificationType.approvalApproved:
      case NotificationType.approvalRejected:
        _navigateToProfile();
        break;

      case NotificationType.announcement:
      case NotificationType.systemAlert:
        _navigateToNotifications();
        break;
    }
  }

  /// Navigate to order details
  void _navigateToOrder(Map<String, dynamic> data) {
    final orderId = data['order_id'] as String?;
    if (orderId != null) {
      _router.go('/driver/orders/$orderId');
    } else {
      _router.go('/driver/orders');
    }
  }

  /// Navigate to profile
  void _navigateToProfile() {
    _router.go('/driver/profile');
  }

  /// Navigate to notifications screen
  void _navigateToNotifications() {
    _router.go('/driver/notifications');
  }
}
