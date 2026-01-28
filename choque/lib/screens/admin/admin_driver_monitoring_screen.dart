import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../ui/design_system.dart';
import '../../providers/driver_admin_provider.dart';
import '../../ui/widgets/driver_status_badge.dart';
import 'admin_driver_detail_screen.dart';

/// Admin Driver Monitoring Screen
///
/// Màn hình giám sát tài xế theo thời gian thực.
/// TODO: Integrate Google Maps for real-time location tracking
class AdminDriverMonitoringScreen extends ConsumerStatefulWidget {
  const AdminDriverMonitoringScreen({super.key});

  @override
  ConsumerState<AdminDriverMonitoringScreen> createState() =>
      _AdminDriverMonitoringScreenState();
}

class _AdminDriverMonitoringScreenState
    extends ConsumerState<AdminDriverMonitoringScreen> {
  String _filter = 'all'; // all, online, busy

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Giám sát Tài xế',
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Filter dropdown
          PopupMenuButton<String>(
            initialValue: _filter,
            onSelected: (value) {
              setState(() {
                _filter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('Tất cả')),
              const PopupMenuItem(value: 'online', child: Text('Online')),
              const PopupMenuItem(value: 'busy', child: Text('Đang giao')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.filter_list, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    _getFilterLabel(_filter),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Bar
          _buildStatsBar(),

          // Map Placeholder
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(AppRadius.medium),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map_outlined,
                      size: 64,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Bản đồ theo dõi GPS',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tích hợp Google Maps sẽ được thêm sau',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Driver List
          Expanded(flex: 1, child: _buildDriverList()),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    final onlineCount = ref.watch(onlineDriversCountProvider);
    final busyCount = ref.watch(busyDriversCountProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Online',
              onlineCount,
              AppColors.success,
              Icons.circle,
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.border),
          Expanded(
            child: _buildStatItem(
              'Đang giao',
              busyCount,
              const Color(0xFFF59E0B),
              Icons.local_shipping,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    AsyncValue<int> countAsync,
    Color color,
    IconData icon,
  ) {
    return countAsync.when(
      data: (count) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count.toString(),
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
      loading: () => const SizedBox(
        height: 40,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildDriverList() {
    final driversAsync = _filter == 'online'
        ? ref.watch(onlineDriversProvider)
        : _filter == 'busy'
        ? ref.watch(busyDriversProvider)
        : ref.watch(approvedDriversProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.large),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Danh sách tài xế',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: driversAsync.when(
              data: (drivers) {
                if (drivers.isEmpty) {
                  return Center(
                    child: Text(
                      'Không có tài xế nào',
                      style: GoogleFonts.inter(color: AppColors.textSecondary),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: drivers.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final driver = drivers[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.1,
                        ),
                        child: Text(
                          _getInitials(driver.fullName ?? 'D'),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      title: Text(
                        driver.fullName ?? 'Chưa có tên',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        driver.phone ?? 'Chưa có SĐT',
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                      trailing: driver.driverStatus != null
                          ? DriverStatusBadge(
                              status: driver.driverStatus!,
                              compact: true,
                            )
                          : null,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminDriverDetailScreen(
                              driverId: driver.userId,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text(
                  'Lỗi: ${error.toString()}',
                  style: GoogleFonts.inter(color: AppColors.textSecondary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'online':
        return 'Online';
      case 'busy':
        return 'Đang giao';
      default:
        return 'Tất cả';
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return 'D';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }
}
