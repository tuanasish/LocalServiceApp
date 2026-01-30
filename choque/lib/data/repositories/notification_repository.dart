import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

/// Notification Repository
/// Handles all notification-related database operations
class NotificationRepository {
  final SupabaseClient _supabase;

  NotificationRepository(this._supabase);

  /// Save FCM token to database
  Future<void> saveFCMToken({
    required String token,
    String? deviceType,
    String? deviceId,
  }) async {
    try {
      await _supabase.rpc('save_fcm_token', params: {
        'p_token': token,
        'p_device_type': deviceType,
        'p_device_id': deviceId,
      });

      if (kDebugMode) {
        print('[NotificationRepository] FCM token saved: ${token.substring(0, 20)}...');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[NotificationRepository] Error saving FCM token: $e');
      }
      rethrow;
    }
  }

  /// Get user notifications with pagination
  Future<List<NotificationModel>> getNotifications({
    int limit = 50,
    int offset = 0,
    bool unreadOnly = false,
  }) async {
    try {
      final response = await _supabase.rpc('get_user_notifications', params: {
        'p_limit': limit,
        'p_offset': offset,
        'p_unread_only': unreadOnly,
      }) as List<dynamic>;

      final notifications = response
          .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
          .toList();

      if (kDebugMode) {
        print('[NotificationRepository] Fetched ${notifications.length} notifications');
      }

      return notifications;
    } catch (e) {
      if (kDebugMode) {
        print('[NotificationRepository] Error fetching notifications: $e');
      }
      rethrow;
    }
  }

  /// Mark notification as read
  Future<NotificationModel> markAsRead(String notificationId, {bool read = true}) async {
    try {
      final response = await _supabase.rpc('mark_notification_read', params: {
        'p_notification_id': notificationId,
        'p_read': read,
      }) as Map<String, dynamic>;

      final notification = NotificationModel.fromJson(response);

      if (kDebugMode) {
        print('[NotificationRepository] Marked notification as ${read ? "read" : "unread"}: $notificationId');
      }

      return notification;
    } catch (e) {
      if (kDebugMode) {
        print('[NotificationRepository] Error marking notification: $e');
      }
      rethrow;
    }
  }

  /// Mark all notifications as read
  Future<int> markAllAsRead() async {
    try {
      final count = await _supabase.rpc('mark_all_notifications_read') as int;

      if (kDebugMode) {
        print('[NotificationRepository] Marked $count notifications as read');
      }

      return count;
    } catch (e) {
      if (kDebugMode) {
        print('[NotificationRepository] Error marking all as read: $e');
      }
      rethrow;
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _supabase.rpc('delete_notification', params: {
        'p_notification_id': notificationId,
      });

      if (kDebugMode) {
        print('[NotificationRepository] Deleted notification: $notificationId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[NotificationRepository] Error deleting notification: $e');
      }
      rethrow;
    }
  }

  /// Get unread notifications count
  Future<int> getUnreadCount() async {
    try {
      final count = await _supabase.rpc('get_unread_notifications_count') as int;

      if (kDebugMode) {
        print('[NotificationRepository] Unread count: $count');
      }

      return count;
    } catch (e) {
      if (kDebugMode) {
        print('[NotificationRepository] Error getting unread count: $e');
      }
      return 0;
    }
  }

  /// Stream of notifications (real-time updates)
  Stream<List<NotificationModel>> watchNotifications() {
    final userId = _supabase.auth.currentUser?.id ?? '';
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50)
        .map((data) => data
            .map((json) => NotificationModel.fromJson(json))
            .toList());
  }

  /// Stream of unread count (real-time updates)
  Stream<int> watchUnreadCount() {
    final userId = _supabase.auth.currentUser?.id ?? '';
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) => data.where((json) => json['read'] == false).length);
  }
}
