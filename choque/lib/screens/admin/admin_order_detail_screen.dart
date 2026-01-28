import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../providers/app_providers.dart';
import '../../providers/driver_admin_provider.dart';
import '../../data/models/order_model.dart';
import '../../data/models/profile_model.dart';
import '../../ui/design_system.dart';

/// Admin Order Detail Screen
///
/// Hiển thị chi tiết đơn hàng cho admin với timeline và action buttons.
class AdminOrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;

  const AdminOrderDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends ConsumerState<AdminOrderDetailScreen> {
  bool _isLoading = false;

  String _formatCurrency(int amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount)}đ';
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '--';
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pendingConfirmation:
        return AppColors.warning;
      case OrderStatus.confirmed:
      case OrderStatus.readyForPickup:
        return AppColors.primary;
      case OrderStatus.assigned:
        return const Color(0xFF8B5CF6);
      case OrderStatus.pickedUp:
        return AppColors.primary;
      case OrderStatus.completed:
        return AppColors.success;
      case OrderStatus.canceled:
        return AppColors.danger;
    }
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pendingConfirmation:
        return 'Chờ xác nhận';
      case OrderStatus.confirmed:
        return 'Đã xác nhận';
      case OrderStatus.readyForPickup:
        return 'Sẵn sàng lấy hàng';
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

  IconData _getServiceIcon(ServiceType type) {
    switch (type) {
      case ServiceType.food:
        return Icons.restaurant_outlined;
      case ServiceType.ride:
        return Icons.two_wheeler_outlined;
      case ServiceType.delivery:
        return Icons.local_shipping_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderStreamProvider(widget.orderId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Chi tiết đơn hàng',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: orderAsync.when(
        data: (order) => _buildContent(order),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorState(error.toString()),
      ),
    );
  }

  Widget _buildContent(OrderModel order) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              _buildHeaderCard(order),

              // Customer Info
              _buildSectionCard(
                title: 'Thông tin khách hàng',
                icon: Icons.person_outline,
                child: _buildCustomerInfo(order),
              ),

              // Location Info
              _buildSectionCard(
                title: 'Địa điểm',
                icon: Icons.location_on_outlined,
                child: _buildLocationInfo(order),
              ),

              // Pricing
              _buildSectionCard(
                title: 'Chi phí',
                icon: Icons.receipt_long_outlined,
                child: _buildPricing(order),
              ),

              // Timeline
              _buildSectionCard(
                title: 'Lịch sử đơn hàng',
                icon: Icons.timeline_outlined,
                child: _buildTimeline(order),
              ),

              // Cancel reason (if canceled)
              if (order.status == OrderStatus.canceled &&
                  order.cancelReason != null)
                _buildSectionCard(
                  title: 'Lý do hủy',
                  icon: Icons.cancel_outlined,
                  child: Text(
                    order.cancelReason!,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.danger,
                    ),
                  ),
                ),

              // Note (if any)
              if (order.note != null && order.note!.isNotEmpty)
                _buildSectionCard(
                  title: 'Ghi chú',
                  icon: Icons.note_outlined,
                  child: Text(
                    order.note!,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Bottom Action Panel
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildActionPanel(order),
        ),
      ],
    );
  }

  Widget _buildHeaderCard(OrderModel order) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        boxShadow: AppShadows.soft(0.06),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getServiceIcon(order.serviceType),
                      size: 24,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đơn #${order.orderNumber}',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.serviceType.name.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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

          if (order.shopName != null && order.shopName!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.store_outlined, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.shopName!,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatCurrency(order.totalAmount),
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildCustomerInfo(OrderModel order) {
    return Column(
      children: [
        _buildInfoRow(
          label: 'Tên khách',
          value: order.customerName ?? 'Không có',
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildInfoRow(
                label: 'Số điện thoại',
                value: order.customerPhone ?? 'Không có',
              ),
            ),
            if (order.customerPhone != null && order.customerPhone!.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.phone, color: AppColors.primary, size: 20),
                onPressed: () => _makePhoneCall(order.customerPhone!),
                tooltip: 'Gọi điện',
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationInfo(OrderModel order) {
    return Column(
      children: [
        _buildLocationRow(
          icon: Icons.radio_button_checked,
          iconColor: AppColors.success,
          label: 'Lấy hàng',
          address: order.pickup.address ?? order.pickup.label,
        ),
        const Padding(
          padding: EdgeInsets.only(left: 7),
          child: DottedLine(height: 20),
        ),
        _buildLocationRow(
          icon: Icons.location_on,
          iconColor: AppColors.danger,
          label: 'Giao hàng',
          address: order.dropoff.address ?? order.dropoff.label,
        ),
      ],
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String address,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPricing(OrderModel order) {
    return Column(
      children: [
        _buildPriceRow('Tiền hàng', order.itemsTotal),
        const SizedBox(height: 6),
        _buildPriceRow('Phí giao hàng', order.deliveryFee),
        if (order.discountAmount > 0) ...[
          const SizedBox(height: 6),
          _buildPriceRow('Giảm giá', -order.discountAmount, isDiscount: true),
        ],
        const Divider(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tổng cộng',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              _formatCurrency(order.totalAmount),
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, int amount, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          isDiscount ? '-${_formatCurrency(-amount)}' : _formatCurrency(amount),
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDiscount ? AppColors.success : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeline(OrderModel order) {
    final events = <_TimelineEvent>[
      _TimelineEvent(
        title: 'Đơn hàng được tạo',
        time: order.createdAt,
        isCompleted: true,
      ),
      if (order.confirmedAt != null)
        _TimelineEvent(
          title: 'Đã xác nhận',
          time: order.confirmedAt!,
          isCompleted: true,
        ),
      if (order.assignedAt != null)
        _TimelineEvent(
          title: 'Đã gán tài xế',
          time: order.assignedAt!,
          isCompleted: true,
        ),
      if (order.pickedUpAt != null)
        _TimelineEvent(
          title: 'Đã lấy hàng',
          time: order.pickedUpAt!,
          isCompleted: true,
        ),
      if (order.completedAt != null)
        _TimelineEvent(
          title: 'Hoàn thành',
          time: order.completedAt!,
          isCompleted: true,
        ),
      if (order.canceledAt != null)
        _TimelineEvent(
          title: 'Đã hủy',
          time: order.canceledAt!,
          isCompleted: true,
          isCanceled: true,
        ),
    ];

    return Column(
      children: events.asMap().entries.map((entry) {
        final index = entry.key;
        final event = entry.value;
        final isLast = index == events.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: event.isCanceled
                        ? AppColors.danger
                        : event.isCompleted
                            ? AppColors.success
                            : AppColors.border,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 30,
                    color: AppColors.border,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      event.title,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: event.isCanceled
                            ? AppColors.danger
                            : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _formatDateTime(event.time),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildActionPanel(OrderModel order) {
    // Don't show actions for completed or canceled orders
    if (order.status == OrderStatus.completed ||
        order.status == OrderStatus.canceled) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Cancel button (always show except completed/canceled)
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.danger),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                  ),
                ),
                onPressed: _isLoading ? null : () => _showCancelDialog(order),
                child: Text(
                  'Hủy đơn',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.danger,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Primary action button
            Expanded(
              flex: 2,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                  ),
                ),
                onPressed: _isLoading ? null : () => _handlePrimaryAction(order),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(
                        _getPrimaryActionText(order),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPrimaryActionText(OrderModel order) {
    switch (order.status) {
      case OrderStatus.pendingConfirmation:
        return 'Xác nhận đơn';
      case OrderStatus.confirmed:
      case OrderStatus.readyForPickup:
        return 'Gán tài xế';
      case OrderStatus.assigned:
      case OrderStatus.pickedUp:
        return 'Gán lại tài xế';
      default:
        return 'Xử lý';
    }
  }

  void _handlePrimaryAction(OrderModel order) {
    switch (order.status) {
      case OrderStatus.pendingConfirmation:
        _confirmOrder(order);
        break;
      case OrderStatus.confirmed:
      case OrderStatus.readyForPickup:
        _showAssignDriverDialog(order);
        break;
      case OrderStatus.assigned:
      case OrderStatus.pickedUp:
        _showReassignDriverDialog(order);
        break;
      default:
        break;
    }
  }

  Future<void> _confirmOrder(OrderModel order) async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(orderRepositoryProvider);
      await repo.confirmOrder(order.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xác nhận đơn #${order.orderNumber}'),
            backgroundColor: AppColors.success,
          ),
        );
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCancelDialog(OrderModel order) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Hủy đơn #${order.orderNumber}',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bạn có chắc muốn hủy đơn hàng này?',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Lý do hủy *',
                hintText: 'Nhập lý do hủy đơn',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Quay lại', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập lý do hủy')),
                );
                return;
              }

              Navigator.pop(context);
              await _cancelOrder(order, reasonController.text.trim());
            },
            child: Text('Hủy đơn', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelOrder(OrderModel order, String reason) async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(orderRepositoryProvider);
      await repo.cancelOrderByAdmin(order.id, reason);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã hủy đơn #${order.orderNumber}'),
            backgroundColor: AppColors.warning,
          ),
        );
        context.pop();
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAssignDriverDialog(OrderModel order) {
    final driversAsync = ref.read(onlineDriversProvider);

    driversAsync.when(
      data: (drivers) {
        if (drivers.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không có tài xế online'),
              backgroundColor: AppColors.warning,
            ),
          );
          return;
        }

        _showDriverPickerDialog(
          order: order,
          drivers: drivers,
          title: 'Gán tài xế',
          actionText: 'Gán',
          onConfirm: (driver) => _assignDriver(order, driver),
        );
      },
      loading: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đang tải danh sách tài xế...')),
        );
      },
      error: (e, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      },
    );
  }

  void _showReassignDriverDialog(OrderModel order) {
    final driversAsync = ref.read(onlineDriversProvider);

    driversAsync.when(
      data: (drivers) {
        final availableDrivers = drivers
            .where((d) => d.userId != order.driverId)
            .toList();

        if (availableDrivers.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không có tài xế khác đang online'),
              backgroundColor: AppColors.warning,
            ),
          );
          return;
        }

        _showDriverPickerDialog(
          order: order,
          drivers: availableDrivers,
          title: 'Gán lại tài xế',
          actionText: 'Gán lại',
          showReasonField: true,
          onConfirmWithReason: (driver, reason) =>
              _reassignDriver(order, driver, reason),
        );
      },
      loading: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đang tải danh sách tài xế...')),
        );
      },
      error: (e, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      },
    );
  }

  void _showDriverPickerDialog({
    required OrderModel order,
    required List<ProfileModel> drivers,
    required String title,
    required String actionText,
    bool showReasonField = false,
    Function(ProfileModel)? onConfirm,
    Function(ProfileModel, String)? onConfirmWithReason,
  }) {
    ProfileModel? selectedDriver;
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            '$title cho đơn #${order.orderNumber}',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chọn tài xế:',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: drivers.length,
                  itemBuilder: (context, index) {
                    final driver = drivers[index];
                    final isSelected = selectedDriver?.userId == driver.userId;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: isSelected
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.1),
                        child: Icon(
                          Icons.person,
                          color: isSelected ? Colors.white : AppColors.primary,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        driver.fullName ?? 'Tài xế',
                        style: GoogleFonts.inter(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        driver.phone ?? '',
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: AppColors.primary)
                          : null,
                      onTap: () => setState(() => selectedDriver = driver),
                    );
                  },
                ),
              ),
              if (showReasonField) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: InputDecoration(
                    labelText: 'Lý do gán lại',
                    hintText: 'Nhập lý do...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 2,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy', style: GoogleFonts.inter()),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: selectedDriver == null
                  ? null
                  : () {
                      Navigator.pop(context);
                      if (showReasonField && onConfirmWithReason != null) {
                        onConfirmWithReason(
                          selectedDriver!,
                          reasonController.text.trim(),
                        );
                      } else if (onConfirm != null) {
                        onConfirm(selectedDriver!);
                      }
                    },
              child: Text(
                actionText,
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _assignDriver(OrderModel order, ProfileModel driver) async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(orderRepositoryProvider);
      await repo.assignDriver(order.id, driver.userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã gán ${driver.fullName ?? "tài xế"} cho đơn #${order.orderNumber}'),
            backgroundColor: AppColors.success,
          ),
        );
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _reassignDriver(
    OrderModel order,
    ProfileModel newDriver,
    String reason,
  ) async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(orderRepositoryProvider);
      await repo.reassignDriver(
        order.id,
        newDriver.userId,
        reason.isNotEmpty ? reason : 'Admin reassigned',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã gán lại ${newDriver.fullName ?? "tài xế"} cho đơn #${order.orderNumber}'),
            backgroundColor: AppColors.success,
          ),
        );
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildInfoRow({required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
            const SizedBox(height: 16),
            Text(
              'Đã xảy ra lỗi',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }
}

class _TimelineEvent {
  final String title;
  final DateTime time;
  final bool isCompleted;
  final bool isCanceled;

  _TimelineEvent({
    required this.title,
    required this.time,
    this.isCompleted = false,
    this.isCanceled = false,
  });
}

/// Dotted line widget for timeline
class DottedLine extends StatelessWidget {
  final double height;

  const DottedLine({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          (height / 4).floor(),
          (index) => Container(
            width: 2,
            height: 2,
            decoration: const BoxDecoration(
              color: AppColors.border,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
