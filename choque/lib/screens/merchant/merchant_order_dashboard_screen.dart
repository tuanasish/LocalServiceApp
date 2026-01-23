import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../ui/design_system.dart';
import '../../ui/widgets/stat_card.dart';
import '../../ui/widgets/merchant_order_card.dart';

/// Merchant Order Dashboard Screen
/// Dashboard cho chủ cửa hàng: thống kê đơn hàng, danh sách đơn mới/chờ xử lý.
class MerchantOrderDashboardScreen extends StatelessWidget {
  const MerchantOrderDashboardScreen({super.key});

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
                      _buildTabs(),
                      const SizedBox(height: 16),
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.storefront,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quán Phở Bò Gia Truyền',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Đang mở cửa',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.success,
                  ),
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
            icon: Icons.receipt_long_outlined,
            label: 'Đơn mới',
            value: '5',
            color: AppColors.primary,
            showBadge: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            icon: Icons.access_time_outlined,
            label: 'Đang xử lý',
            value: '3',
            color: const Color(0xFFF59E0B),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            icon: Icons.check_circle_outline,
            label: 'Hoàn thành',
            value: '24',
            color: AppColors.success,
          ),
        ),
      ],
    );
  }



  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        boxShadow: AppShadows.soft(0.03),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton('Tất cả', isActive: true),
          ),
          Expanded(
            child: _buildTabButton('Mới', isActive: false, badge: '5'),
          ),
          Expanded(
            child: _buildTabButton('Đang xử lý', isActive: false),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, {required bool isActive, String? badge}) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : AppColors.textSecondary,
              ),
            ),
            if (badge != null && !isActive) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList() {
    return Column(
      children: [
        MerchantOrderCard(
          orderId: '#ORD-2024-001239',
          customerName: 'Nguyễn Văn A',
          items: 'Phở Bò Tái Lăn x1, Trà Đá x1',
          total: '80.000đ',
          time: '14:30',
          status: 'Mới',
          isUrgent: false,
          onAccept: () {},
          onReject: () {},
        ),
        const SizedBox(height: 12),
        MerchantOrderCard(
          orderId: '#ORD-2024-001240',
          customerName: 'Trần Thị B',
          items: 'Bún Bò Huế x2',
          total: '120.000đ',
          time: '14:25',
          status: 'Mới',
          isUrgent: true,
          onAccept: () {},
          onReject: () {},
        ),
        const SizedBox(height: 12),
        MerchantOrderCard(
          orderId: '#ORD-2024-001241',
          customerName: 'Lê Văn C',
          items: 'Phở Gà x1, Nước ngọt x2',
          total: '95.000đ',
          time: '14:20',
          status: 'Đang chuẩn bị',
          isUrgent: false,
        ),
      ],
    );
  }


}
