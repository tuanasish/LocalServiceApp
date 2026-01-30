import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../ui/widgets/app_bottom_nav_bar.dart';

/// MainShell: Scaffold chính với Bottom Navigation Bar cố định
/// Sử dụng IndexedStack để giữ state của các tab
class MainShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: widget.navigationShell),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return AppBottomNavBar(
      currentIndex: widget.navigationShell.currentIndex,
      onTap: (index) => _onTabTap(index),
    );
  }

  void _onTabTap(int index) {
    // Sử dụng goBranch để giữ state của mỗi tab
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }
}
