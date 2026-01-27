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
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    var query = _client
        .from('notifications')
        .select()
        .eq('user_id', userId);

    if (type != null && type != 'Tất cả' && type.isNotEmpty) {
      query = query.eq('type', type.toLowerCase());
    }

    final response = await query
        .order('created_at', ascending: false)
        .limit(limit)
        .timeout(AppConstants.apiTimeout);

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
        .select('id')
        .eq('user_id', userId)
        .eq('is_read', false)
        .timeout(AppConstants.apiTimeout);

    return (response as List).length;
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
