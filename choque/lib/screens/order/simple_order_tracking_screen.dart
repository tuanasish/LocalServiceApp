import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../ui/design_system.dart';
import '../../ui/widgets/order_timeline_item.dart';

/// Simple Order Tracking Screen
/// Design: "Simple Order Tracking" (Stitch, project Chợ Quê)
class SimpleOrderTrackingScreen extends StatelessWidget {
  const SimpleOrderTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            const AppSimpleHeader(title: 'Theo dõi đơn hàng'),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildOrderInfoCard(),
                      const SizedBox(height: 24),
                      _buildTimeline(),
                      const SizedBox(height: 24),
                      _buildStoreInfo(),
                      const SizedBox(height: 16),
                      _buildDeliveryInfo(),
                      const SizedBox(height: 24),
                      _buildActionButtons(),
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

  Widget _buildOrderInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        boxShadow: AppShadows.soft(0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mã đơn hàng',
                    style: AppTextStyles.body13Secondary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '#ORD-2024-001234',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  'Đang chuẩn bị',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.access_time_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Đặt lúc: 14:30 • 23/01/2024',
                style: AppTextStyles.body13Secondary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '123 Đường Lê Lợi, Phường Bến Thành, Quận 1, TP. Hồ Chí Minh',
                  style: AppTextStyles.body13Secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildTimeline() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        boxShadow: AppShadows.soft(0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Trạng thái đơn hàng', style: AppTextStyles.heading18),
          const SizedBox(height: 20),
          OrderTimelineItem(
            icon: Icons.check_circle,
            iconColor: AppColors.primary,
            title: 'Đơn hàng đã được xác nhận',
            subtitle: '14:30 • 23/01/2024',
            isCompleted: true,
          ),
          OrderTimelineItem(
            icon: Icons.restaurant,
            iconColor: AppColors.primary,
            title: 'Đang chuẩn bị món ăn',
            subtitle: 'Dự kiến hoàn thành: 15:00',
            isCompleted: true,
          ),
          OrderTimelineItem(
            icon: Icons.delivery_dining,
            iconColor: AppColors.textMuted,
            title: 'Đang giao hàng',
            subtitle: 'Chờ shipper nhận đơn',
            isCompleted: false,
          ),
          OrderTimelineItem(
            icon: Icons.check_circle_outline,
            iconColor: AppColors.textMuted,
            title: 'Đã giao hàng',
            subtitle: '',
            isCompleted: false,
            isLast: true,
          ),
        ],
      ),
    );
  }



  Widget _buildStoreInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        boxShadow: AppShadows.soft(0.04),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: const Icon(
              Icons.store,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cửa hàng',
                  style: AppTextStyles.body13Secondary,
                ),
                const SizedBox(height: 4),
                Text(
                  'Quán Phở Bò Gia Truyền',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.phone_outlined,
              color: AppColors.primary,
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        boxShadow: AppShadows.soft(0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shipper',
                      style: AppTextStyles.body13Secondary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Chưa có shipper nhận đơn',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            onPressed: () {},
            icon: const Icon(
              Icons.support_agent_outlined,
              color: AppColors.primary,
            ),
            label: Text(
              'Liên hệ hỗ trợ',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
