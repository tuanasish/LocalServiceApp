import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../ui/design_system.dart';
import '../../providers/driver_admin_provider.dart';
import '../../ui/widgets/driver_status_badge.dart';
import '../../data/models/order_model.dart';

/// Admin Driver Detail Screen
///
/// Màn hình chi tiết tài xế với thông tin, thống kê, và lịch sử đơn hàng.
class AdminDriverDetailScreen extends ConsumerWidget {
  final String driverId;

  const AdminDriverDetailScreen({super.key, required this.driverId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driverAsync = ref.watch(driverDetailProvider(driverId));
    final statsAsync = ref.watch(driverStatsProvider(driverId));
    final ordersAsync = ref.watch(driverOrderHistoryProvider(driverId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Chi tiết Tài xế',
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: driverAsync.when(
        data: (driver) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(driverDetailProvider(driverId));
            ref.invalidate(driverStatsProvider(driverId));
            ref.invalidate(driverOrderHistoryProvider(driverId));
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Card
                _buildProfileCard(context, driver),
                const SizedBox(height: 16),

                // Statistics
                _buildStatisticsSection(statsAsync),
                const SizedBox(height: 16),

                // Order History
                _buildOrderHistorySection(ordersAsync),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.danger),
              const SizedBox(height: 16),
              Text(
                'Lỗi: ${error.toString()}',
                style: GoogleFonts.inter(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, driver) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                _getInitials(driver.fullName ?? 'Driver'),
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Name
            Text(
              driver.fullName ?? 'Chưa có tên',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),

            // Phone
            Text(
              driver.phone ?? 'Chưa có SĐT',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),

            // Status Badges
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (driver.driverApprovalStatus != null)
                  DriverStatusBadge(status: driver.driverApprovalStatus!),
                if (driver.driverStatus != null) ...[
                  const SizedBox(width: 8),
                  DriverStatusBadge(status: driver.driverStatus!),
                ],
              ],
            ),

            // Approval Info
            if (driver.isDriverApproved && driver.driverApprovedAt != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Đã duyệt: ${DateFormat('dd/MM/yyyy HH:mm').format(driver.driverApprovedAt!)}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Rejection Info
            if (driver.isDriverRejected &&
                driver.driverRejectionReason != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.small),
                  border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.cancel, color: AppColors.danger, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Lý do từ chối',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      driver.driverRejectionReason!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Vehicle & License Info
            if (driver.driverVehicleInfo != null ||
                driver.driverLicenseInfo != null) ...[
              const Divider(height: 32),
              _buildInfoRow(
                'Phương tiện',
                _getVehicleInfo(driver.driverVehicleInfo),
                Icons.motorcycle,
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                'Giấy phép',
                _getLicenseInfo(driver.driverLicenseInfo),
                Icons.badge,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 8),
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
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsSection(AsyncValue<Map<String, dynamic>> statsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thống kê',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        statsAsync.when(
          data: (stats) => Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Tổng đơn',
                      stats['total_orders']?.toString() ?? '0',
                      Icons.receipt_long,
                      AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Hoàn thành',
                      stats['completed_orders']?.toString() ?? '0',
                      Icons.check_circle,
                      AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Tỷ lệ hoàn thành',
                      '${stats['completion_rate']?.toString() ?? '0'}%',
                      Icons.trending_up,
                      const Color(0xFF8B5CF6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Thời gian TB',
                      '${stats['avg_delivery_time_minutes']?.toString() ?? '0'} phút',
                      Icons.timer,
                      const Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHistorySection(AsyncValue<List<dynamic>> ordersAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lịch sử đơn hàng',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ordersAsync.when(
          data: (orders) {
            if (orders.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'Chưa có đơn hàng nào',
                      style: GoogleFonts.inter(color: AppColors.textSecondary),
                    ),
                  ),
                ),
              );
            }

            return Column(
              children: orders.take(10).map((order) {
                return _buildOrderCard(order);
              }).toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đơn #${order.id.substring(0, 8)}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            DriverStatusBadge(status: order.status.toDbString(), compact: true),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return 'D';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  String _getVehicleInfo(Map<String, dynamic>? vehicleInfo) {
    if (vehicleInfo == null || vehicleInfo.isEmpty) return 'Chưa cập nhật';
    final type = vehicleInfo['type'] ?? 'Xe máy';
    final plateNumber = vehicleInfo['plate_number'];
    if (plateNumber != null) return '$type - $plateNumber';
    return type;
  }

  String _getLicenseInfo(Map<String, dynamic>? licenseInfo) {
    if (licenseInfo == null || licenseInfo.isEmpty) return 'Chưa cập nhật';
    final number = licenseInfo['number'];
    final licenseClass = licenseInfo['class'] ?? 'A1';
    if (number != null) return '$licenseClass - $number';
    return licenseClass;
  }
}
