import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../ui/design_system.dart';
import '../../ui/widgets/driver_recent_order_card.dart';
import '../../ui/widgets/driver_bottom_nav_bar.dart';
import '../../ui/widgets/notification_badge.dart';
import '../../providers/app_providers.dart';
import '../../data/models/order_model.dart';

/// Driver Home Dashboard Screen
/// Màn chính cho tài xế: thống kê, đơn hàng đang chờ, trạng thái online/offline.
class DriverHomeDashboardScreen extends ConsumerStatefulWidget {
  const DriverHomeDashboardScreen({super.key});

  @override
  ConsumerState<DriverHomeDashboardScreen> createState() =>
      _DriverHomeDashboardScreenState();
}

class _DriverHomeDashboardScreenState
    extends ConsumerState<DriverHomeDashboardScreen> {
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
          _isOnline =
              profile!.driverStatus == 'online' ||
              profile.driverStatus == 'busy';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);

    return profileAsync.when(
      data: (profile) {
        if (profile == null || !profile.isDriver) {
          return Scaffold(
            backgroundColor: AppColors.backgroundLight,
            body: SafeArea(child: _buildNotDriverState()),
          );
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
      loading: () => Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: const SafeArea(child: Center(child: CircularProgressIndicator())),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: SafeArea(child: _buildErrorState(error.toString())),
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
            Icon(
              Icons.drive_eta_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
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
    final profileAsync = ref.watch(currentProfileProvider);
    final marketId = profileAsync.value?.marketId ?? 'default';
    
    return Scaffold(
      backgroundColor: AppColors.driverBackgroundLight,
      body: SafeArea(
        child: Column(
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
                        _buildOnlineStatusCard(driverStatus),
                        const SizedBox(height: 16),
                        _buildStatsCards(marketId),
                        const SizedBox(height: 20),
                        _buildSectionTitle(
                          'Đơn hàng gần đây',
                          actionLabel: 'Xem tất cả',
                          onActionPressed: () => context.push('/driver/requests'),
                        ),
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
        ),
      ),
      bottomNavigationBar: DriverBottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          // TODO: Navigate to different screens
        },
      ),
    );
  }

  Widget _buildHeader(String driverName, String driverStatus) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderSoft,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.borderSoft,
                width: 1,
              ),
            ),
            child: _buildAvatarPlaceholder(),
          ),
          const SizedBox(width: 12),
          // Title centered
          Expanded(
            child: Text(
              'Trang chủ',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Notification badge
          NotificationBadge(
            onTap: () => context.push('/driver/notifications'),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.1),
      child: const Icon(
        Icons.person,
        color: AppColors.primary,
        size: 24,
      ),
    );
  }

  Widget _buildOnlineStatusCard(String driverStatus) {
    final isOnline = driverStatus == 'online' || driverStatus == 'busy';
    final isBusy = driverStatus == 'busy';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: AppShadows.soft(0.04),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bạn đang trực tuyến',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isBusy
                      ? 'Đang có đơn hàng'
                      : isOnline
                      ? 'Sẵn sàng nhận đơn hàng mới'
                      : 'Tắt để không nhận đơn',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.driverTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isOnline,
            onChanged: isBusy
                ? null
                : (value) async {
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
                            content: Text(
                              value
                                  ? 'Đã bật trạng thái online'
                                  : 'Đã tắt trạng thái',
                            ),
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

  Widget _buildStatsCards(String marketId) {
    final statsAsync = ref.watch(driverStatsProvider);
    
    // Map marketId to display name (simplified)
    String getMarketName(String id) {
      if (id.contains('quan_1') || id.contains('district_1')) {
        return 'Quận 1, TP.HCM';
      }
      return 'Khu vực hoạt động';
    }

    return statsAsync.when(
      data: (stats) {
        final todayEarnings = stats['today_earnings'] as int? ?? 0;

        return Row(
          children: [
            Expanded(
              child: _buildStatCardHorizontal(
                icon: Icons.location_on,
                label: 'Khu vực',
                value: getMarketName(marketId),
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCardHorizontal(
                icon: Icons.payments,
                label: 'Thu nhập',
                value: _formatEarnings(todayEarnings),
                color: AppColors.primary,
              ),
            ),
          ],
        );
      },
      loading: () => Row(
        children: [
          Expanded(child: _buildStatCardSkeleton()),
          const SizedBox(width: 16),
          Expanded(child: _buildStatCardSkeleton()),
        ],
      ),
      error: (e, st) => const SizedBox(),
    );
  }

  Widget _buildStatCardHorizontal({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(
          color: AppColors.borderSoft,
          width: 1,
        ),
        boxShadow: AppShadows.soft(0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.driverTextSecondary),
              const SizedBox(width: 6),
              Text(
                label.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.driverTextSecondary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color == AppColors.primary
                  ? AppColors.primary
                  : AppColors.textPrimary,
            ),
          ),
        ],
      ),
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


  Widget _buildSectionTitle(
    String title, {
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.heading18),
        if (actionLabel != null && onActionPressed != null)
          TextButton(
            onPressed: onActionPressed,
            child: Text(
              actionLabel,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
      ],
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
        children: List.generate(
          2,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildOrderCardSkeleton(),
          ),
        ),
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
        final storeName =
            merchantAsync?.when(
              data: (merchant) => merchant.name,
              loading: () => 'Đang tải...',
              error: (e, st) => 'Cửa hàng',
            ) ??
            'Cửa hàng';

        // Store image URL - MerchantModel doesn't have imageUrl field
        // Will use placeholder in widget
        final isExpired = order.status == OrderStatus.canceled ||
            order.status == OrderStatus.completed;

        // Tính khoảng cách (cần current location của driver)
        final distance =
            'Đang tính...'; // TODO: Tính từ driver location đến pickup location

        return DriverRecentOrderCard(
          storeName: storeName,
          storeImageUrl: null, // MerchantModel doesn't have imageUrl
          distance: distance,
          fee: _formatPrice(order.deliveryFee),
          isExpired: isExpired,
          onViewDetails: () {
            context.push('/driver/order/${order.id}');
          },
          onAccept: () async {
            try {
              await ref.read(driverRepositoryProvider).acceptOrder(order.id);
              if (mounted) {
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
              }
            }
          },
        );
      },
      loading: () => _buildOrderCardSkeleton(),
      error: (e, st) => DriverRecentOrderCard(
        storeName: 'Cửa hàng',
        distance: 'N/A',
        fee: _formatPrice(order.deliveryFee),
        isExpired: true,
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
          Icon(
            Icons.local_shipping_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
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

  String _formatPrice(int price) {
    final formatted = price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '$formattedđ';
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
