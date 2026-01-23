import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../ui/design_system.dart';

/// User Profile Screen
/// Màn hình profile của user: thông tin cá nhân, địa chỉ, cài đặt.
class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            const AppSimpleHeader(title: 'Hồ sơ'),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      _buildProfileHeader(),
                      const SizedBox(height: 24),
                      _buildMenuSection(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        boxShadow: AppShadows.soft(0.04),
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              size: 50,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Nguyễn Văn A',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '0901 234 567',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            onPressed: () {},
            icon: const Icon(
              Icons.edit_outlined,
              size: 18,
              color: AppColors.primary,
            ),
            label: Text(
              'Chỉnh sửa hồ sơ',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    return Column(
      children: [
        _buildMenuItem(
          icon: Icons.location_on_outlined,
          title: 'Địa chỉ của tôi',
          subtitle: 'Quản lý địa chỉ giao hàng',
          onTap: () {},
        ),
        const SizedBox(height: 12),
        _buildMenuItem(
          icon: Icons.receipt_long_outlined,
          title: 'Đơn hàng của tôi',
          subtitle: 'Xem lịch sử đơn hàng',
          onTap: () {},
        ),
        const SizedBox(height: 12),
        _buildMenuItem(
          icon: Icons.favorite_outline,
          title: 'Món yêu thích',
          subtitle: 'Danh sách món đã lưu',
          onTap: () {},
        ),
        const SizedBox(height: 12),
        _buildMenuItem(
          icon: Icons.payment_outlined,
          title: 'Phương thức thanh toán',
          subtitle: 'Quản lý thẻ, ví điện tử',
          onTap: () {},
        ),
        const SizedBox(height: 12),
        _buildMenuItem(
          icon: Icons.settings_outlined,
          title: 'Cài đặt',
          subtitle: 'Ngôn ngữ, thông báo, bảo mật',
          onTap: () {},
        ),
        const SizedBox(height: 12),
        _buildMenuItem(
          icon: Icons.help_outline,
          title: 'Trợ giúp & Hỗ trợ',
          subtitle: 'Câu hỏi thường gặp, liên hệ',
          onTap: () {},
        ),
        const SizedBox(height: 12),
        _buildMenuItem(
          icon: Icons.logout_outlined,
          title: 'Đăng xuất',
          subtitle: null,
          onTap: () {},
          isDanger: true,
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.large),
          boxShadow: AppShadows.soft(0.04),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDanger
                    ? AppColors.danger.withValues(alpha: 0.1)
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: Icon(
                icon,
                size: 24,
                color: isDanger ? AppColors.danger : AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDanger ? AppColors.danger : AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
