import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../providers/admin_order_provider.dart';
import '../../providers/driver_admin_provider.dart';
import '../../providers/app_providers.dart';
import '../../data/models/order_model.dart';
import '../../data/models/profile_model.dart';
import '../../ui/widgets/admin_order_card.dart';
import '../../ui/design_system.dart';

/// Admin Orders Screen
///
/// Màn hình quản lý đơn hàng cho admin với 3 tabs:
/// - Chờ xác nhận (PENDING_CONFIRMATION)
/// - Chờ gán tài xế (CONFIRMED + READY_FOR_PICKUP)
/// - Đang thực hiện (ASSIGNED + PICKED_UP)
class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Quản lý đơn hàng',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          labelStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          tabs: [
            _buildTabWithBadge('Chờ xác nhận', ref.watch(pendingOrdersCountProvider)),
            _buildTabWithBadge('Chờ gán', ref.watch(confirmedOrdersCountProvider)),
            _buildTabWithBadge('Đang giao', ref.watch(activeOrdersCountProvider)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingOrdersTab(),
          _buildConfirmedOrdersTab(),
          _buildActiveOrdersTab(),
        ],
      ),
    );
  }

  Widget _buildTabWithBadge(String label, AsyncValue<int> countAsync) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          countAsync.when(
            data: (count) {
              if (count == 0) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ============================================
  // TAB 1: Pending Orders (Chờ xác nhận)
  // ============================================
  Widget _buildPendingOrdersTab() {
    final ordersAsync = ref.watch(pendingAdminOrdersProvider);

    return ordersAsync.when(
      data: (orders) {
        if (orders.isEmpty) {
          return _buildEmptyState(
            icon: Icons.inbox_outlined,
            title: 'Không có đơn chờ xác nhận',
            subtitle: 'Các đơn hàng mới sẽ xuất hiện ở đây',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(pendingAdminOrdersProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return AdminOrderCard(
                order: order,
                onTap: () => context.push('/admin/orders/${order.id}'),
                onConfirm: () => _confirmOrder(order),
                onCancel: () => _showCancelDialog(order),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _buildErrorState(error.toString()),
    );
  }

  // ============================================
  // TAB 2: Confirmed Orders (Chờ gán tài xế)
  // ============================================
  Widget _buildConfirmedOrdersTab() {
    final ordersAsync = ref.watch(confirmedAdminOrdersProvider);

    return ordersAsync.when(
      data: (orders) {
        if (orders.isEmpty) {
          return _buildEmptyState(
            icon: Icons.local_shipping_outlined,
            title: 'Không có đơn chờ gán tài xế',
            subtitle: 'Các đơn đã xác nhận sẽ xuất hiện ở đây',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(confirmedAdminOrdersProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return AdminOrderCard(
                order: order,
                onTap: () => context.push('/admin/orders/${order.id}'),
                onAssignDriver: () => _showAssignDriverDialog(order),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _buildErrorState(error.toString()),
    );
  }

  // ============================================
  // TAB 3: Active Orders (Đang thực hiện)
  // ============================================
  Widget _buildActiveOrdersTab() {
    final ordersAsync = ref.watch(activeAdminOrdersProvider);

    return ordersAsync.when(
      data: (orders) {
        if (orders.isEmpty) {
          return _buildEmptyState(
            icon: Icons.two_wheeler_outlined,
            title: 'Không có đơn đang giao',
            subtitle: 'Các đơn đang thực hiện sẽ xuất hiện ở đây',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(activeAdminOrdersProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return AdminOrderCard(
                order: order,
                onTap: () => context.push('/admin/orders/${order.id}'),
                onReassignDriver: () => _showReassignDriverDialog(order),
                onCancel: () => _showCancelDialog(order),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _buildErrorState(error.toString()),
    );
  }

  // ============================================
  // ACTIONS
  // ============================================

  Future<void> _confirmOrder(OrderModel order) async {
    try {
      final repo = ref.read(orderRepositoryProvider);
      await repo.confirmOrder(order.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xác nhận đơn #${order.orderNumber}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _showCancelDialog(OrderModel order) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Hủy đơn #${order.orderNumber}',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bạn có chắc muốn hủy đơn hàng này?',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Lý do hủy *',
                hintText: 'Nhập lý do hủy đơn',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Quay lại', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập lý do hủy')),
                );
                return;
              }

              Navigator.pop(context);
              await _cancelOrder(order, reasonController.text.trim());
            },
            child: Text('Hủy đơn', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelOrder(OrderModel order, String reason) async {
    try {
      final repo = ref.read(orderRepositoryProvider);
      await repo.cancelOrderByAdmin(order.id, reason);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã hủy đơn #${order.orderNumber}'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _showAssignDriverDialog(OrderModel order) {
    final driversAsync = ref.read(onlineDriversProvider);

    driversAsync.when(
      data: (drivers) {
        if (drivers.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không có tài xế online'),
              backgroundColor: AppColors.warning,
            ),
          );
          return;
        }

        _showDriverPickerDialog(
          order: order,
          drivers: drivers,
          title: 'Gán tài xế',
          actionText: 'Gán',
          onConfirm: (driver) => _assignDriver(order, driver),
        );
      },
      loading: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đang tải danh sách tài xế...')),
        );
      },
      error: (e, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      },
    );
  }

  void _showReassignDriverDialog(OrderModel order) {
    final driversAsync = ref.read(onlineDriversProvider);

    driversAsync.when(
      data: (drivers) {
        // Filter out current driver
        final availableDrivers = drivers
            .where((d) => d.userId != order.driverId)
            .toList();

        if (availableDrivers.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không có tài xế khác đang online'),
              backgroundColor: AppColors.warning,
            ),
          );
          return;
        }

        _showDriverPickerDialog(
          order: order,
          drivers: availableDrivers,
          title: 'Gán lại tài xế',
          actionText: 'Gán lại',
          showReasonField: true,
          onConfirmWithReason: (driver, reason) =>
              _reassignDriver(order, driver, reason),
        );
      },
      loading: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đang tải danh sách tài xế...')),
        );
      },
      error: (e, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      },
    );
  }

  void _showDriverPickerDialog({
    required OrderModel order,
    required List<ProfileModel> drivers,
    required String title,
    required String actionText,
    bool showReasonField = false,
    Function(ProfileModel)? onConfirm,
    Function(ProfileModel, String)? onConfirmWithReason,
  }) {
    ProfileModel? selectedDriver;
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            '$title cho đơn #${order.orderNumber}',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chọn tài xế:',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: drivers.length,
                  itemBuilder: (context, index) {
                    final driver = drivers[index];
                    final isSelected = selectedDriver?.userId == driver.userId;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: isSelected
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.1),
                        child: Icon(
                          Icons.person,
                          color: isSelected ? Colors.white : AppColors.primary,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        driver.fullName ?? 'Tài xế',
                        style: GoogleFonts.inter(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        driver.phone ?? '',
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: AppColors.primary)
                          : null,
                      onTap: () => setState(() => selectedDriver = driver),
                    );
                  },
                ),
              ),
              if (showReasonField) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: InputDecoration(
                    labelText: 'Lý do gán lại',
                    hintText: 'Nhập lý do...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 2,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy', style: GoogleFonts.inter()),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: selectedDriver == null
                  ? null
                  : () {
                      Navigator.pop(context);
                      if (showReasonField && onConfirmWithReason != null) {
                        onConfirmWithReason(
                          selectedDriver!,
                          reasonController.text.trim(),
                        );
                      } else if (onConfirm != null) {
                        onConfirm(selectedDriver!);
                      }
                    },
              child: Text(
                actionText,
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _assignDriver(OrderModel order, ProfileModel driver) async {
    try {
      final repo = ref.read(orderRepositoryProvider);
      await repo.assignDriver(order.id, driver.userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã gán ${driver.fullName ?? "tài xế"} cho đơn #${order.orderNumber}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _reassignDriver(
    OrderModel order,
    ProfileModel newDriver,
    String reason,
  ) async {
    try {
      final repo = ref.read(orderRepositoryProvider);
      await repo.reassignDriver(
        order.id,
        newDriver.userId,
        reason.isNotEmpty ? reason : 'Admin reassigned',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã gán lại ${newDriver.fullName ?? "tài xế"} cho đơn #${order.orderNumber}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  // ============================================
  // HELPER WIDGETS
  // ============================================

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
            const SizedBox(height: 16),
            Text(
              'Đã xảy ra lỗi',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
