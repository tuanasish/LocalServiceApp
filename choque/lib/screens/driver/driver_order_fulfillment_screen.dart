import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../ui/design_system.dart';
import '../../providers/app_providers.dart';
import '../../data/models/order_model.dart';
import '../../data/models/order_item_model.dart';
import '../../services/location_tracking_service.dart';
import '../../services/navigation_service.dart';
import '../../ui/widgets/order_tracking_map.dart';

/// Driver Order Fulfillment Screen
/// Màn chi tiết đơn hàng đang giao: thông tin đơn, địa chỉ, timeline, nút hành động.
class DriverOrderFulfillmentScreen extends ConsumerStatefulWidget {
  final String orderId;

  const DriverOrderFulfillmentScreen({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<DriverOrderFulfillmentScreen> createState() => _DriverOrderFulfillmentScreenState();
}

class _DriverOrderFulfillmentScreenState extends ConsumerState<DriverOrderFulfillmentScreen> {
  bool _isUpdatingStatus = false;
  LocationTrackingService? _locationService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _locationService = LocationTrackingService(ref.read(driverRepositoryProvider));
    });
  }

  @override
  void dispose() {
    _locationService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));
    
    // Auto start/stop location tracking
    orderAsync.whenData((order) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (order.status == OrderStatus.assigned || order.status == OrderStatus.pickedUp) {
          _startLocationTracking(order.id);
        } else {
          _stopLocationTracking();
        }
      });
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: orderAsync.when(
          data: (order) => Column(
            children: [
              AppSimpleHeader(title: 'Đơn hàng #${order.orderNumber}'),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(orderDetailProvider(widget.orderId));
                    ref.invalidate(orderItemsProvider(widget.orderId));
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          _buildOrderInfoCard(order),
                          const SizedBox(height: 20),
                          _buildRealtimeMap(order),
                          const SizedBox(height: 20),
                          _buildTimeline(order),
                          const SizedBox(height: 20),
                          _buildStoreInfo(order),
                          const SizedBox(height: 16),
                          _buildCustomerInfo(order),
                          const SizedBox(height: 20),
                          _buildOrderItems(widget.orderId),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          loading: () => Column(
            children: [
              const AppSimpleHeader(title: 'Đơn hàng'),
              const Expanded(child: Center(child: CircularProgressIndicator())),
            ],
          ),
          error: (error, stack) => Column(
            children: [
              const AppSimpleHeader(title: 'Đơn hàng'),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: AppColors.danger),
                        const SizedBox(height: 16),
                        Text(
                          'Lỗi tải đơn hàng',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
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
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            ref.invalidate(orderDetailProvider(widget.orderId));
                          },
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: orderAsync.when(
        data: (order) => _buildBottomBar(order),
        loading: () => null,
        error: (e, st) => null,
      ),
    );
  }

  Widget _buildOrderInfoCard(OrderModel order) {
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
              Text(
                '#${order.orderNumber}',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(order.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  _getStatusText(order.status),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(order.status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.attach_money_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Phí giao hàng: ${_formatPrice(order.deliveryFee)}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build realtime tracking map with distance/ETA info
  Widget _buildRealtimeMap(OrderModel order) {
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
              Text(
                'Bản đồ giao hàng',
                style: AppTextStyles.heading18,
              ),
              const Spacer(),
              // Navigate to external map
              IconButton(
                onPressed: () => NavigationService.openNavigationApp(
                  lat: order.status == OrderStatus.assigned
                      ? order.pickup.lat
                      : order.dropoff.lat,
                  lng: order.status == OrderStatus.assigned
                      ? order.pickup.lng
                      : order.dropoff.lng,
                  label: order.status == OrderStatus.assigned
                      ? 'Cửa hàng'
                      : 'Khách hàng',
                ),
                icon: const Icon(Icons.directions, color: AppColors.primary),
                tooltip: 'Mở chỉ đường',
              ),
            ],
          ),
          const SizedBox(height: 12),
          OrderTrackingMapWidget(order: order),
        ],
      ),
    );
  }

  Widget _buildTimeline(OrderModel order) {
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
          Text(
            'Tiến trình',
            style: AppTextStyles.heading18,
          ),
          const SizedBox(height: 20),
          _buildTimelineItem(
            icon: Icons.check_circle,
            iconColor: AppColors.primary,
            title: 'Đã nhận đơn',
            subtitle: order.assignedAt != null 
                ? DateFormat('HH:mm • dd/MM/yyyy').format(order.assignedAt!)
                : '',
            isCompleted: order.status != OrderStatus.pendingConfirmation,
            isLast: false,
          ),
          _buildTimelineItem(
            icon: Icons.store_outlined,
            iconColor: AppColors.primary,
            title: 'Đã đến cửa hàng',
            subtitle: order.pickedUpAt != null 
                ? '${DateFormat('HH:mm').format(order.pickedUpAt!)} • Đã lấy hàng'
                : '',
            isCompleted: order.status == OrderStatus.pickedUp || order.status == OrderStatus.completed,
            isLast: false,
          ),
          _buildTimelineItem(
            icon: Icons.delivery_dining,
            iconColor: AppColors.primary,
            title: 'Đang giao hàng',
            subtitle: order.status == OrderStatus.pickedUp 
                ? 'Đang trên đường đến khách hàng'
                : '',
            isCompleted: order.status == OrderStatus.pickedUp,
            isLast: false,
          ),
          _buildTimelineItem(
            icon: Icons.check_circle_outline,
            iconColor: AppColors.textMuted,
            title: 'Hoàn thành',
            subtitle: order.completedAt != null 
                ? DateFormat('HH:mm • dd/MM/yyyy').format(order.completedAt!)
                : '',
            isCompleted: order.status == OrderStatus.completed,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.textMuted.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: isCompleted ? iconColor : AppColors.textMuted,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: isCompleted
                    ? AppColors.primary.withValues(alpha: 0.3)
                    : AppColors.textMuted.withValues(alpha: 0.2),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: isCompleted ? FontWeight.w600 : FontWeight.w500,
                    color: isCompleted
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.body13Secondary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStoreInfo(OrderModel order) {
    final merchantAsync = order.shopId != null 
        ? ref.watch(merchantDetailProvider(order.shopId!))
        : null;

    return merchantAsync?.when(
      data: (merchant) => Container(
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
                const Icon(
                  Icons.store_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Cửa hàng',
                  style: AppTextStyles.label14,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              merchant.name,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              order.pickup.address ?? order.pickup.label,
              style: AppTextStyles.body13Secondary,
            ),
            if (merchant.phone != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                      onPressed: () {
                        // TODO: Implement phone call
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Gọi số: ${merchant.phone}'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.phone_outlined,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      label: Text(
                        'Gọi cửa hàng',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                      onPressed: () async {
                        final success = await NavigationService.openNavigationApp(
                          lat: order.pickup.lat,
                          lng: order.pickup.lng,
                          label: merchant.name,
                        );
                        if (!success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Không thể mở ứng dụng chỉ đường'),
                              backgroundColor: AppColors.danger,
                            ),
                          );
                        }
                      },
                      icon: const Icon(
                        Icons.navigation,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: Text(
                        'Chỉ đường',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      loading: () => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.large),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => const SizedBox.shrink(),
    ) ?? const SizedBox.shrink();
  }

  Widget _buildCustomerInfo(OrderModel order) {
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
              const Icon(
                Icons.person_outline,
                size: 20,
                color: Color(0xFF0EA5E9),
              ),
              const SizedBox(width: 8),
              Text(
                'Khách hàng',
                style: AppTextStyles.label14,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            order.customerName ?? 'Khách hàng',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (order.customerPhone != null) ...[
            const SizedBox(height: 6),
            Text(
              order.customerPhone!,
              style: AppTextStyles.body13Secondary,
            ),
          ],
          const SizedBox(height: 8),
          Text(
            order.dropoff.address ?? order.dropoff.label,
            style: AppTextStyles.body13Secondary,
          ),
          if (order.customerPhone != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: const BorderSide(color: Color(0xFF0EA5E9)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                    onPressed: () {
                      // TODO: Implement phone call
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Gọi số: ${order.customerPhone}'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.phone_outlined,
                      size: 16,
                      color: Color(0xFF0EA5E9),
                    ),
                    label: Text(
                      'Gọi khách',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0EA5E9),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0EA5E9),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                    onPressed: () async {
                      final success = await NavigationService.openNavigationApp(
                        lat: order.dropoff.lat,
                        lng: order.dropoff.lng,
                        label: order.customerName ?? 'Khách hàng',
                      );
                      if (!success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Không thể mở ứng dụng chỉ đường'),
                            backgroundColor: AppColors.danger,
                          ),
                        );
                      }
                    },
                    icon: const Icon(
                      Icons.navigation,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: Text(
                      'Chỉ đường',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderItems(String orderId) {
    return Consumer(
      builder: (context, ref, child) {
        final itemsAsync = ref.watch(orderItemsProvider(orderId));

        return itemsAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return const SizedBox.shrink();
            }

            final subtotal = items.fold<int>(0, (sum, item) => sum + item.subtotal);

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
                  Text(
                    'Đơn hàng',
                    style: AppTextStyles.heading18,
                  ),
                  const SizedBox(height: 12),
                  ...items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildOrderItemRow(item),
                      )),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tổng cộng',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        _formatPrice(subtotal),
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
          loading: () => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.large),
            ),
            child: const Center(child: CircularProgressIndicator()),
          ),
          error: (e, st) => const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildOrderItemRow(OrderItemModel item) {
    return Row(
      children: [
        Expanded(
          child: Text(
            item.productName,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'x${item.quantity}',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _formatPrice(item.subtotal),
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(OrderModel order) {
    final canPickUp = order.status == OrderStatus.assigned;
    final canComplete = order.status == OrderStatus.pickedUp;

    if (!canPickUp && !canComplete) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (canPickUp) ...[
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                onPressed: _isUpdatingStatus ? null : () => _rejectOrder(order),
                child: Text(
                  'Hủy đơn',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                onPressed: _isUpdatingStatus ? null : () => _updateStatus(order, OrderStatus.pickedUp),
                child: _isUpdatingStatus
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Đã lấy hàng',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
          if (canComplete) ...[
            Expanded(
              flex: 2,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                onPressed: _isUpdatingStatus ? null : () => _updateStatus(order, OrderStatus.completed),
                child: _isUpdatingStatus
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Đã giao hàng',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _startLocationTracking(String orderId) async {
    if (_locationService?.isTracking == true && _locationService?.currentOrderId == orderId) {
      return; // Đã đang track
    }
    
    try {
      await _locationService?.startTracking(orderId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể bắt đầu tracking: ${e.toString()}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _stopLocationTracking() async {
    await _locationService?.stopTracking();
  }

  Future<void> _rejectOrder(OrderModel order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy nhận đơn'),
        content: const Text('Bạn có chắc chắn muốn hủy nhận đơn hàng này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Bỏ qua'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isUpdatingStatus = true);
    try {
      await ref.read(driverRepositoryProvider).rejectOrder(order.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã hủy nhận đơn hàng'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/driver');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  Future<void> _updateStatus(OrderModel order, OrderStatus newStatus) async {
    setState(() => _isUpdatingStatus = true);

    try {
      await ref.read(orderRepositoryProvider).updateOrderStatus(order.id, newStatus);
      ref.invalidate(orderDetailProvider(widget.orderId));
      ref.invalidate(assignedOrdersProvider);
      ref.invalidate(driverOrdersStreamProvider);
      
      // Stop tracking nếu completed
      if (newStatus == OrderStatus.completed) {
        await _stopLocationTracking();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã cập nhật trạng thái: ${_getStatusText(newStatus)}'),
            backgroundColor: AppColors.success,
          ),
        );
        
        // Nếu completed, quay về dashboard
        if (newStatus == OrderStatus.completed) {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              context.go('/driver');
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingStatus = false);
      }
    }
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.readyForPickup:
      case OrderStatus.confirmed:
      case OrderStatus.assigned:
        return 'Đã nhận đơn';
      case OrderStatus.pickedUp:
        return 'Đang giao';
      case OrderStatus.completed:
        return 'Hoàn thành';
      default:
        return 'Khác';
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.readyForPickup:
      case OrderStatus.confirmed:
      case OrderStatus.assigned:
        return AppColors.primary;
      case OrderStatus.pickedUp:
        return const Color(0xFF0EA5E9);
      case OrderStatus.completed:
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatPrice(int price) {
    final formatted = price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '$formattedđ';
  }
}
