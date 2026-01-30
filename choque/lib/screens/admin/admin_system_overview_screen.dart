import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../ui/design_system.dart';
import '../../ui/widgets/stat_card.dart';
import '../../ui/widgets/activity_timeline_item.dart';
import '../../ui/widgets/health_status_item.dart';
import '../../providers/admin_order_provider.dart';
import '../../providers/admin_merchant_provider.dart';
import '../../providers/admin_product_provider.dart';
import '../../providers/admin_promotion_provider.dart';
import 'admin_driver_list_screen.dart';
import 'admin_driver_monitoring_screen.dart';

/// Admin System Overview Screen
/// Tổng quan hệ thống cho admin: thống kê tổng thể, biểu đồ, hoạt động gần đây.
class AdminSystemOverviewScreen extends ConsumerWidget {
  const AdminSystemOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                      const SizedBox(height: 20),
                      _buildMainStats(),
                      const SizedBox(height: 20),
                      _buildOrderManagement(context, ref),
                      const SizedBox(height: 20),
                      _buildDriverManagement(context),
                      const SizedBox(height: 20),
                      _buildMerchantManagement(context, ref),
                      const SizedBox(height: 20),
                      _buildMenuManagement(context, ref),
                      const SizedBox(height: 20),
                      _buildSettingsManagement(context),
                      const SizedBox(height: 20),
                      _buildPromotionManagement(context, ref),
                      const SizedBox(height: 20),
                      _buildQuickStats(),
                      const SizedBox(height: 20),
                      _buildRecentActivity(),
                      const SizedBox(height: 20),
                      _buildSystemHealth(),
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
              Icons.dashboard_outlined,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tổng quan hệ thống',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
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

  Widget _buildMainStats() {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            label: 'Tổng đơn hàng',
            value: '1,234',
            icon: Icons.receipt_long_outlined,
            color: AppColors.primary,
            change: '+12.5%',
            isPositive: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            label: 'Doanh thu',
            value: '125M',
            icon: Icons.attach_money_outlined,
            color: AppColors.success,
            change: '+8.3%',
            isPositive: true,
          ),
        ),
      ],
    );
  }

  Widget _buildDriverManagement(BuildContext context) {
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
          Text('Quản lý Tài xế', style: AppTextStyles.heading18),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDriverManagementCard(
                  context: context,
                  icon: Icons.list_alt,
                  label: 'Danh sách',
                  color: AppColors.primary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminDriverListScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDriverManagementCard(
                  context: context,
                  icon: Icons.map_outlined,
                  label: 'Giám sát',
                  color: AppColors.success,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const AdminDriverMonitoringScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDriverManagementCard(
                  context: context,
                  icon: Icons.pending_actions,
                  label: 'Chờ duyệt',
                  color: const Color(0xFFF59E0B),
                  badge: '3', // TODO: Get from provider
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminDriverListScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderManagement(BuildContext context, WidgetRef ref) {
    final pendingCount = ref.watch(pendingOrdersCountProvider);
    final confirmedCount = ref.watch(confirmedOrdersCountProvider);
    final activeCount = ref.watch(activeOrdersCountProvider);

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
              Text('Quản lý Đơn hàng', style: AppTextStyles.heading18),
              TextButton(
                onPressed: () => context.push('/admin/orders'),
                child: Text(
                  'Xem tất cả',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDriverManagementCard(
                  context: context,
                  icon: Icons.pending_outlined,
                  label: 'Chờ xác nhận',
                  color: AppColors.warning,
                  badge: pendingCount.when(
                    data: (c) => c > 0 ? '$c' : null,
                    loading: () => null,
                    error: (e, s) => null,
                  ),
                  onTap: () => context.push('/admin/orders'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDriverManagementCard(
                  context: context,
                  icon: Icons.local_shipping_outlined,
                  label: 'Chờ gán',
                  color: AppColors.primary,
                  badge: confirmedCount.when(
                    data: (c) => c > 0 ? '$c' : null,
                    loading: () => null,
                    error: (e, s) => null,
                  ),
                  onTap: () => context.push('/admin/orders'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDriverManagementCard(
                  context: context,
                  icon: Icons.two_wheeler_outlined,
                  label: 'Đang giao',
                  color: AppColors.success,
                  badge: activeCount.when(
                    data: (c) => c > 0 ? '$c' : null,
                    loading: () => null,
                    error: (e, s) => null,
                  ),
                  onTap: () => context.push('/admin/orders'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDriverManagementCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    String? badge,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 32, color: color),
                if (badge != null)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        badge,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMerchantManagement(BuildContext context, WidgetRef ref) {
    final pendingCount = ref.watch(pendingMerchantsCountProvider);

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
              Text('Quản lý Cửa hàng', style: AppTextStyles.heading18),
              TextButton(
                onPressed: () => context.push('/admin/merchants'),
                child: Text(
                  'Xem tất cả',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDriverManagementCard(
                  context: context,
                  icon: Icons.pending_actions_outlined,
                  label: 'Chờ duyệt',
                  color: const Color(0xFFF59E0B),
                  badge: pendingCount.when(
                    data: (c) => c > 0 ? '$c' : null,
                    loading: () => null,
                    error: (e, s) => null,
                  ),
                  onTap: () => context.push('/admin/merchants'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDriverManagementCard(
                  context: context,
                  icon: Icons.store_outlined,
                  label: 'Đang hoạt động',
                  color: AppColors.success,
                  onTap: () => context.push('/admin/merchants'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDriverManagementCard(
                  context: context,
                  icon: Icons.list_alt_outlined,
                  label: 'Tất cả',
                  color: AppColors.primary,
                  onTap: () => context.push('/admin/merchants'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuManagement(BuildContext context, WidgetRef ref) {
    final totalProductsAsync = ref.watch(totalProductsCountProvider);
    final activeProductsAsync = ref.watch(activeProductsCountProvider);

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
              Text('Quản lý Sản phẩm', style: AppTextStyles.heading18),
              TextButton(
                onPressed: () => context.push('/admin/menu'),
                child: Text(
                  'Xem tất cả',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDriverManagementCard(
                  context: context,
                  icon: Icons.inventory_2_outlined,
                  label: 'Tổng sản phẩm',
                  color: AppColors.primary,
                  badge: totalProductsAsync.when(
                    data: (c) => c > 0 ? '$c' : null,
                    loading: () => null,
                    error: (e, s) => null,
                  ),
                  onTap: () => context.push('/admin/menu'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDriverManagementCard(
                  context: context,
                  icon: Icons.check_circle_outline,
                  label: 'Đang bán',
                  color: AppColors.success,
                  badge: activeProductsAsync.when(
                    data: (c) => c > 0 ? '$c' : null,
                    loading: () => null,
                    error: (e, s) => null,
                  ),
                  onTap: () => context.push('/admin/menu'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDriverManagementCard(
                  context: context,
                  icon: Icons.add_circle_outline,
                  label: 'Thêm mới',
                  color: const Color(0xFF8B5CF6),
                  onTap: () => context.push('/admin/menu/new'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsManagement(BuildContext context) {
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
              Text('Cài đặt hệ thống', style: AppTextStyles.heading18),
              TextButton(
                onPressed: () => context.push('/admin/config'),
                child: Text(
                  'Cấu hình',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDriverManagementCard(
                  context: context,
                  icon: Icons.tune_outlined,
                  label: 'Feature Flags',
                  color: const Color(0xFF8B5CF6),
                  onTap: () => context.push('/admin/config'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDriverManagementCard(
                  context: context,
                  icon: Icons.rule_outlined,
                  label: 'Quy tắc',
                  color: const Color(0xFF10B981),
                  onTap: () => context.push('/admin/config'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDriverManagementCard(
                  context: context,
                  icon: Icons.settings_outlined,
                  label: 'Giới hạn',
                  color: const Color(0xFFF59E0B),
                  onTap: () => context.push('/admin/config'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionManagement(BuildContext context, WidgetRef ref) {
    final activeCountAsync = ref.watch(activePromotionsCountProvider);
    
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
              Text('Khuyến mãi', style: AppTextStyles.heading18),
              TextButton(
                onPressed: () => context.push('/admin/promotions'),
                child: Text(
                  'Quản lý',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDriverManagementCard(
                  context: context,
                  icon: Icons.local_offer_outlined,
                  label: activeCountAsync.when(
                    data: (count) => '$count đang chạy',
                    loading: () => 'Đang tải...',
                    error: (e, s) => 'Lỗi',
                  ),
                  color: const Color(0xFF10B981),
                  onTap: () => context.push('/admin/promotions'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDriverManagementCard(
                  context: context,
                  icon: Icons.add_circle_outline,
                  label: 'Tạo mới',
                  color: const Color(0xFF8B5CF6),
                  onTap: () => context.push('/admin/promotions'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDriverManagementCard(
                  context: context,
                  icon: Icons.bar_chart_outlined,
                  label: 'Thống kê',
                  color: const Color(0xFFF59E0B),
                  onTap: () => context.push('/admin/promotions'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
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
          Text('Thống kê nhanh', style: AppTextStyles.heading18),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickStatItem(
                  label: 'Cửa hàng',
                  value: '24',
                  icon: Icons.store_outlined,
                ),
              ),
              Expanded(
                child: _buildQuickStatItem(
                  label: 'Tài xế',
                  value: '156',
                  icon: Icons.delivery_dining_outlined,
                ),
              ),
              Expanded(
                child: _buildQuickStatItem(
                  label: 'Khách hàng',
                  value: '1.2K',
                  icon: Icons.people_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickStatItem(
                  label: 'Đơn chờ xử lý',
                  value: '12',
                  icon: Icons.pending_outlined,
                  color: const Color(0xFFF59E0B),
                ),
              ),
              Expanded(
                child: _buildQuickStatItem(
                  label: 'Đơn đang giao',
                  value: '8',
                  icon: Icons.local_shipping_outlined,
                  color: AppColors.primary,
                ),
              ),
              Expanded(
                child: _buildQuickStatItem(
                  label: 'Đơn hoàn thành',
                  value: '1,214',
                  icon: Icons.check_circle_outline,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatItem({
    required String label,
    required String value,
    required IconData icon,
    Color? color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 28, color: color ?? AppColors.textSecondary),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
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
              Text('Hoạt động gần đây', style: AppTextStyles.heading18),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Xem tất cả',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ActivityTimelineItem(
            icon: Icons.store,
            title: 'Cửa hàng mới đăng ký',
            subtitle: 'Quán Phở Bò Gia Truyền',
            time: '5 phút trước',
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          ActivityTimelineItem(
            icon: Icons.receipt_long,
            title: 'Đơn hàng mới',
            subtitle: 'Đơn #1234 - 250,000 đ',
            time: '12 phút trước',
            color: AppColors.success,
          ),
          const SizedBox(height: 12),
          ActivityTimelineItem(
            icon: Icons.warning_amber_rounded,
            title: 'Cảnh báo hệ thống',
            subtitle: 'Lưu lượng truy cập cao',
            time: '1 giờ trước',
            color: const Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemHealth() {
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
          Text('Tình trạng hệ thống', style: AppTextStyles.heading18),
          const SizedBox(height: 16),
          HealthStatusItem(
            label: 'Server',
            status: 'Hoạt động bình thường',
            isHealthy: true,
          ),
          const SizedBox(height: 12),
          HealthStatusItem(
            label: 'Database',
            status: 'Hoạt động bình thường',
            isHealthy: true,
          ),
          const SizedBox(height: 12),
          HealthStatusItem(
            label: 'API',
            status: 'Hoạt động bình thường',
            isHealthy: true,
          ),
        ],
      ),
    );
  }
}
