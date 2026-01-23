import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../ui/design_system.dart';

/// Template Example – Error State Screen
/// Template màn hình hiển thị trạng thái lỗi: icon, message, action buttons.
class ErrorStateScreen extends StatelessWidget {
  final String? title;
  final String? message;
  final VoidCallback? onRetry;
  final VoidCallback? onGoBack;

  const ErrorStateScreen({
    super.key,
    this.title,
    this.message,
    this.onRetry,
    this.onGoBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildErrorIcon(),
              const SizedBox(height: 24),
              _buildErrorTitle(),
              const SizedBox(height: 12),
              _buildErrorMessage(),
              const SizedBox(height: 32),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.error_outline,
        size: 64,
        color: AppColors.danger,
      ),
    );
  }

  Widget _buildErrorTitle() {
    return Text(
      title ?? 'Đã xảy ra lỗi',
      style: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildErrorMessage() {
    return Text(
      message ??
          'Không thể tải dữ liệu. Vui lòng kiểm tra kết nối mạng và thử lại.',
      style: GoogleFonts.inter(
        fontSize: 14,
        color: AppColors.textSecondary,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (onRetry != null)
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
              onPressed: onRetry,
              icon: const Icon(
                Icons.refresh,
                color: Colors.white,
              ),
              label: Text(
                'Thử lại',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        if (onRetry != null && onGoBack != null) const SizedBox(height: 12),
        if (onGoBack != null)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: AppColors.textSecondary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              onPressed: onGoBack,
              icon: const Icon(
                Icons.arrow_back,
                color: AppColors.textSecondary,
              ),
              label: Text(
                'Quay lại',
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
