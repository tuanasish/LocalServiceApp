import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../ui/design_system.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_providers.dart' show currentUserProvider;
import '../../models/user_profile.dart';

/// User Profile Screen
/// Màn hình profile của user theo design mới
class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final profile = profileAsync.value;
    final currentUser = ref.watch(currentUserProvider).value;
    final isGuest = !isAuthenticated || (profile?.isGuest ?? false);

    // Hiển thị error nếu có lỗi network
    if (profileAsync.hasError) {
      final error = profileAsync.error;
      if (error != null &&
          (error.toString().contains('Failed host lookup') ||
              error.toString().contains('SocketException') ||
              error.toString().contains('Network'))) {
        return Scaffold(
          backgroundColor: AppColors.backgroundLight,
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Không thể kết nối đến server',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vui lòng kiểm tra kết nối mạng và thử lại',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(userProfileProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        'Thử lại',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      _buildProfileCard(context, ref, isAuthenticated, profile),
                      const SizedBox(height: 24),
                      if (!isGuest) ...[
                        _buildSectionTitle('THÔNG TIN CÁ NHÂN'),
                        const SizedBox(height: 12),
                        _buildInfoCard(context, ref, profile, currentUser),
                        const SizedBox(height: 24),
                      ],
                      _buildSectionTitle('THAO TÁC NHANH'),
                      const SizedBox(height: 12),
                      _buildQuickActions(context),
                      const SizedBox(height: 32),
                      if (!isGuest)
                        _buildLogoutButton(ref)
                      else
                        _buildAuthButtons(context),
                      const SizedBox(height: 16),
                      _buildVersionText(),
                      const SizedBox(height: 24),
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'Tài khoản',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.settings_outlined, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(
    BuildContext context,
    WidgetRef ref,
    bool isAuthenticated,
    UserProfile? profile,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: isAuthenticated ? () => _updateAvatar(context, ref) : null,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFE8D5B7),
                shape: BoxShape.circle,
                image: profile?.avatarUrl != null
                    ? DecorationImage(
                        image: NetworkImage(profile!.avatarUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: profile?.avatarUrl == null
                  ? const Icon(Icons.person, size: 36, color: Color(0xFFA58860))
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAuthenticated && !(profile?.isGuest ?? false)
                      ? (profile?.fullName ?? 'Hội viên')
                      : 'Khách hàng',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAuthenticated && !(profile?.isGuest ?? false)
                      ? (profile?.phone ?? 'Chưa cập nhật SĐT')
                      : 'Đang duyệt ẩn danh',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                if (isAuthenticated && !(profile?.isGuest ?? false)) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'ĐÃ XÁC THỰC',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey[500],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    WidgetRef ref,
    UserProfile? profile,
    User? currentUser,
  ) {
    // Lấy email từ auth user
    final email = currentUser?.email ?? 'Chưa cập nhật';

    // Lấy giới tính từ profile
    String genderText = 'Chưa xác định';
    if (profile?.gender != null && profile!.gender!.isNotEmpty) {
      switch (profile.gender!.toLowerCase()) {
        case 'male':
        case 'nam':
        case 'm':
          genderText = 'Nam';
          break;
        case 'female':
        case 'nữ':
        case 'f':
          genderText = 'Nữ';
          break;
        case 'other':
        case 'khác':
        case 'o':
          genderText = 'Khác';
          break;
        default:
          genderText = profile.gender!;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.email_outlined,
            iconColor: AppColors.primary,
            label: 'Email',
            value: email,
          ),
          Divider(height: 1, color: Colors.grey[200]),
          _buildInfoRow(
            icon: Icons.person_outline,
            iconColor: AppColors.primary,
            label: 'Giới tính',
            value: genderText,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(26),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey[400]),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildActionRow(
            icon: Icons.favorite_outline,
            iconColor: AppColors.primary,
            label: 'Cửa hàng yêu thích',
            onTap: () => context.push('/profile/favorites'),
          ),
          Divider(height: 1, color: Colors.grey[200]),
          _buildActionRow(
            icon: Icons.location_on_outlined,
            iconColor: AppColors.primary,
            label: 'Địa chỉ đã lưu',
            onTap: () => context.push('/profile/addresses'),
          ),
          Divider(height: 1, color: Colors.grey[200]),
          _buildActionRow(
            icon: Icons.receipt_long_outlined,
            iconColor: AppColors.primary,
            label: 'Đơn hàng của tôi',
          ),
          Divider(height: 1, color: Colors.grey[200]),
          _buildActionRow(
            icon: Icons.notifications_outlined,
            iconColor: AppColors.primary,
            label: 'Hộp thư',
            badgeCount: 2,
          ),
          Divider(height: 1, color: Colors.grey[200]),
          _buildActionRow(
            icon: Icons.settings_outlined,
            iconColor: AppColors.primary,
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    int? badgeCount,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(26),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (badgeCount != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$badgeCount',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(WidgetRef ref) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextButton.icon(
        onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
        icon: Icon(Icons.logout, color: Colors.grey[700], size: 20),
        label: Text(
          'Đăng xuất',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Future<void> _updateAvatar(BuildContext context, WidgetRef ref) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 500,
      );

      if (image == null) return;

      final authNotifier = ref.read(authNotifierProvider.notifier);
      final avatarUrl = await authNotifier.uploadAvatar(image);
      if (avatarUrl != null) {
        await authNotifier.updateProfile(avatarUrl: avatarUrl);
      }
    } catch (e) {
      if (context.mounted) {
        final msg = e.toString().toLowerCase();
        final isPermissionDenied = msg.contains('permission') ||
            msg.contains('denied') ||
            msg.contains('photo');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isPermissionDenied
                  ? 'Quyền truy cập ảnh đã bị tắt. Vui lòng bật trong Cài đặt.'
                  : 'Lỗi upload: ${e.toString()}',
            ),
            backgroundColor: isPermissionDenied ? Colors.orange : null,
          ),
        );
      }
    }
  }

  Widget _buildAuthButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.push('/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              'Đăng nhập ngay',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => context.push('/register'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: const BorderSide(color: AppColors.primary),
            ),
            child: Text(
              'Đăng ký tài khoản mới',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVersionText() {
    return Center(
      child: Text(
        'Phiên bản 2.4.0',
        style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[400]),
      ),
    );
  }
}
