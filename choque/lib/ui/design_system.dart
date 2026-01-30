import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design system chung cho app Chợ Quê.
/// Trên iOS dùng font fallback (SF Pro) khi Inter chưa load.

class AppColors {
  AppColors._();

  static const primary = Color(0xFF1E7F43);
  static const backgroundLight = Color(0xFFF8FAFC);
  static const background = backgroundLight;
  static const surface = Colors.white;

  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFF94A3B8);

  static const borderSoft = Color(0xFFE2E8F0);
  static const border = borderSoft;

  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFDC2626);
  static const error = danger;
  
  // Accent colors
  static const accentYellow = Color(0xFFF2C94C);
  
  // Driver specific colors
  static const driverBackgroundLight = Color(0xFFF6F8F7);
  static const driverBackgroundDark = Color(0xFF131F18);
  static const driverSurfaceDark = Color(0xFF1A2621);
  static const driverTextSecondary = Color(0xFF678379);
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

  static const List<String> _iosFontFallback = [
    'SF Pro Display',
    'SF Pro Text',
    '.SF UI Text',
  ];

  static TextStyle _withFallback(TextStyle style) {
    if (Platform.isIOS) {
      return style.copyWith(fontFamilyFallback: _iosFontFallback);
    }
    return style;
  }

  static TextStyle get heading20 => _withFallback(GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  ));

  static TextStyle get heading18 => _withFallback(GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  ));

  static TextStyle get label14 => _withFallback(GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  ));

  static TextStyle get body13Secondary =>
      _withFallback(GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary));

  static TextStyle get body15Secondary =>
      _withFallback(GoogleFonts.inter(fontSize: 15, color: AppColors.textSecondary));

  static TextStyle get body13 =>
      _withFallback(GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary));

  static TextStyle get body12 =>
      _withFallback(GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary));

  static TextStyle get body11 =>
      _withFallback(GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary));

  static TextStyle get label16 => _withFallback(GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  ));
}

/// Header đơn giản với nút back + title, dùng lại cho nhiều màn.
class AppSimpleHeader extends StatelessWidget {
  const AppSimpleHeader({super.key, required this.title, this.actions});

  final String title;
  final List<Widget>? actions;

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
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}
