import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../ui/design_system.dart';

/// Login Selection Screen
/// Chọn cách đăng nhập / vai trò: Khách hàng, Tài xế, Chủ cửa hàng.
class LoginSelectionScreen extends StatelessWidget {
  const LoginSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chào mừng trở lại 👋',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Chọn cách anh muốn tiếp tục đăng nhập\nvào hệ sinh thái Chợ Quê.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Column(
                  children: [
                    _buildRoleCard(
                      icon: Icons.shopping_bag_outlined,
                      title: 'Tôi là khách hàng',
                      description:
                          'Đặt món ăn, đặc sản và nhu yếu phẩm\ncho gia đình.',
                      badge: 'App Khách hàng',
                      onTap: () {
                        // TODO: điều hướng flow login khách hàng
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildRoleCard(
                      icon: Icons.delivery_dining,
                      title: 'Tôi là tài xế',
                      description:
                          'Nhận đơn giao hàng, theo dõi thu nhập\nvà lịch sử chuyến đi.',
                      badge: 'App Tài xế',
                      onTap: () {
                        // TODO: điều hướng flow login tài xế
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildRoleCard(
                      icon: Icons.storefront_outlined,
                      title: 'Tôi là chủ cửa hàng',
                      description:
                          'Quản lý đơn hàng, cập nhật thực đơn\nvà giá bán mỗi ngày.',
                      badge: 'App Chủ cửa hàng',
                      onTap: () {
                        // TODO: điều hướng flow login merchant
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () {
                    // TODO: có thể mở màn chọn ngôn ngữ / vùng miền
                  },
                  child: Text(
                    'Tiếp tục với số điện thoại',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required IconData icon,
    required String title,
    required String description,
    required String badge,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.large),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.large),
          boxShadow: AppShadows.soft(0.04),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: Icon(icon, size: 24, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      badge,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
