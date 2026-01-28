import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../design_system.dart';
import '../../data/models/order_model.dart';

/// Admin Order Card Widget
///
/// Hiển thị thông tin đơn hàng cho admin với các action buttons.
class AdminOrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onTap;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final VoidCallback? onAssignDriver;
  final VoidCallback? onReassignDriver;

  const AdminOrderCard({
    super.key,
    required this.order,
    this.onTap,
    this.onConfirm,
    this.onCancel,
    this.onAssignDriver,
    this.onReassignDriver,
  });

  Color get _statusColor {
    switch (order.status) {
      case OrderStatus.pendingConfirmation:
        return AppColors.warning;
      case OrderStatus.confirmed:
      case OrderStatus.readyForPickup:
        return AppColors.primary;
      case OrderStatus.assigned:
        return const Color(0xFF8B5CF6); // Purple
      case OrderStatus.pickedUp:
        return AppColors.primary;
      case OrderStatus.completed:
        return AppColors.success;
      case OrderStatus.canceled:
        return AppColors.danger;
    }
  }

  String get _statusText {
    switch (order.status) {
      case OrderStatus.pendingConfirmation:
        return 'Chờ xác nhận';
      case OrderStatus.confirmed:
        return 'Đã xác nhận';
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

  IconData get _serviceIcon {
    switch (order.serviceType) {
      case ServiceType.food:
        return Icons.restaurant_outlined;
      case ServiceType.ride:
        return Icons.two_wheeler_outlined;
      case ServiceType.delivery:
        return Icons.local_shipping_outlined;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return DateFormat('dd/MM HH:mm').format(dateTime);
  }

  String _formatCurrency(int amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount)}đ';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.large),
          boxShadow: AppShadows.soft(0.04),
          border: order.status == OrderStatus.pendingConfirmation
              ? Border.all(color: AppColors.warning.withValues(alpha: 0.5), width: 1.5)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Order ID + Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _serviceIcon,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '#${order.orderNumber}',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    _statusText,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _statusColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Shop name (if food order)
            if (order.shopName != null && order.shopName!.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.store_outlined, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      order.shopName!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Customer info
            Row(
              children: [
                const Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order.customerName ?? 'Khách hàng',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.access_time_outlined, size: 12, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  _formatTime(order.createdAt),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),

            // Phone (tap to call)
            if (order.customerPhone != null && order.customerPhone!.isNotEmpty) ...[
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => _makePhoneCall(order.customerPhone!),
                child: Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      order.customerPhone!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 10),

            // Locations
            _buildLocationRow(
              icon: Icons.radio_button_checked,
              iconColor: AppColors.success,
              text: order.pickup.address ?? order.pickup.label,
            ),
            const SizedBox(height: 4),
            _buildLocationRow(
              icon: Icons.location_on,
              iconColor: AppColors.danger,
              text: order.dropoff.address ?? order.dropoff.label,
            ),

            const SizedBox(height: 12),

            // Footer: Total + Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatCurrency(order.totalAmount),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                _buildActionButtons(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color iconColor,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    switch (order.status) {
      case OrderStatus.pendingConfirmation:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionButton(
              label: 'Hủy',
              color: AppColors.danger,
              isOutlined: true,
              onPressed: onCancel,
            ),
            const SizedBox(width: 8),
            _buildActionButton(
              label: 'Xác nhận',
              color: AppColors.primary,
              onPressed: onConfirm,
            ),
          ],
        );
      case OrderStatus.confirmed:
      case OrderStatus.readyForPickup:
        return _buildActionButton(
          label: 'Gán tài xế',
          color: AppColors.primary,
          onPressed: onAssignDriver,
        );
      case OrderStatus.assigned:
      case OrderStatus.pickedUp:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionButton(
              label: 'Gán lại',
              color: const Color(0xFF8B5CF6),
              isOutlined: true,
              onPressed: onReassignDriver,
            ),
            const SizedBox(width: 8),
            _buildActionButton(
              label: 'Hủy',
              color: AppColors.danger,
              isOutlined: true,
              onPressed: onCancel,
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    bool isOutlined = false,
    VoidCallback? onPressed,
  }) {
    if (isOutlined) {
      return OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          side: BorderSide(color: color),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      );
    }

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
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
