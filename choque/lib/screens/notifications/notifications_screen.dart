import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../ui/design_system.dart';
import '../../providers/app_providers.dart';
import '../../data/models/notification_model.dart';

/// Notifications Screen
/// Màn hình thông báo: danh sách notifications, order updates, promotions.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  int _selectedFilter = 0;

  @override
  Widget build(BuildContext context) {
    // Map filter index to notification type
    final filterType = _getFilterType(_selectedFilter);
    // Dùng stream provider để tự động cập nhật real-time
    final notificationsAsync = ref.watch(notificationsStreamFilteredProvider(filterType));

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
                    // Refresh stream provider
                    onRefresh: () async {
                      ref.invalidate(notificationsStreamFilteredProvider(filterType));
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: index < notifications.length - 1 ? 12 : 100),
                          child: _buildNotificationItem(notifications[index]),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => _buildErrorState(error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _getFilterType(int index) {
    switch (index) {
      case 0:
        return null; // Tất cả
      case 1:
        return 'order'; // Đơn hàng
      case 2:
        return 'promo'; // Khuyến mãi
      case 3:
        return 'system'; // Hệ thống
      default:
        return null;
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          // Nút quay về
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 4),
          // Title
          Expanded(
            child: Text(
              'Thông báo',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          // Action: Đánh dấu đã đọc
          Consumer(
            builder: (context, ref, child) {
              // Dùng stream provider để tự động cập nhật
              final unreadCountAsync = ref.watch(unreadNotificationsCountStreamProvider);
              final unreadCount = unreadCountAsync.asData?.value ?? 
                                 ref.watch(unreadNotificationsCountProvider).asData?.value ?? 0;
              final hasUnread = unreadCount > 0;
              
              if (!hasUnread) return const SizedBox.shrink();
              
              return TextButton(
                onPressed: () => _handleMarkAllAsRead(ref),
                child: Text(
                  'Đánh dấu đã đọc',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = ['Tất cả', 'Đơn hàng', 'Khuyến mãi', 'Hệ thống'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.asMap().entries.map((entry) {
            final index = entry.key;
            final label = entry.value;
            final isActive = index == _selectedFilter;
            return Padding(
              padding: EdgeInsets.only(right: index < filters.length - 1 ? 8 : 0),
              child: GestureDetector(
                onTap: () => setState(() => _selectedFilter = index),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive ? AppColors.primary : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    final iconData = _getIconForType(notification.type);
    final color = _getColorForType(notification.type);
    final timeAgo = _formatTimeAgo(notification.createdAt);

    return GestureDetector(
      onTap: () => _handleNotificationTap(notification),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.large),
          boxShadow: AppShadows.soft(0.04),
          border: !notification.isRead
              ? Border.all(
                  color: AppColors.primary.withAlpha(51),
                  width: 1,
                )
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: Icon(
                iconData,
                size: 24,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
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
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
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
                  const SizedBox(height: 6),
                  Text(
                    notification.body,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    timeAgo,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'order':
        return Icons.local_shipping_outlined;
      case 'promo':
        return Icons.local_offer_outlined;
      case 'system':
        return Icons.info_outline;
      default:
        return Icons.notifications_none;
    }
  }

  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'order':
        return AppColors.primary;
      case 'promo':
        return const Color(0xFFF59E0B);
      case 'system':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  Future<void> _handleNotificationTap(NotificationModel notification) async {
    // Đánh dấu đã đọc nếu chưa đọc
    if (!notification.isRead) {
      try {
        final repo = ref.read(notificationRepositoryProvider);
        await repo.markAsRead(notification.id);
        
        // Invalidate providers để refresh
        ref.invalidate(notificationsStreamFilteredProvider(_getFilterType(_selectedFilter)));
        ref.invalidate(unreadNotificationsCountProvider);
        ref.invalidate(unreadNotificationsCountStreamProvider);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e')),
          );
        }
      }
    }

    // Navigate dựa trên type và data
    if (notification.type == 'order' && notification.data != null) {
      final orderId = notification.data!['order_id'] as String?;
      if (orderId != null) {
        context.push('/orders/$orderId');
      }
    }
  }

  Future<void> _handleMarkAllAsRead(WidgetRef ref) async {
    try {
      final repo = ref.read(notificationRepositoryProvider);
      await repo.markAllAsRead();
      
      // Invalidate providers để refresh
      ref.invalidate(notificationsStreamFilteredProvider(_getFilterType(_selectedFilter)));
      ref.invalidate(unreadNotificationsCountProvider);
      ref.invalidate(unreadNotificationsCountStreamProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã đánh dấu tất cả là đã đọc')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có thông báo',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bạn sẽ nhận được thông báo khi có cập nhật về đơn hàng hoặc khuyến mãi',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.danger),
            const SizedBox(height: 16),
            Text(
              'Không thể tải thông báo',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final filterType = _getFilterType(_selectedFilter);
                ref.invalidate(notificationsStreamFilteredProvider(filterType));
              },
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
