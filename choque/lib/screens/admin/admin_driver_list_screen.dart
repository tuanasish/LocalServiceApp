import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../ui/design_system.dart';
import '../../providers/app_providers.dart';
import '../../providers/driver_admin_provider.dart';
import '../../ui/widgets/driver_approval_card.dart';
import 'admin_driver_detail_screen.dart';

/// Admin Driver List Screen
///
/// Màn hình quản lý danh sách tài xế với các tab: Pending, Approved, Rejected.
class AdminDriverListScreen extends ConsumerStatefulWidget {
  const AdminDriverListScreen({super.key});

  @override
  ConsumerState<AdminDriverListScreen> createState() =>
      _AdminDriverListScreenState();
}

class _AdminDriverListScreenState extends ConsumerState<AdminDriverListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Quản lý Tài xế',
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên hoặc SĐT...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: AppColors.backgroundLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),

              // Tabs
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                labelStyle: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                tabs: [
                  Tab(
                    child: _buildTabWithBadge(
                      'Chờ duyệt',
                      ref.watch(pendingDriversCountProvider),
                    ),
                  ),
                  Tab(
                    child: _buildTabWithBadge(
                      'Đã duyệt',
                      ref.watch(approvedDriversProvider).whenData((d) => d.length),
                    ),
                  ),
                  Tab(
                    child: _buildTabWithBadge(
                      'Từ chối',
                      ref.watch(rejectedDriversProvider).whenData((d) => d.length),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDriverList(ref.watch(pendingDriversProvider)),
          _buildDriverList(ref.watch(approvedDriversProvider)),
          _buildDriverList(ref.watch(rejectedDriversProvider)),
        ],
      ),
    );
  }

  Widget _buildTabWithBadge(String label, AsyncValue<int>? count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        if (count != null)
          count.when(
            data: (value) {
              if (value == 0) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  value.toString(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
      ],
    );
  }

  Widget _buildDriverList(AsyncValue driversAsync) {
    return driversAsync.when(
      data: (drivers) {
        // Filter by search query
        final filteredDrivers = drivers.where((driver) {
          if (_searchQuery.isEmpty) return true;
          final name = driver.fullName?.toLowerCase() ?? '';
          final phone = driver.phone?.toLowerCase() ?? '';
          return name.contains(_searchQuery) || phone.contains(_searchQuery);
        }).toList();

        if (filteredDrivers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_off_outlined,
                  size: 64,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isEmpty
                      ? 'Chưa có tài xế nào'
                      : 'Không tìm thấy tài xế',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(pendingDriversProvider);
            ref.invalidate(approvedDriversProvider);
            ref.invalidate(rejectedDriversProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredDrivers.length,
            itemBuilder: (context, index) {
              final driver = filteredDrivers[index];
              return DriverApprovalCard(
                driver: driver,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AdminDriverDetailScreen(driverId: driver.userId),
                    ),
                  );
                },
                onApprove: driver.isDriverPending
                    ? () => _showApproveDialog(driver.userId)
                    : null,
                onReject: driver.isDriverPending
                    ? () => _showRejectDialog(driver.userId)
                    : null,
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.danger),
            const SizedBox(height: 16),
            Text(
              'Lỗi: ${error.toString()}',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(pendingDriversProvider);
                ref.invalidate(approvedDriversProvider);
                ref.invalidate(rejectedDriversProvider);
              },
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  void _showApproveDialog(String driverId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Duyệt tài xế',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Bạn có chắc muốn duyệt tài xế này? Sau khi duyệt, tài xế sẽ có thể nhận đơn hàng.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _approveDriver(driverId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Duyệt'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(String driverId) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Từ chối tài xế',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vui lòng nhập lý do từ chối:', style: GoogleFonts.inter()),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ví dụ: Giấy tờ không hợp lệ...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập lý do từ chối')),
                );
                return;
              }
              Navigator.pop(context);
              await _rejectDriver(driverId, reasonController.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
  }

  Future<void> _approveDriver(String driverId) async {
    try {
      final repo = ref.read(driverRepositoryProvider);
      await repo.approveDriver(driverId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã duyệt tài xế thành công')),
        );
        // Refresh lists
        ref.invalidate(pendingDriversProvider);
        ref.invalidate(approvedDriversProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
      }
    }
  }

  Future<void> _rejectDriver(String driverId, String reason) async {
    try {
      final repo = ref.read(driverRepositoryProvider);
      await repo.rejectDriver(driverId, reason);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã từ chối tài xế')));
        // Refresh lists
        ref.invalidate(pendingDriversProvider);
        ref.invalidate(rejectedDriversProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
      }
    }
  }
}
