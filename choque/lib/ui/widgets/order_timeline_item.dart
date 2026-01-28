import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../design_system.dart';

/// Reusable order timeline item widget
class OrderTimelineItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isCompleted;
  final bool isActive;
  final bool isLast;

  const OrderTimelineItem({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    this.isActive = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isActive
                    ? iconColor.withValues(alpha: 0.2)
                    : (isCompleted
                          ? iconColor
                          : AppColors.textMuted.withValues(alpha: 0.1)),
                shape: BoxShape.circle,
                border: isActive
                    ? Border.all(color: iconColor, width: 2)
                    : null,
              ),
              child: Icon(
                icon,
                size: 20,
                color: isActive || isCompleted
                    ? iconColor
                    : AppColors.textMuted,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted
                    ? iconColor.withValues(alpha: 0.3)
                    : AppColors.textMuted.withValues(alpha: 0.2),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                    color: isActive || isCompleted
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
