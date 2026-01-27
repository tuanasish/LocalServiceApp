import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../ui/design_system.dart';
import '../../providers/app_providers.dart';
import '../../providers/cart_provider.dart';
import '../../data/models/order_model.dart';
import '../../data/models/order_item_model.dart';
import 'package:intl/intl.dart';

/// Order History Screen
/// Danh sách lịch sử đơn hàng của user: tất cả, đang xử lý, đã hoàn thành, đã hủy.
class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> {
  String _selectedFilter = 'Tất cả';
  
  // Cache filtered orders để tránh tính lại mỗi build
  List<OrderModel>? _cachedFilteredOrders;
  String? _cachedFilter;
  List<OrderModel>? _cachedOrders;

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(myOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            const AppSimpleHeader(title: 'Đơn hàng của tôi'),
            _buildFilterTabs(),
            Expanded(
              child: ordersAsync.when(
                data: (orders) {
                  // Cache filtered orders - chỉ tính lại khi filter hoặc orders thay đổi
                  if (_cachedFilter != _selectedFilter || 
                      _cachedOrders != orders ||
                      _cachedFilteredOrders == null) {
                    _cachedFilteredOrders = _filterOrders(orders);
                    _cachedFilter = _selectedFilter;
                    _cachedOrders = orders;
                  }
                  
                  final filteredOrders = _cachedFilteredOrders!;
                  if (filteredOrders.isEmpty) {
                    return _buildEmptyState();
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      // Invalidate provider để trigger refresh
                      ref.invalidate(myOrdersProvider);
                      // Invalidate cache khi refresh
                      _cachedFilteredOrders = null;
                      _cachedOrders = null;
                      // Đợi provider refresh
                      await ref.read(myOrdersProvider.future);
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredOrders.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _OrderCard(order: filteredOrders[index]),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _buildErrorState(error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<OrderModel> _filterOrders(List<OrderModel> orders) {
    if (_selectedFilter == 'Tất cả') return orders;
    if (_selectedFilter == 'Đang xử lý') {
      return orders.where((o) => 
        o.status != OrderStatus.completed && o.status != OrderStatus.canceled).toList();
    }
    if (_selectedFilter == 'Đã hoàn thành') {
      return orders.where((o) => o.status == OrderStatus.completed).toList();
    }
    if (_selectedFilter == 'Đã hủy') {
      return orders.where((o) => o.status == OrderStatus.canceled).toList();
    }
    return orders;
  }

  Widget _buildFilterTabs() {
    final filters = ['Tất cả', 'Đang xử lý', 'Đã hoàn thành', 'Đã hủy'];
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
      child: SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: filters.length,
          itemBuilder: (context, index) {
            final filter = filters[index];
            final isActive = filter == _selectedFilter;
            return Padding(
              padding: EdgeInsets.only(right: index < filters.length - 1 ? 8 : 0),
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedFilter = filter);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: isActive ? AppColors.primary : AppColors.borderSoft,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      filter,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isActive ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Chưa có đơn hàng nào',
            style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Các đơn hàng của bạn sẽ xuất hiện tại đây',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
            const SizedBox(height: 16),
            Text('Đã có lỗi xảy ra', style: AppTextStyles.heading18),
            const SizedBox(height: 8),
            Text(error.toString(), textAlign: TextAlign.center, style: AppTextStyles.body13Secondary),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.refresh(myOrdersProvider),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  final OrderModel order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _getStatusColor(order.status);
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt);
    
    // Tối ưu: Dùng select() để chỉ watch name field thay vì toàn bộ merchant
    String storeName = 'Đơn hàng dịch vụ';
    if (order.shopId != null) {
      final merchantAsync = ref.watch(merchantDetailProvider(order.shopId!));
      storeName = merchantAsync.when(
        data: (merchant) => merchant.name,
        loading: () => 'Đang tải...',
        error: (_, __) {
          final shopId = order.shopId!;
          return 'Cửa hàng #${shopId.length > 4 ? shopId.substring(0, 4) : shopId}';
        },
      );
    }

    return GestureDetector(
      onTap: () => context.push('/orders/${order.id}'),
      child: Container(
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
                Text(
                  '#${order.orderNumber}',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    order.status.displayName,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.store_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    storeName,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  formattedDate,
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                ),
                const Spacer(),
                Text(
                  '${_formatPrice(order.totalAmount)}đ',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (order.status == OrderStatus.completed)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                    ),
                    onPressed: () => _handleReorder(context, ref, order, storeName),
                    child: Text(
                      'Đặt lại',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                if (order.status != OrderStatus.completed && order.status != OrderStatus.canceled) ...[
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                    ),
                    onPressed: () => context.push('/orders/${order.id}'),
                    child: Text(
                      'Theo dõi',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.completed:
        return AppColors.success;
      case OrderStatus.canceled:
        return AppColors.danger;
      case OrderStatus.pickedUp:
      case OrderStatus.readyForPickup:
      case OrderStatus.confirmed:
      case OrderStatus.assigned:
        return const Color(0xFFF59E0B); // Amber
      default:
        return AppColors.primary;
    }
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  Future<void> _handleReorder(
    BuildContext context,
    WidgetRef ref,
    OrderModel order,
    String shopName,
  ) async {
    // Load order items từ repository
    List<OrderItemModel> items;
    try {
      items = await ref.read(orderRepositoryProvider).getOrderItems(order.id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể tải thông tin đơn hàng')),
        );
      }
      return;
    }

    if (items.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đơn hàng này không có sản phẩm')),
        );
      }
      return;
    }

    // Check conflict với cart hiện tại
    final cart = ref.read(cartProvider);
    final hasConflict = cart.isNotEmpty &&
        order.shopId != null &&
        cart.first.shopId != order.shopId;

    if (hasConflict) {
      // Show confirm dialog
      final shouldClear = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Giỏ hàng hiện tại'),
          content: const Text(
            'Giỏ hàng của bạn đang có sản phẩm từ cửa hàng khác. '
            'Bạn có muốn xóa và thay thế bằng đơn hàng này không?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Xóa và đặt lại'),
            ),
          ],
        ),
      );

      if (shouldClear != true || !context.mounted) return;
    }

    // Reorder
    final success = ref.read(cartProvider.notifier).reorderFromOrder(
          order: order,
          orderItems: items,
          shopName: shopName,
          forceClear: hasConflict,
        );

    if (!success) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể đặt lại đơn hàng')),
        );
      }
      return;
    }

    // Navigate
    if (!context.mounted) return;

    if (order.shopId != null) {
      context.push('/shops/${order.shopId}');
    } else {
      context.push('/checkout');
    }
  }
}
