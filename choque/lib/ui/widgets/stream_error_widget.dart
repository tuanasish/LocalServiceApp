import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../design_system.dart';

/// A reusable widget to display stream/async errors with a retry button.
class StreamErrorWidget extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  final String? title;
  final String? retryLabel;

  const StreamErrorWidget({
    super.key,
    required this.error,
    required this.onRetry,
    this.title,
    this.retryLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              title ?? 'Lỗi kết nối',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getErrorMessage(error),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: Text(
                retryLabel ?? 'Thử lại',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getErrorMessage(Object error) {
    final errorStr = error.toString();
    
    // Network errors
    if (errorStr.contains('SocketException') || 
        errorStr.contains('TimeoutException') ||
        errorStr.contains('Connection')) {
      return 'Không thể kết nối. Vui lòng kiểm tra mạng.';
    }
    
    // Auth errors
    if (errorStr.contains('unauthenticated') || 
        errorStr.contains('Unauthorized')) {
      return 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.';
    }
    
    // Generic
    return 'Đã có lỗi xảy ra. Vui lòng thử lại.';
  }
}
