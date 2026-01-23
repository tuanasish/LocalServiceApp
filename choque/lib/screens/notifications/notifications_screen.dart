import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../ui/design_system.dart';

/// Notifications Screen
/// Màn hình thông báo: danh sách notifications, order updates, promotions.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildNotificationList(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
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
          TextButton(
            onPressed: () {},
            child: Text(
              'Đánh dấu đã đọc',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList() {
    return Column(
      children: [
        _buildNotificationItem(
          icon: Icons.local_shipping_outlined,
          title: 'Đơn hàng đang được giao',
          message: 'Đơn #1234 đang được giao đến bạn',
          time: '5 phút trước',
          isUnread: true,
          color: AppColors.primary,
        ),
        const SizedBox(height: 12),
        _buildNotificationItem(
          icon: Icons.check_circle_outline,
          title: 'Đơn hàng đã hoàn thành',
          message: 'Đơn #1233 đã được giao thành công',
          time: '1 giờ trước',
          isUnread: true,
          color: AppColors.success,
        ),
        const SizedBox(height: 12),
        _buildNotificationItem(
          icon: Icons.local_offer_outlined,
          title: 'Khuyến mãi mới',
          message: 'Giảm 20% cho đơn hàng đầu tiên',
          time: '2 giờ trước',
          isUnread: false,
          color: const Color(0xFFF59E0B),
        ),
        const SizedBox(height: 12),
        _buildNotificationItem(
          icon: Icons.store_outlined,
          title: 'Cửa hàng mới',
          message: 'Quán Phở Bò Gia Truyền vừa tham gia',
          time: '1 ngày trước',
          isUnread: false,
          color: AppColors.primary,
        ),
        const SizedBox(height: 12),
        _buildNotificationItem(
          icon: Icons.receipt_long_outlined,
          title: 'Đơn hàng đã được xác nhận',
          message: 'Đơn #1232 đã được cửa hàng xác nhận',
          time: '2 ngày trước',
          isUnread: false,
          color: AppColors.success,
        ),
      ],
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required String title,
    required String message,
    required String time,
    required bool isUnread,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        boxShadow: AppShadows.soft(0.04),
        border: isUnread
            ? Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
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
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: Icon(
              icon,
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
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (isUnread)
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
                  message,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  time,
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
    );
  }
}
