import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../design_system.dart';

/// Reusable checkout address card widget
class CheckoutAddressCard extends StatelessWidget {
  final String name;
  final String phone;
  final String address;
  final VoidCallback? onTap;

  const CheckoutAddressCard({
    super.key,
    required this.name,
    required this.phone,
    required this.address,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
            Text('Giao đến địa chỉ', style: AppTextStyles.heading18),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$name | $phone',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(address, style: AppTextStyles.body13Secondary),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
