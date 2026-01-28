import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../design_system.dart';

class CategoryChip extends StatelessWidget {
  final IconData? icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const CategoryChip({
    super.key,
    this.icon,
    required this.label,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isActive ? const Color(0xFFDCFCE7) : AppColors.surface;
    final borderColor = isActive ? AppColors.success : AppColors.borderSoft;
    final textColor = isActive
        ? const Color(0xFF166534)
        : AppColors.textPrimary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: borderColor),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.15),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: textColor),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
