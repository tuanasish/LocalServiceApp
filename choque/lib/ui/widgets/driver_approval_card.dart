import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../design_system.dart';
import '../../data/models/profile_model.dart';
import 'driver_status_badge.dart';

/// Driver Approval Card
///
/// Card hiển thị thông tin driver đang chờ duyệt với các nút approve/reject.
class DriverApprovalCard extends StatelessWidget {
  final ProfileModel driver;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onTap;

  const DriverApprovalCard({
    super.key,
    required this.driver,
    this.onApprove,
    this.onReject,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Avatar + Info + Status
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      _getInitials(driver.fullName ?? 'Driver'),
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Name + Phone
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driver.fullName ?? 'Chưa có tên',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          driver.phone ?? 'Chưa có SĐT',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status Badge
                  if (driver.driverApprovalStatus != null)
                    DriverStatusBadge(
                      status: driver.driverApprovalStatus!,
                      compact: true,
                    ),
                ],
              ),

              // Vehicle Info (if available)
              if (driver.driverVehicleInfo != null &&
                  driver.driverVehicleInfo!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(AppRadius.small),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.motorcycle,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Phương tiện',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              _getVehicleInfo(driver.driverVehicleInfo!),
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
                  ),
                ),
              ],

              // License Info (if available)
              if (driver.driverLicenseInfo != null &&
                  driver.driverLicenseInfo!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(AppRadius.small),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.badge,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Giấy phép lái xe',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              _getLicenseInfo(driver.driverLicenseInfo!),
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
                  ),
                ),
              ],

              // Action Buttons (only for pending drivers)
              if (driver.isDriverPending) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Từ chối'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: BorderSide(color: AppColors.danger),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppRadius.small,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onApprove,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Duyệt'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppRadius.small,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // Rejection Reason (if rejected)
              if (driver.isDriverRejected &&
                  driver.driverRejectionReason != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.small),
                    border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: AppColors.danger,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lý do từ chối',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.danger,
                              ),
                            ),
                            const SizedBox(height: 2),
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
                  ),
                ),
              ],
            ],
          ),
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

  String _getVehicleInfo(Map<String, dynamic> vehicleInfo) {
    final type = vehicleInfo['type'] ?? 'Xe máy';
    final plateNumber = vehicleInfo['plate_number'];
    if (plateNumber != null) {
      return '$type - $plateNumber';
    }
    return type;
  }

  String _getLicenseInfo(Map<String, dynamic> licenseInfo) {
    final number = licenseInfo['number'];
    final licenseClass = licenseInfo['class'] ?? 'A1';
    if (number != null) {
      return '$licenseClass - $number';
    }
    return licenseClass;
  }
}
