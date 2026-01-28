import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../design_system.dart';

/// Order card cho màn hình driver home với hình ảnh cửa hàng
class DriverRecentOrderCard extends StatelessWidget {
  final String storeName;
  final String? storeImageUrl;
  final String distance;
  final String fee;
  final bool isExpired;
  final VoidCallback? onViewDetails;
  final VoidCallback? onAccept;

  const DriverRecentOrderCard({
    super.key,
    required this.storeName,
    this.storeImageUrl,
    required this.distance,
    required this.fee,
    this.isExpired = false,
    this.onViewDetails,
    this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isExpired ? 0.8 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.large),
          border: Border.all(
            color: AppColors.borderSoft,
            width: 1,
          ),
          boxShadow: AppShadows.soft(0.04),
        ),
        child: Column(
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
                        storeName,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.near_me,
                                size: 16,
                                color: AppColors.driverTextSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                distance,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.driverTextSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Row(
                            children: [
                              const Icon(
                                Icons.account_balance_wallet,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                fee,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Store image
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                    color: AppColors.borderSoft,
                  ),
                  child: storeImageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.medium),
                          child: Image.network(
                            storeImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildPlaceholderImage(),
                          ),
                        )
                      : _buildPlaceholderImage(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isExpired ? null : onViewDetails,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: BorderSide(
                        color: isExpired
                            ? AppColors.borderSoft
                            : AppColors.primary.withValues(alpha: 0.3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                      ),
                    ),
                    child: Text(
                      'Chi tiết',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isExpired
                            ? AppColors.textSecondary
                            : AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: isExpired ? null : onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isExpired
                          ? AppColors.borderSoft
                          : AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                      ),
                    ),
                    child: Text(
                      isExpired ? 'Hết hạn' : 'Nhận đơn ngay',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isExpired
                            ? AppColors.textSecondary
                            : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: AppColors.borderSoft,
      child: const Icon(
        Icons.store,
        color: AppColors.textSecondary,
        size: 32,
      ),
    );
  }
}
