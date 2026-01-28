import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../ui/design_system.dart';
import '../../ui/widgets/driver_status_badge.dart';
import '../../ui/widgets/driver_bottom_nav_bar.dart';
import '../../ui/widgets/notification_badge.dart';
import '../../providers/app_providers.dart';
import '../../data/models/order_model.dart';
import '../../ui/widgets/route_path_painter.dart';

/// Driver Dashboard & Request Screen
/// Dashboard tài xế với danh sách đơn hàng đang chờ nhận / có thể nhận.
class DriverDashboardRequestScreen extends ConsumerStatefulWidget {
  const DriverDashboardRequestScreen({super.key});

  @override
  ConsumerState<DriverDashboardRequestScreen> createState() =>
      _DriverDashboardRequestScreenState();
}

class _DriverDashboardRequestScreenState
    extends ConsumerState<DriverDashboardRequestScreen> {
  bool _isAccepting = false;
  OrderModel? _selectedOrder;


  Future<void> _acceptOrder(OrderModel order) async {
    if (_isAccepting) return;

    setState(() {
      _isAccepting = true;
      _selectedOrder = null; // Hide bottom sheet
    });
    try {
      await ref.read(driverRepositoryProvider).acceptOrder(order.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã nhận đơn #${order.orderNumber}'),
            backgroundColor: AppColors.success,
          ),
        );
        // Chuyển đến màn hình xử lý đơn hàng
        context.push('/driver/order/${order.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể nhận đơn: ${e.toString()}'),
            backgroundColor: AppColors.danger,
          ),
        );
        // Show order request again on error
        setState(() => _selectedOrder = order);
      }
    } finally {
      if (mounted) setState(() => _isAccepting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider);
    final marketId = profile.value?.marketId ?? '';
    final driverStatus = profile.value?.driverStatus ?? 'offline';
    final isOnline = driverStatus == 'online' || driverStatus == 'busy';

    // Watch available orders stream
    final availableOrdersAsync = ref.watch(
      availableOrdersStreamProvider(marketId),
    );

    return Scaffold(
      backgroundColor: AppColors.driverBackgroundLight,
      body: Stack(
        children: [
          // Map background
          _buildMapBackground(),
          // Floating top bar
          SafeArea(
            child: _buildFloatingTopBar(isOnline),
          ),
          // Content overlay (empty state, error, or order sheet)
          Positioned.fill(
            child: availableOrdersAsync.when(
              data: (orders) {
                if (orders.isEmpty) {
                  return _buildEmptyState();
                }
                // Auto-show first order in bottom sheet
                if (_selectedOrder == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _selectedOrder = orders.first;
                      });
                    }
                  });
                }
                return const SizedBox.shrink();
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorState(error.toString()),
            ),
          ),
          // Bottom sheet for order request
          if (_selectedOrder != null)
            Positioned(
              bottom: 85, // Above bottom nav
              left: 0,
              right: 0,
              child: OrderRequestBottomSheet(
                order: _selectedOrder!,
                pickup: _selectedOrder!.pickup,
                dropoff: _selectedOrder!.dropoff,
                remainingSeconds: 30,
                onAccept: () => _acceptOrder(_selectedOrder!),
                onReject: () => setState(() => _selectedOrder = null),
              ),
            ),
          // Bottom navigation
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: DriverBottomNavBar(
              currentIndex: 0,
              onTap: (index) {
                // TODO: Navigate
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapBackground() {
    return Positioned.fill(
      child: Container(
        color: const Color(0xFFE5E7EB),
        child: Stack(
          children: [
            // Placeholder map image or VietmapGL
            // For now, using a simple colored background
            // In production, use VietmapGL here
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFE5E7EB),
                    Color(0xFFD1D5DB),
                  ],
                ),
              ),
            ),
            // Simulated route path (simplified)
            CustomPaint(
              painter: RoutePathPainter(),
              size: Size.infinite,
            ),
            // Map markers would go here
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingTopBar(bool isOnline) {
    return Container(
      padding: const EdgeInsets.only(top: 48, left: 16, right: 16, bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.9),
            Colors.white.withValues(alpha: 0.5),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          DriverStatusBadge(
            isOnline: isOnline,
            label: 'Online',
          ),
          // Notification button
          NotificationBadge(
            onTap: () => context.push('/driver/notifications'),
            color: AppColors.textPrimary,
          ),
        ],
      ),
    );
  }


  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(
            'Chưa có đơn hàng nào cần giao',
            style: AppTextStyles.body13Secondary,
          ),
          const SizedBox(height: 8),
          Text(
            'Chúng tôi sẽ thông báo khi có đơn mới',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
            const SizedBox(height: 16),
            Text('Đã có lỗi xảy ra: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() {}),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

}
