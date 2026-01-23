import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../ui/design_system.dart';
import '../../ui/widgets/stat_card.dart';
import '../../ui/widgets/driver_order_card.dart';

/// Driver Home Dashboard Screen
/// Màn chính cho tài xế: thống kê, đơn hàng đang chờ, trạng thái online/offline.
class DriverHomeDashboardScreen extends StatelessWidget {
  const DriverHomeDashboardScreen({super.key});

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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      _buildStatsCards(),
                      const SizedBox(height: 20),
                      _buildStatusToggle(),
                      const SizedBox(height: 20),
                      _buildSectionTitle('Đơn hàng gần đây'),
                      const SizedBox(height: 12),
                      _buildOrderList(),
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
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
                  'Xin chào, Nguyễn Văn A',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Đang hoạt động',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: AppColors.textPrimary,
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            icon: Icons.local_shipping_outlined,
            label: 'Đơn hôm nay',
            value: '12',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            icon: Icons.attach_money_outlined,
            label: 'Thu nhập',
            value: '450k',
            color: const Color(0xFF16A34A),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            icon: Icons.star_outline,
            label: 'Đánh giá',
            value: '4.8',
            color: const Color(0xFFF59E0B),
          ),
        ),
      ],
    );
  }



  Widget _buildStatusToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        boxShadow: AppShadows.soft(0.04),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trạng thái nhận đơn',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Bật để nhận đơn hàng mới',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Switch(
            value: true,
            onChanged: (_) {},
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.heading18,
    );
  }

  Widget _buildOrderList() {
    return Column(
      children: [
        DriverOrderCard(
          orderId: '#ORD-2024-001234',
          storeName: 'Quán Phở Bò Gia Truyền',
          address: '123 Đường Lê Lợi, Q1',
          distance: '2.5km',
          fee: '25.000đ',
          status: 'Chờ nhận',
        ),
        const SizedBox(height: 12),
        DriverOrderCard(
          orderId: '#ORD-2024-001235',
          storeName: 'Cửa hàng Rau Sạch',
          address: '456 Nguyễn Huệ, Q1',
          distance: '3.2km',
          fee: '30.000đ',
          status: 'Đang giao',
          isActive: true,
          onViewDetails: () {},
        ),
      ],
    );
  }


}
