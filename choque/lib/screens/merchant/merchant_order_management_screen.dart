import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../ui/design_system.dart';
import '../../providers/app_providers.dart';
import '../../data/models/order_model.dart';
import '../../data/models/order_item_model.dart';

/// Merchant Order Management Screen
/// Màn quản lý đơn hàng chi tiết: xem, cập nhật trạng thái, chi tiết đơn hàng.
class MerchantOrderManagementScreen extends ConsumerWidget {
  final String orderId;

  const MerchantOrderManagementScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));

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
                    ref.invalidate(orderDetailProvider(orderId));
                    ref.invalidate(orderItemsProvider(orderId));
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          _buildOrderDetailCard(order),
                          const SizedBox(height: 20),
                          _buildCustomerInfo(context, order),
                          const SizedBox(height: 20),
                          _buildOrderItems(orderId),
                          const SizedBox(height: 20),
                          _buildStatusInfo(order),
                          const SizedBox(height: 30),
                          _buildActionButtons(context, ref, order),
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
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.danger,
                        ),
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
                            ref.invalidate(orderDetailProvider(orderId));
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
    );
  }

  Widget _buildOrderDetailCard(OrderModel order) {
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
                  fontSize: 18,
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
                'Đặt lúc: ${DateFormat('HH:mm • dd/MM/yyyy').format(order.createdAt)}',
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
          if (order.note != null && order.note!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.note_outlined,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ghi chú: ${order.note}',
                    style: AppTextStyles.body13Secondary,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng đơn hàng',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                _formatPrice(order.totalAmount),
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo(BuildContext context, OrderModel order) {
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
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text('Thông tin khách hàng', style: AppTextStyles.label14),
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
            Row(
              children: [
                const Icon(
                  Icons.phone_outlined,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  order.customerPhone!,
                  style: AppTextStyles.body13Secondary,
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  order.dropoff.address ?? order.dropoff.label,
                  style: AppTextStyles.body13Secondary,
                ),
              ),
            ],
          ),
          if (order.customerPhone != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                onPressed: () => _makePhoneCall(context, order.customerPhone!),
                icon: const Icon(
                  Icons.phone_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
                label: Text(
                  'Gọi khách',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
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

            final subtotal = items.fold<int>(
              0,
              (sum, item) => sum + item.subtotal,
            );

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
                  Text('Chi tiết đơn hàng', style: AppTextStyles.heading18),
                  const SizedBox(height: 16),
                  ...items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildOrderItemRow(item),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tạm tính',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        _formatPrice(subtotal),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
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
          error: (_, __) => const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildOrderItemRow(OrderItemModel item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (item.note != null && item.note!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Ghi chú: ${item.note}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'x${item.quantity}',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _formatPrice(item.subtotal),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusInfo(OrderModel order) {
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
          Text('Thông tin trạng thái', style: AppTextStyles.heading18),
          const SizedBox(height: 16),
          _buildStatusInfoRow(
            icon: Icons.info_outline,
            label: 'Trạng thái hiện tại',
            value: _getStatusText(order.status),
            valueColor: _getStatusColor(order.status),
          ),
          if (order.confirmedAt != null) ...[
            const SizedBox(height: 12),
            _buildStatusInfoRow(
              icon: Icons.check_circle_outline,
              label: 'Đã xác nhận lúc',
              value: DateFormat(
                'HH:mm • dd/MM/yyyy',
              ).format(order.confirmedAt!),
            ),
          ],
          if (order.assignedAt != null) ...[
            const SizedBox(height: 12),
            _buildStatusInfoRow(
              icon: Icons.local_shipping_outlined,
              label: 'Đã gán tài xế lúc',
              value: DateFormat('HH:mm • dd/MM/yyyy').format(order.assignedAt!),
            ),
          ],
          if (order.pickedUpAt != null) ...[
            const SizedBox(height: 12),
            _buildStatusInfoRow(
              icon: Icons.inventory_2_outlined,
              label: 'Đã lấy hàng lúc',
              value: DateFormat('HH:mm • dd/MM/yyyy').format(order.pickedUpAt!),
            ),
          ],
          if (order.completedAt != null) ...[
            const SizedBox(height: 12),
            _buildStatusInfoRow(
              icon: Icons.check_circle,
              label: 'Hoàn thành lúc',
              value: DateFormat(
                'HH:mm • dd/MM/yyyy',
              ).format(order.completedAt!),
            ),
          ],
          const SizedBox(height: 16),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    OrderModel order,
  ) {
    if (order.status == OrderStatus.completed ||
        order.status == OrderStatus.canceled) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (order.status == OrderStatus.pendingConfirmation) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              onPressed: () => _handleConfirm(context, ref, order),
              child: Text(
                'Xác nhận đơn hàng',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppColors.danger),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              onPressed: () => _handleReject(context, ref, order),
              child: Text(
                'Từ chối đơn hàng',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.danger,
                ),
              ),
            ),
          ),
        ],
        if (order.status == OrderStatus.confirmed) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              onPressed: () => _handleMarkReady(context, ref, order),
              child: Text(
                'Báo sẵn sàng (Giao cho tài xế)',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
        if (order.status == OrderStatus.readyForPickup) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.success),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Đã báo sẵn sàng. Đang chờ Admin gán tài xế.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _handleConfirm(
    BuildContext context,
    WidgetRef ref,
    OrderModel order,
  ) async {
    try {
      await ref.read(merchantRepositoryProvider).confirmOrder(order.id);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã xác nhận đơn hàng')));
        ref.invalidate(orderDetailProvider(order.id));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _handleReject(
    BuildContext context,
    WidgetRef ref,
    OrderModel order,
  ) async {
    final reasonController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Từ chối đơn hàng'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(hintText: 'Nhập lý do từ chối...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Xác nhận',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      try {
        await ref
            .read(merchantRepositoryProvider)
            .rejectOrder(
              order.id,
              reasonController.text.isEmpty
                  ? 'Merchant từ chối'
                  : reasonController.text,
            );
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Đã từ chối đơn hàng')));
          ref.invalidate(orderDetailProvider(order.id));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: $e'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleMarkReady(
    BuildContext context,
    WidgetRef ref,
    OrderModel order,
  ) async {
    try {
      await ref.read(merchantRepositoryProvider).markOrderReady(order.id);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã báo sẵn sàng')));
        ref.invalidate(orderDetailProvider(order.id));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Widget _buildStatusInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pendingConfirmation:
        return 'Chờ xác nhận';
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

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pendingConfirmation:
        return AppColors.primary;
      case OrderStatus.confirmed:
        return const Color(0xFFF59E0B);
      case OrderStatus.readyForPickup:
        return AppColors.success;
      case OrderStatus.assigned:
        return const Color(0xFF0EA5E9);
      case OrderStatus.pickedUp:
        return const Color(0xFF8B5CF6);
      case OrderStatus.completed:
        return AppColors.success;
      case OrderStatus.canceled:
        return AppColors.danger;
    }
  }

  String _formatPrice(int price) {
    final formatted = price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '$formattedđ';
  }

  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    // TODO: Implement phone call using url_launcher or similar package
    // For now, just show a message
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gọi số: $phoneNumber'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
