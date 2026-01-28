import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../ui/design_system.dart';

/// Customer Profile Overview (Stitch)
/// - ScreenId: 56328457a92142f9a452d8a0d71a2a44
class CustomerProfileOverviewScreen extends StatelessWidget {
  const CustomerProfileOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _TopBar(
                  title: 'Tài khoản',
                  onBack: () => Navigator.of(context).maybePop(),
                  onSettings: () {},
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ProfileCard(
                          name: 'Nguyễn Văn A',
                          phone: '0901 234 567',
                          isVerified: true,
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'Thông tin cá nhân',
                          children: const [
                            _ProfileListTile(
                              icon: Icons.mail_outline,
                              title: 'Email',
                              subtitle: 'user@email.com',
                            ),
                            Divider(height: 1, color: AppColors.borderSoft),
                            _ProfileListTile(
                              icon: Icons.person_outline,
                              title: 'Giới tính',
                              subtitle: 'Nam',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'Thao tác nhanh',
                          children: const [
                            _ProfileListTile(
                              icon: Icons.location_on_outlined,
                              title: 'Địa chỉ đã lưu',
                            ),
                            Divider(height: 1, color: AppColors.borderSoft),
                            _ProfileListTile(
                              icon: Icons.receipt_long_outlined,
                              title: 'Đơn hàng của tôi',
                            ),
                            Divider(height: 1, color: AppColors.borderSoft),
                            _ProfileListTile(
                              icon: Icons.notifications_outlined,
                              title: 'Hộp thư',
                              trailingBadgeText: '2',
                            ),
                            Divider(height: 1, color: AppColors.borderSoft),
                            _ProfileListTile(
                              icon: Icons.settings_suggest_outlined,
                              title: 'Cài đặt',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _LogoutCard(
                          versionText: 'Phiên bản 2.4.0',
                          onLogout: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BottomNavBar(active: _BottomNavTab.profile),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.onBack,
    required this.onSettings,
  });

  final String title;
  final VoidCallback onBack;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              color: AppColors.textPrimary,
              splashRadius: 22,
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 40,
            height: 40,
            child: IconButton(
              onPressed: onSettings,
              icon: const Icon(Icons.settings_outlined, size: 20),
              color: AppColors.textPrimary,
              splashRadius: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.phone,
    required this.isVerified,
  });

  final String name;
  final String phone;
  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        boxShadow: AppShadows.soft(0.04),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.1),
                  ),
                ),
                child: const Icon(Icons.person, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      phone,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isVerified)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 14,
                    color: AppColors.textPrimary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Đã xác thực',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        boxShadow: AppShadows.soft(0.04),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Text(
                title.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                  color: AppColors.textMuted.withValues(alpha: 0.8),
                ),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ProfileListTile extends StatelessWidget {
  const _ProfileListTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailingBadgeText,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailingBadgeText;

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      constraints: const BoxConstraints(minHeight: 56),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailingBadgeText != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                trailingBadgeText!,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: () {}, child: tile),
    );
  }
}

class _LogoutCard extends StatelessWidget {
  const _LogoutCard({required this.versionText, required this.onLogout});

  final String versionText;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: AppColors.borderSoft,
              foregroundColor: AppColors.textPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.large),
              ),
            ),
            onPressed: onLogout,
            icon: const Icon(Icons.logout, size: 18),
            label: Text(
              'Đăng xuất',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          versionText,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

enum _BottomNavTab { home, explore, orders, profile }

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({required this.active});

  final _BottomNavTab active;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            _BottomNavItem(
              icon: Icons.home_outlined,
              label: 'Trang chủ',
              tab: _BottomNavTab.home,
            ),
            _BottomNavItem(
              icon: Icons.explore_outlined,
              label: 'Khám phá',
              tab: _BottomNavTab.explore,
            ),
            _BottomNavItem(
              icon: Icons.receipt_long_outlined,
              label: 'Đơn hàng',
              tab: _BottomNavTab.orders,
            ),
            _BottomNavItem(
              icon: Icons.person,
              label: 'Tài khoản',
              tab: _BottomNavTab.profile,
              filledWhenActive: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.tab,
    this.filledWhenActive = false,
  });

  final IconData icon;
  final String label;
  final _BottomNavTab tab;
  final bool filledWhenActive;

  @override
  Widget build(BuildContext context) {
    final parent = context.findAncestorWidgetOfExactType<_BottomNavBar>();
    final isActive = parent?.active == tab;

    final color = isActive ? AppColors.primary : AppColors.textMuted;
    final iconData = (isActive && filledWhenActive) ? Icons.person : icon;

    return Expanded(
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(iconData, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
