import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../ui/design_system.dart';

/// Confirm Flag Changes Sheet
/// Bottom sheet xác nhận thay đổi flag/trạng thái: hiển thị thay đổi, xác nhận/hủy.
class ConfirmFlagChangesSheet extends StatelessWidget {
  final String itemName;
  final String currentFlag;
  final String newFlag;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const ConfirmFlagChangesSheet({
    super.key,
    required this.itemName,
    required this.currentFlag,
    required this.newFlag,
    this.onConfirm,
    this.onCancel,
  });

  static void show(
    BuildContext context, {
    required String itemName,
    required String currentFlag,
    required String newFlag,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ConfirmFlagChangesSheet(
        itemName: itemName,
        currentFlag: currentFlag,
        newFlag: newFlag,
        onConfirm: onConfirm,
        onCancel: onCancel ?? () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.large),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildItemInfo(),
              const SizedBox(height: 20),
              _buildChangesPreview(),
              const SizedBox(height: 24),
              _buildActionButtons(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
          child: const Icon(
            Icons.flag_outlined,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Xác nhận thay đổi',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.close,
            color: AppColors.textSecondary,
          ),
          onPressed: onCancel,
        ),
      ],
    );
  }

  Widget _buildItemInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.restaurant_menu_outlined,
            size: 20,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              itemName,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangesPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thay đổi trạng thái',
            style: AppTextStyles.label14,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildFlagBox(
                  label: 'Hiện tại',
                  flag: currentFlag,
                  isCurrent: true,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.arrow_forward,
                size: 20,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFlagBox(
                  label: 'Mới',
                  flag: newFlag,
                  isCurrent: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFlagBox({
    required String label,
    required String flag,
    required bool isCurrent,
  }) {
    Color flagColor;
    if (flag == 'Đang bán' || flag == 'Hoạt động') {
      flagColor = AppColors.success;
    } else if (flag == 'Tạm ngưng' || flag == 'Chờ duyệt') {
      flagColor = const Color(0xFFF59E0B);
    } else {
      flagColor = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(
          color: isCurrent ? AppColors.borderSoft : AppColors.primary.withValues(alpha: 0.3),
          width: isCurrent ? 1 : 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: flagColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              flag,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: flagColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            onPressed: onConfirm,
            icon: const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
            ),
            label: Text(
              'Xác nhận thay đổi',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: AppColors.textSecondary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            onPressed: onCancel,
            child: Text(
              'Hủy',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
