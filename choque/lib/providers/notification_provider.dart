import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/notification_model.dart';
import '../data/repositories/notification_repository.dart';

/// Notification Repository Provider
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(Supabase.instance.client);
});

/// Notifications List Provider
final notificationsProvider = FutureProvider.autoDispose<List<NotificationModel>>((ref) async {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getNotifications();
});

/// Unread Notifications Provider
final unreadNotificationsProvider = FutureProvider.autoDispose<List<NotificationModel>>((ref) async {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getNotifications(unreadOnly: true);
});

/// Unread Notifications Count Provider
final unreadNotificationsCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getUnreadCount();
});

/// Notifications Stream Provider (Real-time)
final notificationsStreamProvider = StreamProvider.autoDispose<List<NotificationModel>>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.watchNotifications();
});

/// Unread Count Stream Provider (Real-time)
final unreadCountStreamProvider = StreamProvider.autoDispose<int>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.watchUnreadCount();
});

/// Mark Notification as Read Action
final markNotificationReadProvider = Provider((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return ({required String notificationId, bool read = true}) async {
    await repository.markAsRead(notificationId, read: read);
    // Invalidate providers to refresh
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadNotificationsProvider);
    ref.invalidate(unreadNotificationsCountProvider);
  };
});

/// Mark All as Read Action
final markAllNotificationsReadProvider = Provider((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return () async {
    await repository.markAllAsRead();
    // Invalidate providers to refresh
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadNotificationsProvider);
    ref.invalidate(unreadNotificationsCountProvider);
  };
});

/// Delete Notification Action
final deleteNotificationProvider = Provider((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return (String notificationId) async {
    await repository.deleteNotification(notificationId);
    // Invalidate providers to refresh
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadNotificationsProvider);
    ref.invalidate(unreadNotificationsCountProvider);
  };
});
