import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../design_system.dart';

/// Bottom navigation bar cho driver app với 4 tabs
class DriverBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const DriverBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.borderSoft,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.only(top: 12, bottom: 20),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              icon: Icons.dashboard,
              label: 'Dashboard',
              index: 0,
              isActive: currentIndex == 0,
            ),
            _buildNavItem(
              icon: Icons.history,
              label: 'Lịch sử',
              index: 1,
              isActive: currentIndex == 1,
            ),
            _buildNavItem(
              icon: Icons.account_balance_wallet,
              label: 'Ví tiền',
              index: 2,
              isActive: currentIndex == 2,
            ),
            _buildNavItem(
              icon: Icons.person,
              label: 'Cá nhân',
              index: 3,
              isActive: currentIndex == 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? AppColors.primary : AppColors.driverTextSecondary,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? AppColors.primary : AppColors.driverTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
