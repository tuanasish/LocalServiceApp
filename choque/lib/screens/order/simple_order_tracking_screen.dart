import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../ui/design_system.dart';
import '../../ui/widgets/order_timeline_item.dart';
import '../../ui/widgets/order_tracking_map.dart';
import '../../providers/app_providers.dart';
import '../../data/models/order_model.dart';
import '../../data/models/order_item_model.dart';

/// Simple Order Tracking Screen
/// Hiển thị chi tiết đơn hàng và theo dõi trạng thái thời gian thực.
class SimpleOrderTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;
  const SimpleOrderTrackingScreen({super.key, required this.orderId});

  @override
  ConsumerState<SimpleOrderTrackingScreen> createState() =>
      _SimpleOrderTrackingScreenState();
}

class _SimpleOrderTrackingScreenState
    extends ConsumerState<SimpleOrderTrackingScreen> {
  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderStreamProvider(widget.orderId));
    final itemsAsync = ref.watch(orderItemsProvider(widget.orderId));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: orderAsync.when(
          data: (order) => Column(
            children: [
              AppSimpleHeader(title: 'Đơn hàng #${order.orderNumber}'),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        _buildOrderInfoCard(order),
                        const SizedBox(height: 24),
                        _buildTimeline(order),
                        const SizedBox(height: 24),
                        if (order.status == OrderStatus.assigned ||
                            order.status == OrderStatus.pickedUp)
                          _buildTrackingMap(order),
                        if (order.status == OrderStatus.assigned ||
                            order.status == OrderStatus.pickedUp)
                          const SizedBox(height: 24),
                        itemsAsync.when(
                          data: (items) => _buildItemsSummary(items),
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 24),
                        _buildStoreInfo(order),
                        const SizedBox(height: 16),
                        _buildDeliveryInfo(order),
                        const SizedBox(height: 24),
                        _buildActionButtons(order),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Lỗi: $err')),
        ),
      ),
    );
  }

  Widget _buildOrderInfoCard(OrderModel order) {
    final statusColor = _getStatusColor(order.status);
    final formattedDate = DateFormat(
      'HH:mm • dd/MM/yyyy',
    ).format(order.createdAt);

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
                  Text('Mã đơn hàng', style: AppTextStyles.body13Secondary),
                  const SizedBox(height: 4),
                  Text(
                    '#${order.orderNumber}',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  order.status.displayName,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
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
                'Đặt lúc: $formattedDate',
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
                  order.dropoff.address ?? order.dropoff.label,
                  style: AppTextStyles.body13Secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(OrderModel order) {
    bool isStepCompleted(OrderStatus step) {
      if (order.status == OrderStatus.canceled) return false;
      return order.status.index >= step.index;
    }

    bool isStepActive(OrderStatus step) {
      if (order.status == OrderStatus.canceled) return false;
      return order.status == step;
    }

    String formatTime(DateTime? dateTime) {
      if (dateTime == null) return '';
      return DateFormat('HH:mm, dd/MM/yyyy').format(dateTime);
    }

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
          // Bước 1: PENDING_CONFIRMATION
          OrderTimelineItem(
            icon: Icons.receipt_long,
            iconColor: AppColors.primary,
            title: 'Đã đặt hàng',
            subtitle:
                'Đơn hàng đã được ghi nhận lúc ${formatTime(order.createdAt)}',
            isCompleted: true,
            isActive: isStepActive(OrderStatus.pendingConfirmation),
          ),
          // Bước 2: CONFIRMED
          OrderTimelineItem(
            icon: Icons.check_circle,
            iconColor: AppColors.primary,
            title: 'Đã xác nhận',
            subtitle: order.confirmedAt != null
                ? 'Người bán đã nhận đơn lúc ${formatTime(order.confirmedAt!)}'
                : 'Đang chờ người bán xác nhận',
            isCompleted: isStepCompleted(OrderStatus.confirmed),
            isActive: isStepActive(OrderStatus.confirmed),
          ),
          // Bước 3: ASSIGNED
          OrderTimelineItem(
            icon: Icons.person_outline,
            iconColor: AppColors.primary,
            title: 'Đã gán tài xế',
            subtitle: order.assignedAt != null
                ? 'Tài xế đã được gán lúc ${formatTime(order.assignedAt)}'
                : 'Đang tìm tài xế',
            isCompleted: isStepCompleted(OrderStatus.assigned),
            isActive: isStepActive(OrderStatus.assigned),
          ),
          // Bước 4: PICKED_UP
          OrderTimelineItem(
            icon: Icons.local_shipping,
            iconColor: AppColors.primary,
            title: 'Đã lấy hàng',
            subtitle: order.pickedUpAt != null
                ? 'Tài xế đã lấy hàng lúc ${formatTime(order.pickedUpAt)}. Đang trên đường giao'
                : 'Đang chuẩn bị hàng',
            isCompleted: isStepCompleted(OrderStatus.pickedUp),
            isActive: isStepActive(OrderStatus.pickedUp),
          ),
          // Bước 5: COMPLETED
          OrderTimelineItem(
            icon: Icons.home,
            iconColor: AppColors.success,
            title: 'Hoàn thành',
            subtitle: order.completedAt != null
                ? 'Đơn hàng đã hoàn thành lúc ${formatTime(order.completedAt)}. Cảm ơn bạn đã mua hàng!'
                : 'Chưa hoàn thành',
            isCompleted: isStepCompleted(OrderStatus.completed),
            isActive: isStepActive(OrderStatus.completed),
            isLast: true,
          ),
          if (order.status == OrderStatus.canceled) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.cancel_outlined,
                    color: AppColors.danger,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đơn hàng đã bị hủy',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.danger,
                          ),
                        ),
                        if (order.cancelReason != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Lý do: ${order.cancelReason}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.danger,
                            ),
                          ),
                        ],
                        if (order.canceledAt != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Thời gian: ${formatTime(order.canceledAt)}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemsSummary(List<OrderItemModel> items) {
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
          Text('Chi tiết món ăn', style: AppTextStyles.heading18),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text('${item.quantity}x', style: AppTextStyles.label14),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(item.productName, style: AppTextStyles.body13),
                  ),
                  Text(
                    _formatPrice(item.subtotal),
                    style: AppTextStyles.label14,
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tổng tiền món', style: AppTextStyles.body13Secondary),
              Text(
                _formatPrice(items.fold(0, (sum, item) => sum + item.subtotal)),
                style: AppTextStyles.label14,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStoreInfo(OrderModel order) {
    if (order.shopId == null) return const SizedBox.shrink();

    final merchantAsync = ref.watch(merchantDetailProvider(order.shopId!));

    return merchantAsync.when(
      data: (shop) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.large),
          boxShadow: AppShadows.soft(0.04),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Thông tin cửa hàng', style: AppTextStyles.heading18),
            const SizedBox(height: 12),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 48,
                    height: 48,
                    color: Colors.grey[200],
                    child: const Icon(Icons.store, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(shop.name, style: AppTextStyles.label14),
                      Text(
                        shop.address ?? 'Không có địa chỉ',
                        style: AppTextStyles.body11,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {}, // TODO: Call store
                  icon: const Icon(
                    Icons.phone_outlined,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildDeliveryInfo(OrderModel order) {
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
          Text('Thông tin giao hàng', style: AppTextStyles.heading18),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.person_outline,
                size: 20,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text('Tài xế: ', style: AppTextStyles.body13Secondary),
              Text(
                order.driverId != null
                    ? 'Đang gán tài xế...'
                    : 'Chưa có tài xế',
                style: AppTextStyles.label14,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.delivery_dining_outlined,
                size: 20,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text('Phí giao hàng: ', style: AppTextStyles.body13Secondary),
              Text(
                _formatPrice(order.deliveryFee),
                style: AppTextStyles.label14,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(OrderModel order) {
    final canCancel = order.canCancel;
    final isCompleted = order.status == OrderStatus.completed;

    return Column(
      children: [
        if (isCompleted) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showReviewDialog(order),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
              ),
              child: Text(
                'Đánh giá ngay',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            if (canCancel)
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _cancelOrder(order.id),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.danger),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                    ),
                  ),
                  child: Text(
                    'Hủy đơn hàng',
                    style: GoogleFonts.inter(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            if (canCancel) const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {}, // TODO: Support chat
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                  ),
                ),
                child: Text(
                  'Hỗ trợ',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showReviewDialog(OrderModel order) {
    if (order.shopId == null) return;

    int selectedRating = 5;
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Đánh giá đơn hàng', style: AppTextStyles.heading18),
              const SizedBox(height: 8),
              Text(
                'Chia sẻ trải nghiệm của bạn về món ăn và dịch vụ',
                style: AppTextStyles.body13Secondary,
              ),
              const SizedBox(height: 24),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (index) {
                    final ratingValue = index + 1;
                    return IconButton(
                      onPressed: () =>
                          setModalState(() => selectedRating = ratingValue),
                      icon: Icon(
                        selectedRating >= ratingValue
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 40,
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Nhập nhận xét của bạn...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      await ref
                          .read(reviewRepositoryProvider)
                          .submitReview(
                            shopId: order.shopId!,
                            rating: selectedRating,
                            comment: commentController.text,
                            orderId: order.id,
                          );
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cảm ơn bạn đã đánh giá!'),
                        ),
                      );
                      // Refresh reviews if needed
                      ref.invalidate(shopReviewsProvider(order.shopId!));
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Lỗi: $e'),
                          backgroundColor: AppColors.danger,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                    ),
                  ),
                  child: Text(
                    'Gửi đánh giá',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _cancelOrder(String orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận hủy'),
        content: const Text('Bạn có chắc chắn muốn hủy đơn hàng này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Hủy đơn',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref
            .read(orderRepositoryProvider)
            .cancelOrderByCustomer(orderId, reason: 'Khách hàng hủy từ app');
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã hủy đơn hàng')));
        ref.invalidate(myOrdersProvider);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Widget _buildTrackingMap(OrderModel order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Theo dõi đơn hàng', style: AppTextStyles.heading18),
        const SizedBox(height: 12),
        OrderTrackingMapWidget(order: order),
      ],
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
        return const Color(0xFFF59E0B);
      default:
        return AppColors.primary;
    }
  }

  String _formatPrice(int price) {
    return '${price.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}đ';
  }
}
