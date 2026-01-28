import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../design_system.dart';

class AppSearchBar extends StatelessWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;

  const AppSearchBar({super.key, required this.hintText, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.soft(0.08),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(Icons.search, color: AppColors.textMuted, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: GoogleFonts.inter(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
                border: InputBorder.none,
              ),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(width: 1, height: 20, color: AppColors.borderSoft),
          const SizedBox(width: 12),
          const Icon(Icons.filter_list, color: AppColors.primary, size: 20),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}
