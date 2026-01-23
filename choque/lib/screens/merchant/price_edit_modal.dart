import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../ui/design_system.dart';

/// Price Edit Modal & States
/// Modal chỉnh sửa giá với các states: normal, editing, saving, success, error.
enum PriceEditState {
  normal,
  editing,
  saving,
  success,
  error,
}

class PriceEditModal extends StatefulWidget {
  final String itemName;
  final String currentPrice;
  final Function(String)? onSave;

  const PriceEditModal({
    super.key,
    required this.itemName,
    required this.currentPrice,
    this.onSave,
  });

  static void show(
    BuildContext context, {
    required String itemName,
    required String currentPrice,
    Function(String)? onSave,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PriceEditModal(
        itemName: itemName,
        currentPrice: currentPrice,
        onSave: onSave,
      ),
    );
  }

  @override
  State<PriceEditModal> createState() => _PriceEditModalState();
}

class _PriceEditModalState extends State<PriceEditModal> {
  late TextEditingController _priceController;
  PriceEditState _state = PriceEditState.normal;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(text: widget.currentPrice);
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    final newPrice = _priceController.text.trim();
    if (newPrice.isEmpty) {
      setState(() {
        _state = PriceEditState.error;
        _errorMessage = 'Vui lòng nhập giá';
      });
      return;
    }

    final priceInt = int.tryParse(newPrice);
    if (priceInt == null || priceInt <= 0) {
      setState(() {
        _state = PriceEditState.error;
        _errorMessage = 'Giá không hợp lệ';
      });
      return;
    }

    setState(() {
      _state = PriceEditState.saving;
      _errorMessage = null;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _state = PriceEditState.success;
      });

      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        widget.onSave?.call(newPrice);
        Navigator.of(context).pop();
      }
    }
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildItemInfo(),
                  const SizedBox(height: 20),
                  _buildPriceInput(),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    _buildErrorMessage(),
                  ],
                  const SizedBox(height: 20),
                  _buildActionButtons(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderSoft,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
            child: const Icon(
              Icons.edit_outlined,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Chỉnh sửa giá',
              style: GoogleFonts.inter(
                fontSize: 16,
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
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildItemInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
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
              widget.itemName,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceInput() {
    final isEditing = _state == PriceEditState.editing;
    final isSaving = _state == PriceEditState.saving;
    final isSuccess = _state == PriceEditState.success;
    final hasError = _state == PriceEditState.error;

    Color borderColor = AppColors.borderSoft;
    if (hasError) {
      borderColor = AppColors.danger;
    } else if (isSuccess) {
      borderColor = AppColors.success;
    } else if (isEditing) {
      borderColor = AppColors.primary;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Giá mới (VNĐ)',
          style: AppTextStyles.label14,
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(
              color: borderColor,
              width: isEditing || hasError || isSuccess ? 2 : 1,
            ),
            boxShadow: isEditing
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: TextField(
            controller: _priceController,
            enabled: !isSaving && !isSuccess,
            keyboardType: TextInputType.number,
            onChanged: (value) {
              if (_state != PriceEditState.editing) {
                setState(() {
                  _state = PriceEditState.editing;
                  _errorMessage = null;
                });
              }
            },
            decoration: InputDecoration(
              hintText: 'Nhập giá',
              hintStyle: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
              prefixIcon: const Icon(
                Icons.attach_money_outlined,
                size: 20,
                color: AppColors.textSecondary,
              ),
              suffixIcon: _buildSuffixIcon(),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget? _buildSuffixIcon() {
    switch (_state) {
      case PriceEditState.saving:
        return const Padding(
          padding: EdgeInsets.all(12),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        );
      case PriceEditState.success:
        return const Padding(
          padding: EdgeInsets.all(12),
          child: Icon(
            Icons.check_circle,
            color: AppColors.success,
            size: 20,
          ),
        );
      case PriceEditState.error:
        return const Padding(
          padding: EdgeInsets.all(12),
          child: Icon(
            Icons.error_outline,
            color: AppColors.danger,
            size: 20,
          ),
        );
      default:
        return null;
    }
  }

  Widget _buildErrorMessage() {
    if (_errorMessage == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(
          color: AppColors.danger.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            size: 16,
            color: AppColors.danger,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final isSaving = _state == PriceEditState.saving;
    final isSuccess = _state == PriceEditState.success;

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
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
            ),
            onPressed: (isSaving || isSuccess) ? null : _handleSave,
            icon: isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(
                    Icons.save_outlined,
                    color: Colors.white,
                  ),
            label: Text(
              isSaving
                  ? 'Đang lưu...'
                  : isSuccess
                      ? 'Đã lưu thành công'
                      : 'Lưu thay đổi',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        if (!isSaving && !isSuccess) ...[
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
              onPressed: () => Navigator.of(context).pop(),
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
      ],
    );
  }
}
