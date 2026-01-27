import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../ui/design_system.dart';
import '../../ui/widgets/stat_card.dart';
import '../../ui/widgets/driver_order_card.dart';
import '../../providers/app_providers.dart';
import '../../data/models/order_model.dart';

/// Driver Home Dashboard Screen
/// Màn chính cho tài xế: thống kê, đơn hàng đang chờ, trạng thái online/offline.
class DriverHomeDashboardScreen extends ConsumerStatefulWidget {
  const DriverHomeDashboardScreen({super.key});

  @override
  ConsumerState<DriverHomeDashboardScreen> createState() => _DriverHomeDashboardScreenState();
}

class _DriverHomeDashboardScreenState extends ConsumerState<DriverHomeDashboardScreen> {
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    // Load driver status từ profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDriverStatus();
    });
  }

  void _loadDriverStatus() {
    final profileAsync = ref.read(currentProfileProvider);
    profileAsync.whenData((profile) {
      if (profile?.driverStatus != null) {
        setState(() {
          _isOnline = profile!.driverStatus == 'online' || profile.driverStatus == 'busy';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: profileAsync.when(
          data: (profile) {
            if (profile == null || !profile.isDriver) {
              return _buildNotDriverState();
            }
            final driverStatus = profile.driverStatus ?? 'offline';
            final isOnline = driverStatus == 'online' || driverStatus == 'busy';
            if (_isOnline != isOnline) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() => _isOnline = isOnline);
              });
            }
            return _buildContent(profile.fullName ?? 'Tài xế', driverStatus);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorState(error.toString()),
        ),
      ),
    );
  }

  Widget _buildNotDriverState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.drive_eta_outlined, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'Không phải tài xế',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tài khoản của bạn chưa được cấp quyền tài xế. Vui lòng liên hệ admin.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.danger),
            const SizedBox(height: 16),
            Text(
              'Có lỗi xảy ra',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(currentProfileProvider),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(String driverName, String driverStatus) {
    return Column(
      children: [
        _buildHeader(driverName, driverStatus),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(currentProfileProvider);
              ref.invalidate(driverStatsProvider);
              ref.invalidate(assignedOrdersProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildStatsCards(),
                    const SizedBox(height: 20),
                    _buildStatusToggle(driverStatus),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Đơn hàng của tôi'),
                    const SizedBox(height: 12),
                    _buildOrderList(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(String driverName, String driverStatus) {
    final statusText = _getStatusText(driverStatus);
    final statusColor = _getStatusColor(driverStatus);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xin chào, $driverName',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: AppColors.textPrimary,
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    final statsAsync = ref.watch(driverStatsProvider);

    return statsAsync.when(
      data: (stats) {
        final todayOrders = stats['today_orders'] as int? ?? 0;
        final todayEarnings = stats['today_earnings'] as int? ?? 0;
        final rating = 4.8; // TODO: Thêm rating vào driver stats

        return Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.local_shipping_outlined,
                label: 'Đơn hôm nay',
                value: todayOrders.toString(),
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                icon: Icons.attach_money_outlined,
                label: 'Thu nhập',
                value: _formatEarnings(todayEarnings),
                color: const Color(0xFF16A34A),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                icon: Icons.star_outline,
                label: 'Đánh giá',
                value: rating.toStringAsFixed(1),
                color: const Color(0xFFF59E0B),
              ),
            ),
          ],
        );
      },
      loading: () => Row(
        children: [
          Expanded(child: _buildStatCardSkeleton()),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCardSkeleton()),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCardSkeleton()),
        ],
      ),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildStatCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.borderSoft,
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 60,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.borderSoft,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 40,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.borderSoft,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusToggle(String currentStatus) {
    final isOnline = currentStatus == 'online' || currentStatus == 'busy';
    final isBusy = currentStatus == 'busy';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        boxShadow: AppShadows.soft(0.04),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trạng thái nhận đơn',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isBusy 
                    ? 'Đang có đơn hàng'
                    : isOnline 
                        ? 'Bật để nhận đơn hàng mới'
                        : 'Tắt để không nhận đơn',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Switch(
            value: isOnline,
            onChanged: isBusy ? null : (value) async {
              try {
                if (value) {
                  await ref.read(driverRepositoryProvider).goOnline();
                } else {
                  await ref.read(driverRepositoryProvider).goOffline();
                }
                ref.invalidate(currentProfileProvider);
                setState(() => _isOnline = value);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(value ? 'Đã bật trạng thái online' : 'Đã tắt trạng thái'),
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
            },
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.heading18,
    );
  }

  Widget _buildOrderList() {
    final ordersAsync = ref.watch(driverOrdersStreamProvider);

    return ordersAsync.when(
      data: (orders) {
        if (orders.isEmpty) {
          return _buildEmptyState();
        }
        return Column(
          children: orders.map((order) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildOrderCard(order),
            );
          }).toList(),
        );
      },
      loading: () => Column(
        children: List.generate(2, (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildOrderCardSkeleton(),
        )),
      ),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.danger),
              const SizedBox(height: 8),
              Text(
                'Lỗi tải đơn hàng',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(driverOrdersStreamProvider),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    // Lấy thông tin cửa hàng và items
    final merchantAsync = order.shopId != null 
        ? ref.watch(merchantDetailProvider(order.shopId!))
        : null;
    final itemsAsync = ref.watch(orderItemsProvider(order.id));

    return itemsAsync.when(
      data: (items) {
        final storeName = merchantAsync?.when(
          data: (merchant) => merchant.name,
          loading: () => 'Đang tải...',
          error: (_, __) => 'Cửa hàng',
        ) ?? 'Cửa hàng';

        final statusText = _getOrderStatusText(order.status);
        final isActive = order.status == OrderStatus.assigned || order.status == OrderStatus.pickedUp;
        
        // Tính khoảng cách (cần current location của driver)
        final distance = 'Đang tính...'; // TODO: Tính từ driver location đến pickup location

        return GestureDetector(
          onTap: () {
            context.push('/driver/order/${order.id}');
          },
          child: DriverOrderCard(
            orderId: '#${order.orderNumber}',
            storeName: storeName,
            address: order.pickup.address ?? order.pickup.label,
            distance: distance,
            fee: _formatPrice(order.deliveryFee),
            status: statusText,
            isActive: isActive,
            onViewDetails: () {
              context.push('/driver/order/${order.id}');
            },
          ),
        );
      },
      loading: () => _buildOrderCardSkeleton(),
      error: (_, __) => DriverOrderCard(
        orderId: '#${order.orderNumber}',
        storeName: 'Cửa hàng',
        address: order.pickup.address ?? order.pickup.label,
        distance: 'N/A',
        fee: _formatPrice(order.deliveryFee),
        status: _getOrderStatusText(order.status),
        isActive: false,
      ),
    );
  }

  Widget _buildOrderCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(width: 100, height: 16, color: AppColors.borderSoft),
              Container(width: 60, height: 20, color: AppColors.borderSoft),
            ],
          ),
          const SizedBox(height: 12),
          Container(width: 150, height: 14, color: AppColors.borderSoft),
          const SizedBox(height: 8),
          Container(width: 200, height: 12, color: AppColors.borderSoft),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          Icon(Icons.local_shipping_outlined, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'Chưa có đơn hàng',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bạn chưa được gán đơn hàng nào. Hãy bật trạng thái online để nhận đơn.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'online':
        return 'Đang hoạt động';
      case 'busy':
        return 'Đang giao hàng';
      case 'offline':
      default:
        return 'Đã tắt';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'online':
        return AppColors.success;
      case 'busy':
        return const Color(0xFFF59E0B);
      case 'offline':
      default:
        return AppColors.textSecondary;
    }
  }

  String _getOrderStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.assigned:
        return 'Chờ nhận';
      case OrderStatus.pickedUp:
        return 'Đang giao';
      case OrderStatus.completed:
        return 'Hoàn thành';
      default:
        return 'Khác';
    }
  }

  String _formatPrice(int price) {
    final formatted = price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '${formatted}đ';
  }

  String _formatEarnings(int earnings) {
    if (earnings >= 1000000) {
      return '${(earnings / 1000000).toStringAsFixed(1)}M';
    } else if (earnings >= 1000) {
      return '${(earnings / 1000).toStringAsFixed(0)}k';
    }
    return earnings.toString();
  }
}
