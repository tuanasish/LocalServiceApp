import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_profile.dart';
import '../../ui/design_system.dart';

/// Role Switcher Screen - chọn role khi user có nhiều roles
class RoleSwitcherScreen extends ConsumerWidget {
  const RoleSwitcherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final availableRoles = ref.watch(availableRolesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              _buildHeader(profileAsync),
              const SizedBox(height: 48),
              Expanded(
                child: _buildRoleCards(context, ref, availableRoles),
              ),
              _buildLogoutButton(context, ref),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AsyncValue<UserProfile?> profileAsync) {
    final name = profileAsync.when(
      data: (p) => p?.displayName ?? 'Bạn',
      loading: () => '…',
      error: (e, st) => 'Bạn',
    );

    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFFE8D5B7),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person,
            size: 36,
            color: Color(0xFFA58860),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Xin chào, $name!',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Bạn muốn tiếp tục với vai trò nào?',
          style: GoogleFonts.inter(
            fontSize: 15,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleCards(BuildContext context, WidgetRef ref, List<UserRole> roles) {
    return ListView.separated(
      itemCount: roles.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final role = roles[index];
        return _RoleCard(
          role: role,
          onTap: () {
            ref.read(activeRoleProvider.notifier).setRole(role);
            context.go(role.route);
          },
        );
      },
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return TextButton.icon(
      onPressed: () async {
        await ref.read(authNotifierProvider.notifier).signOut();
        if (context.mounted) {
          context.go('/login');
        }
      },
      icon: Icon(Icons.logout, color: Colors.grey[600], size: 20),
      label: Text(
        'Đăng xuất',
        style: GoogleFonts.inter(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final UserRole role;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
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
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _getColor().withAlpha(26),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  role.icon,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.displayName,
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getDescription(),
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
      ),
    );
  }

  Color _getColor() {
    switch (role) {
      case UserRole.customer:
        return AppColors.primary;
      case UserRole.driver:
        return Colors.blue;
      case UserRole.merchant:
        return Colors.orange;
      case UserRole.admin:
        return Colors.purple;
    }
  }

  String _getDescription() {
    switch (role) {
      case UserRole.customer:
        return 'Đặt đồ ăn và theo dõi đơn hàng';
      case UserRole.driver:
        return 'Nhận và giao đơn hàng';
      case UserRole.merchant:
        return 'Quản lý cửa hàng và đơn hàng';
      case UserRole.admin:
        return 'Quản trị hệ thống';
    }
  }
}
