import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design system chung cho app Chợ Quê.

class AppColors {
  AppColors._();

  static const primary = Color(0xFF1E7F43);
  static const backgroundLight = Color(0xFFF8FAFC);
  static const surface = Colors.white;

  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFF94A3B8);

  static const borderSoft = Color(0xFFE2E8F0);

  static const success = Color(0xFF16A34A);
  static const danger = Color(0xFFDC2626);
}

class AppRadius {
  AppRadius._();

  static const small = 12.0;
  static const medium = 16.0;
  static const large = 24.0;
  static const pill = 999.0;
}

class AppShadows {
  AppShadows._();

  static List<BoxShadow> soft([double opacity = 0.05]) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: opacity),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
}

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get heading20 => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get heading18 => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get label14 => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get body13Secondary => GoogleFonts.inter(
        fontSize: 13,
        color: AppColors.textSecondary,
      );
}

/// Header đơn giản với nút back + title, dùng lại cho nhiều màn.
class AppSimpleHeader extends StatelessWidget {
  const AppSimpleHeader({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

