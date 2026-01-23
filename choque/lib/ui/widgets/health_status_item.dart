import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../design_system.dart';

/// Reusable health status item widget
class HealthStatusItem extends StatelessWidget {
  final String label;
  final String status;
  final bool isHealthy;
  final VoidCallback? onTap;

  const HealthStatusItem({
    super.key,
    required this.label,
    required this.status,
    required this.isHealthy,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isHealthy ? AppColors.success : AppColors.danger,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Text(
            status,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isHealthy ? AppColors.success : AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}
