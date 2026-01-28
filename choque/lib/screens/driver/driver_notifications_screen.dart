import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../data/models/notification_model.dart';
import '../../providers/notification_provider.dart';
import '../../ui/design_system.dart';

/// Driver Notifications Screen
/// Displays list of notifications for drivers
class DriverNotificationsScreen extends ConsumerStatefulWidget {
  const DriverNotificationsScreen({super.key});

  @override
  ConsumerState<DriverNotificationsScreen> createState() =>
      _DriverNotificationsScreenState();
}

class _DriverNotificationsScreenState
    extends ConsumerState<DriverNotificationsScreen> {
  bool _showUnreadOnly = false;

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsStreamProvider).whenData((list) {
      if (_showUnreadOnly) {
        return list.where((n) => !n.read).toList();
      }
      return list;
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Thông báo',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Filter toggle
          IconButton(
            icon: Icon(
              _showUnreadOnly
                  ? Icons.filter_alt
                  : Icons.filter_alt_outlined,
              color: _showUnreadOnly ? AppColors.primary : AppColors.textSecondary,
            ),
            onPressed: () {
              setState(() {
                _showUnreadOnly = !_showUnreadOnly;
              });
            },
            tooltip: _showUnreadOnly ? 'Hiện tất cả' : 'Chỉ chưa đọc',
          ),
          // Mark all as read
          IconButton(
            icon: const Icon(Icons.done_all, color: AppColors.textSecondary),
            onPressed: () async {
              final markAll = ref.read(markAllNotificationsReadProvider);
              await markAll();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã đánh dấu tất cả là đã đọc')),
                );
              }
            },
            tooltip: 'Đánh dấu tất cả đã đọc',
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificationsProvider);
              ref.invalidate(unreadNotificationsProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _NotificationItem(
                  notification: notification,
                  onTap: () => _handleNotificationTap(notification),
                  onDelete: () => _handleDelete(notification.id),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Không thể tải thông báo',
                style: GoogleFonts.inter(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  ref.invalidate(notificationsProvider);
                },
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _showUnreadOnly ? Icons.mark_email_read : Icons.notifications_none,
            size: 64,
            color: AppColors.textSecondary.withAlpha(128),
          ),
          const SizedBox(height: 16),
          Text(
            _showUnreadOnly
                ? 'Không có thông báo chưa đọc'
                : 'Chưa có thông báo nào',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleNotificationTap(NotificationModel notification) async {
    // Mark as read
    if (!notification.read) {
      final markAsRead = ref.read(markNotificationReadProvider);
      await markAsRead(notificationId: notification.id);
    }

    // Navigate based on type (you can implement navigation logic here)
    // For now, just show details in a dialog
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(notification.title),
          content: Text(notification.body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _handleDelete(String notificationId) async {
    final delete = ref.read(deleteNotificationProvider);
    await delete(notificationId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa thông báo')),
      );
    }
  }
}

/// Notification Item Widget
class _NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationItem({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.read
                ? Colors.white
                : AppColors.primary.withAlpha(13),
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(
              color: notification.read
                  ? AppColors.border
                  : AppColors.primary.withAlpha(51),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getTypeColor().withAlpha(26),
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: Icon(
                  _getTypeIcon(),
                  color: _getTypeColor(),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: notification.read
                                  ? FontWeight.w500
                                  : FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (!notification.read)
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
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTime(notification.createdAt),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon() {
    switch (notification.type) {
      case NotificationType.orderAssigned:
        return Icons.assignment;
      case NotificationType.orderCanceled:
        return Icons.cancel;
      case NotificationType.orderCompleted:
        return Icons.check_circle;
      case NotificationType.approvalApproved:
        return Icons.verified;
      case NotificationType.approvalRejected:
        return Icons.block;
      case NotificationType.paymentReceived:
        return Icons.payments;
      case NotificationType.announcement:
        return Icons.campaign;
      case NotificationType.systemAlert:
        return Icons.warning;
    }
  }

  Color _getTypeColor() {
    switch (notification.type) {
      case NotificationType.orderAssigned:
        return AppColors.primary;
      case NotificationType.orderCanceled:
        return AppColors.error;
      case NotificationType.orderCompleted:
        return AppColors.success;
      case NotificationType.approvalApproved:
        return AppColors.success;
      case NotificationType.approvalRejected:
        return AppColors.error;
      case NotificationType.paymentReceived:
        return AppColors.success;
      case NotificationType.announcement:
        return AppColors.warning;
      case NotificationType.systemAlert:
        return AppColors.error;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(time);
    }
  }
}
