import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_providers.dart';

/// Shared Bottom Navigation Bar dùng chung cho tất cả màn hình chính
/// KHÔNG dùng ConsumerWidget để tránh rebuild khi badge thay đổi
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final void Function(int)? onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  /// Indices: 0 = Trang chủ, 1 = Đơn hàng, 2 = Thông báo, 3 = Tài khoản
  static const int indexHome = 0;
  static const int indexOrders = 1;
  static const int indexNotifications = 2;
  static const int indexProfile = 3;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context: context,
                icon: Icons.home,
                label: 'Trang chủ',
                isActive: currentIndex == indexHome,
                onTap: () => _handleTap(context, indexHome),
              ),
              _buildNavItem(
                context: context,
                icon: Icons.receipt_long,
                label: 'Đơn hàng',
                isActive: currentIndex == indexOrders,
                onTap: () => _handleTap(context, indexOrders),
              ),
              // Notifications item với badge riêng - chỉ badge rebuild khi count thay đổi
              _NotificationNavItem(
                isActive: currentIndex == indexNotifications,
                onTap: () => _handleTap(context, indexNotifications),
              ),
              _buildNavItem(
                context: context,
                icon: Icons.person_outline,
                label: 'Tài khoản',
                isActive: currentIndex == indexProfile,
                onTap: () => _handleTap(context, indexProfile),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, int index) {
    if (onTap != null) {
      // Sử dụng callback từ MainShell (goBranch)
      onTap!(index);
    } else {
      // Fallback: navigate trực tiếp (cho màn không dùng shell)
      _navigateTo(context, index);
    }
  }

  void _navigateTo(BuildContext context, int index) {
    if (currentIndex == index) return;
    
    switch (index) {
      case indexHome:
        context.go('/');
        break;
      case indexOrders:
        context.go('/orders');
        break;
      case indexNotifications:
        context.go('/notifications');
        break;
      case indexProfile:
        context.go('/profile');
        break;
    }
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    // Màu sắc cho icon: active = primary, inactive = xám
    final color = isActive 
        ? const Color(0xFF1E7F43)
        : const Color(0xFF94A3B8);
    return GestureDetector(
      onTap: onTap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: isActive
                          ? BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF1E7F43).withValues(alpha: 0.15),
                                  const Color(0xFF1E7F43).withValues(alpha: 0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            )
                          : null,
                      child: Icon(icon, color: color, size: 24),
                    ),
                    if (badgeCount > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: _BadgeWidget(count: badgeCount),
                      ),
                  ],
                ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge widget riêng để hiển thị số lượng notification
class _BadgeWidget extends StatelessWidget {
  final int count;
  const _BadgeWidget({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: const BoxDecoration(
        color: Color(0xFFEF4444),
        shape: BoxShape.circle,
      ),
      constraints: const BoxConstraints(
        minWidth: 16,
        minHeight: 16,
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Notification Nav Item riêng với Consumer để chỉ rebuild badge khi cần
class _NotificationNavItem extends ConsumerWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _NotificationNavItem({
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Chỉ widget này rebuild khi notification count thay đổi
    // Ưu tiên stream provider (real-time), fallback sang future provider
    final badgeCount = ref.watch(unreadNotificationsCountStreamProvider).asData?.value ?? 
                       ref.watch(unreadNotificationsCountProvider).asData?.value ?? 0;

    final color = isActive 
        ? const Color(0xFF1E7F43)
        : const Color(0xFF94A3B8);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: isActive
                    ? BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF1E7F43).withValues(alpha: 0.15),
                            const Color(0xFF1E7F43).withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      )
                    : null,
                child: Icon(Icons.notifications_none, color: color, size: 24),
              ),
              if (badgeCount > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: _BadgeWidget(count: badgeCount),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Thông báo',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
