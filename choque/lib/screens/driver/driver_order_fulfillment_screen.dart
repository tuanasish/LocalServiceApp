import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../ui/design_system.dart';
import '../../ui/widgets/order_timeline_stepper.dart';
import '../../providers/app_providers.dart';
import '../../data/models/order_model.dart';
import '../../data/models/order_item_model.dart';
import '../../services/location_tracking_service.dart';
import '../../services/navigation_service.dart';
import '../../ui/widgets/order_tracking_map.dart';
import '../../ui/widgets/stream_error_widget.dart';

/// Driver Order Fulfillment Screen
/// Màn chi tiết đơn hàng đang giao: thông tin đơn, địa chỉ, timeline, nút hành động.
class DriverOrderFulfillmentScreen extends ConsumerStatefulWidget {
  final String orderId;

  const DriverOrderFulfillmentScreen({super.key, required this.orderId});

  @override
  ConsumerState<DriverOrderFulfillmentScreen> createState() =>
      _DriverOrderFulfillmentScreenState();
}

class _DriverOrderFulfillmentScreenState
    extends ConsumerState<DriverOrderFulfillmentScreen> {
  bool _isUpdatingStatus = false;
  LocationTrackingService? _locationService;
  final Map<String, bool> _itemChecked = {}; // Track checked items

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _locationService = LocationTrackingService(
        ref.read(driverRepositoryProvider),
      );

      // Listen to order changes for auto-start/stop tracking
      ref.listen(orderDetailProvider(widget.orderId), (previous, next) {
        next.whenData((order) {
          if (order.status == OrderStatus.assigned ||
              order.status == OrderStatus.pickedUp) {
            _startLocationTracking(order.id);
          } else {
            _stopLocationTracking();
          }
        });
      });
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

    return Scaffold(
      backgroundColor: AppColors.driverBackgroundLight,
      body: SafeArea(
        child: orderAsync.when(
          data: (order) => Column(
            children: [
              _buildHeader(order),
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
                          OrderTimelineStepper(currentStatus: order.status),
                          const SizedBox(height: 20),
                          _buildMerchantCardWithMap(order),
                          const SizedBox(height: 16),
                          _buildOrderItemsChecklist(widget.orderId),
                          const SizedBox(height: 16),
                          _buildCustomerCard(order),
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
              _buildHeader(null),
              const Expanded(child: Center(child: CircularProgressIndicator())),
            ],
          ),
          error: (error, stack) => Column(
            children: [
              _buildHeader(null),
              Expanded(
                child: StreamErrorWidget(
                  error: error,
                  title: 'Lỗi tải đơn hàng',
                  onRetry: () {
                    ref.invalidate(orderDetailProvider(widget.orderId));
                  },
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

  Widget _buildHeader(OrderModel? order) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderSoft,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
            color: AppColors.textPrimary,
          ),
          Expanded(
            child: Text(
              order != null ? 'Đơn hàng #${order.orderNumber}' : 'Đơn hàng',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              // TODO: Show help
            },
            icon: const Icon(Icons.help_outline),
            color: AppColors.primary,
          ),
        ],
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
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
              Text('Bản đồ giao hàng', style: AppTextStyles.heading18),
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

  Widget _buildMerchantCardWithMap(OrderModel order) {
    final merchantAsync = order.shopId != null
        ? ref.watch(merchantDetailProvider(order.shopId!))
        : null;

    return merchantAsync?.when(
          data: (merchant) => Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.large),
              boxShadow: AppShadows.soft(0.04),
              border: Border.all(
                color: AppColors.borderSoft,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // Map image background
                Container(
                  height: 128,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.borderSoft,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppRadius.large),
                      topRight: Radius.circular(AppRadius.large),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppRadius.large),
                      topRight: Radius.circular(AppRadius.large),
                    ),
                    child: Container(
                      color: AppColors.borderSoft,
                      child: const Center(
                        child: Icon(
                          Icons.map,
                          size: 48,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ĐIỂM LẤY HÀNG',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  merchant.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => NavigationService.openNavigationApp(
                              lat: order.pickup.lat,
                              lng: order.pickup.lng,
                              label: merchant.name,
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.medium),
                              ),
                            ),
                            icon: const Icon(
                              Icons.near_me,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            label: Text(
                              'Chỉ đường',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 18,
                            color: AppColors.driverTextSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              order.pickup.address ?? order.pickup.label,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.driverTextSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          loading: () => Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.large),
            ),
            child: const Center(child: CircularProgressIndicator()),
          ),
          error: (e, st) => const SizedBox.shrink(),
        ) ??
        const SizedBox.shrink();
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
                    Text('Cửa hàng', style: AppTextStyles.label14),
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
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
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
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                          ),
                          onPressed: () async {
                            final success =
                                await NavigationService.openNavigationApp(
                                  lat: order.pickup.lat,
                                  lng: order.pickup.lng,
                                  label: merchant.name,
                                );
                            if (!success && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Không thể mở ứng dụng chỉ đường',
                                  ),
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
        ) ??
        const SizedBox.shrink();
  }

  Widget _buildCustomerCard(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        boxShadow: AppShadows.soft(0.04),
        border: Border.all(
          color: AppColors.borderSoft,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ĐIỂM GIAO HÀNG',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
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
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.customerName ?? 'Khách hàng',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (order.customerPhone != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              order.customerPhone!,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.driverTextSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (order.customerPhone != null) ...[
                const SizedBox(width: 8),
                // Call button
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.call,
                      size: 20,
                      color: AppColors.primary,
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
                  ),
                ),
                const SizedBox(width: 8),
                // Chat button
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.chat,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    onPressed: () {
                      // TODO: Navigate to chat
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Navigation button
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.near_me,
                      size: 20,
                      color: Colors.white,
                    ),
                    onPressed: () => NavigationService.openNavigationApp(
                      lat: order.dropoff.lat,
                      lng: order.dropoff.lng,
                      label: order.customerName ?? 'Khách hàng',
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAF9),
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on,
                  size: 18,
                  color: AppColors.driverTextSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.dropoff.address ?? order.dropoff.label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemsChecklist(String orderId) {
    return Consumer(
      builder: (context, ref, child) {
        final itemsAsync = ref.watch(orderItemsProvider(orderId));

        return itemsAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return const SizedBox.shrink();
            }

            return Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.large),
                boxShadow: AppShadows.soft(0.04),
                border: Border.all(
                  color: AppColors.borderSoft,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.borderSoft,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Text(
                      'Kiểm tra món ăn (${items.length} món)',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: items.map((item) {
                        return CheckboxListTile(
                          value: _itemChecked[item.id] ?? false,
                          onChanged: (value) {
                            setState(() {
                              _itemChecked[item.id] = value ?? false;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.medium),
                          ),
                          title: Text(
                            'x${item.quantity} ${item.productName}',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          subtitle: item.note != null && item.note!.isNotEmpty
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    item.note!,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppColors.driverTextSecondary,
                                    ),
                                  ),
                                )
                              : null,
                        );
                      }).toList(),
                    ),
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
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.borderSoft,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main CTA button
          if (canPickUp)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.large),
                  ),
                  elevation: 4,
                ),
                onPressed: _isUpdatingStatus
                    ? null
                    : () => _updateStatus(order, OrderStatus.pickedUp),
                child: _isUpdatingStatus
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        'Đã đến điểm lấy',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          if (canComplete)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.large),
                  ),
                  elevation: 4,
                ),
                onPressed: _isUpdatingStatus
                    ? null
                    : () => _updateStatus(order, OrderStatus.completed),
                child: _isUpdatingStatus
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        'Đã giao hàng',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          const SizedBox(height: 12),
          // Secondary action buttons (disabled style)
          Row(
            children: [
              Expanded(
                child: _buildSecondaryActionButton(
                  icon: Icons.inventory_2,
                  label: 'Lấy hàng',
                  enabled: canPickUp && order.status == OrderStatus.pickedUp,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSecondaryActionButton(
                  icon: Icons.local_shipping,
                  label: 'Giao đi',
                  enabled: canComplete,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSecondaryActionButton(
                  icon: Icons.verified,
                  label: 'Hoàn tất',
                  enabled: order.status == OrderStatus.completed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryActionButton({
    required IconData icon,
    required String label,
    required bool enabled,
  }) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: enabled ? AppColors.borderSoft : AppColors.borderSoft,
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: enabled
                ? AppColors.textSecondary
                : AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: enabled
                  ? AppColors.textSecondary
                  : AppColors.textSecondary.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startLocationTracking(String orderId) async {
    if (_locationService?.isTracking == true &&
        _locationService?.currentOrderId == orderId) {
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
      await ref
          .read(orderRepositoryProvider)
          .updateOrderStatus(order.id, newStatus);
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
            content: Text(
              'Đã cập nhật trạng thái: ${_getStatusText(newStatus)}',
            ),
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


  /// Build tracking status badge
  Widget _buildTrackingStatusBadge() {
    final isTracking = _locationService?.isTracking ?? false;

    if (!isTracking) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Đang theo dõi vị trí',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}
