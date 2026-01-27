import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../ui/design_system.dart';
import '../../ui/widgets/stat_card.dart';
import '../../ui/widgets/merchant_order_card.dart';
import '../../providers/app_providers.dart';
import '../../data/models/order_model.dart';
import '../../data/models/order_item_model.dart';
import '../../data/repositories/merchant_repository.dart';
import 'merchant_profile_screen.dart';

/// Merchant Order Dashboard Screen
/// Dashboard cho chủ cửa hàng: thống kê đơn hàng, danh sách đơn mới/chờ xử lý.
class MerchantOrderDashboardScreen extends ConsumerStatefulWidget {
  const MerchantOrderDashboardScreen({super.key});

  @override
  ConsumerState<MerchantOrderDashboardScreen> createState() => _MerchantOrderDashboardScreenState();
}

class _MerchantOrderDashboardScreenState extends ConsumerState<MerchantOrderDashboardScreen> {
  String? _selectedStatus; // null = Tất cả, 'PENDING_CONFIRMATION' = Mới, 'CONFIRMED' = Đang xử lý

  @override
  Widget build(BuildContext context) {
    final shopAsync = ref.watch(myShopProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: shopAsync.when(
          data: (shop) {
            if (shop == null) {
              return _buildNoShopState();
            }
            return _buildContent(shop.id);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorState(error.toString()),
        ),
      ),
    );
  }

  Widget _buildNoShopState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_outlined, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'Chưa có cửa hàng',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bạn chưa được gán vào cửa hàng nào. Vui lòng liên hệ admin.',
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

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.danger),
            const SizedBox(height: 16),
            Text(
              'Có lỗi xảy ra',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(myShopProvider),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(String shopId) {
    return Column(
      children: [
        _buildHeader(shopId),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(myShopProvider);
              ref.invalidate(shopStatsProvider(shopId));
              if (_selectedStatus != null) {
                ref.invalidate(shopOrdersProvider(ShopOrdersParams(shopId: shopId, status: _selectedStatus)));
              } else {
                ref.invalidate(shopOrdersProvider(ShopOrdersParams(shopId: shopId)));
              }
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildStatsCards(shopId),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Thao tác nhanh'),
                    const SizedBox(height: 12),
                    _buildQuickActions(context),
                    const SizedBox(height: 30),
                    _buildTabs(shopId),
                    const SizedBox(height: 16),
                    _buildOrderList(shopId),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(String shopId) {
    final shopAsync = ref.watch(merchantDetailProvider(shopId));

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
      child: shopAsync.when(
        data: (shop) => Row(
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
                    shop.name,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    shop.status == 'active' ? 'Đang mở cửa' : 'Đã đóng cửa',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: shop.status == 'active' ? AppColors.success : AppColors.textSecondary,
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
        loading: () => const SizedBox(height: 56, child: Center(child: CircularProgressIndicator())),
        error: (_, __) => const SizedBox(height: 56),
      ),
    );
  }

  Widget _buildStatsCards(String shopId) {
    final statsAsync = ref.watch(shopStatsProvider(shopId));

    return statsAsync.when(
      data: (stats) {
        final pendingCount = stats['pending_orders'] as int? ?? 0;
        final preparingCount = stats['preparing_orders'] as int? ?? 0;
        final completedCount = stats['completed_orders'] as int? ?? 0;

        return Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.receipt_long_outlined,
                label: 'Đơn mới',
                value: pendingCount.toString(),
                color: AppColors.primary,
                showBadge: pendingCount > 0,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                icon: Icons.access_time_outlined,
                label: 'Đang xử lý',
                value: preparingCount.toString(),
                color: const Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                icon: Icons.check_circle_outline,
                label: 'Hoàn thành',
                value: completedCount.toString(),
                color: AppColors.success,
              ),
            ),
          ],
        );
      },
      loading: () => Row(
        children: [
          Expanded(child: _buildStatCardSkeleton()),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCardSkeleton()),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCardSkeleton()),
        ],
      ),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildStatCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.borderSoft,
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 60,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.borderSoft,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 40,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.borderSoft,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(String shopId) {
    final statsAsync = ref.watch(shopStatsProvider(shopId));
    final pendingCount = statsAsync.asData?.value?['pending_orders'] as int? ?? 0;

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
            child: _buildTabButton(
              'Tất cả',
              isActive: _selectedStatus == null,
              onTap: () => setState(() => _selectedStatus = null),
            ),
          ),
          Expanded(
            child: _buildTabButton(
              'Mới',
              isActive: _selectedStatus == 'PENDING_CONFIRMATION',
              badge: pendingCount > 0 ? pendingCount.toString() : null,
              onTap: () => setState(() => _selectedStatus = 'PENDING_CONFIRMATION'),
            ),
          ),
          Expanded(
            child: _buildTabButton(
              'Đang xử lý',
              isActive: _selectedStatus == 'CONFIRMED',
              onTap: () => setState(() => _selectedStatus = 'CONFIRMED'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(
    String label, {
    required bool isActive,
    String? badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            label: 'Quản lý\nProfile Shop',
            icon: Icons.store_outlined,
            color: AppColors.primary,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MerchantProfileScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            label: 'Quản lý\nMenu & Giá',
            icon: Icons.menu_book_outlined,
            color: Colors.blue,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chức năng đang phát triển')),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(String shopId) {
    final params = ShopOrdersParams(
      shopId: shopId,
      status: _selectedStatus,
      limit: 50,
    );
    
    // Use stream for real-time updates
    final ordersStreamAsync = ref.watch(shopOrdersStreamProvider(shopId));
    
    return ordersStreamAsync.when(
      data: (allOrders) {
        // Filter by selected status
        final orders = _selectedStatus == null
            ? allOrders
            : allOrders.where((order) => order.status.toDbString() == _selectedStatus).toList();
            
        if (orders.isEmpty) {
          return _buildEmptyState();
        }
        return Column(
          children: orders.map((order) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildOrderCard(order, shopId),
            );
          }).toList(),
        );
      },
      loading: () => Column(
        children: List.generate(3, (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildOrderCardSkeleton(),
        )),
      ),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.danger),
              const SizedBox(height: 8),
              Text(
                'Lỗi tải đơn hàng',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(shopOrdersProvider(params)),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order, String shopId) {
    // Lấy order items để hiển thị
    final itemsAsync = ref.watch(orderItemsProvider(order.id));

    return itemsAsync.when(
      data: (items) {
        final itemsText = items.map((item) => '${item.productName} x${item.quantity}').join(', ');
        final statusText = _getStatusText(order.status);
        final timeText = DateFormat('HH:mm').format(order.createdAt);

        return GestureDetector(
          onTap: () {
            context.push('/merchant/order/${order.id}');
          },
          child: MerchantOrderCard(
            orderId: '#${order.orderNumber}',
            customerName: order.customerName ?? 'Khách hàng',
            items: itemsText,
            total: _formatPrice(order.totalAmount),
            time: timeText,
            status: statusText,
            isUrgent: order.status == OrderStatus.pendingConfirmation,
            onAccept: () => _handleConfirm(order),
            onReject: () => _handleReject(order),
            onMarkReady: () => _handleMarkReady(order),
          ),
        );
      },
      loading: () => _buildOrderCardSkeleton(),
      error: (_, __) => MerchantOrderCard(
        orderId: '#${order.orderNumber}',
        customerName: order.customerName ?? 'Khách hàng',
        items: 'Đang tải...',
        total: _formatPrice(order.totalAmount),
        time: DateFormat('HH:mm').format(order.createdAt),
        status: _getStatusText(order.status),
        isUrgent: false,
      ),
    );
  }

  Widget _buildOrderCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(width: 100, height: 16, color: AppColors.borderSoft),
              Container(width: 60, height: 20, color: AppColors.borderSoft),
            ],
          ),
          const SizedBox(height: 12),
          Container(width: 150, height: 14, color: AppColors.borderSoft),
          const SizedBox(height: 8),
          Container(width: 200, height: 12, color: AppColors.borderSoft),
        ],
      ),
    );
  }

  Future<void> _handleConfirm(OrderModel order) async {
    try {
      await ref.read(merchantRepositoryProvider).confirmOrder(order.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xác nhận đơn hàng')),
        );
        ref.invalidate(shopStatsProvider(order.shopId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _handleReject(OrderModel order) async {
    final reasonController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Từ chối đơn hàng'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: 'Nhập lý do từ chối...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      try {
        await ref.read(merchantRepositoryProvider).rejectOrder(
          order.id, 
          reasonController.text.isEmpty ? 'Merchant từ chối' : reasonController.text
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã từ chối đơn hàng')),
          );
          ref.invalidate(shopStatsProvider(order.shopId));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.danger),
          );
        }
      }
    }
  }

  Future<void> _handleMarkReady(OrderModel order) async {
    try {
      await ref.read(merchantRepositoryProvider).markOrderReady(order.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã báo sẵn sàng')),
        );
        ref.invalidate(shopStatsProvider(order.shopId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'Chưa có đơn hàng',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedStatus == null
                ? 'Bạn chưa có đơn hàng nào'
                : 'Không có đơn hàng ở trạng thái này',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pendingConfirmation:
        return 'Mới';
      case OrderStatus.confirmed:
        return 'Đang chuẩn bị';
      case OrderStatus.readyForPickup:
        return 'Sẵn sàng';
      case OrderStatus.assigned:
        return 'Đã gán tài xế';
      case OrderStatus.pickedUp:
        return 'Đang giao';
      case OrderStatus.completed:
        return 'Hoàn thành';
      case OrderStatus.canceled:
        return 'Đã hủy';
    }
  }

  String _formatPrice(int price) {
    final formatted = price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '${formatted}đ';
  }
}
