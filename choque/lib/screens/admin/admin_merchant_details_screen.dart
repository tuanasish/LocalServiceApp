import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/repositories/merchant_repository.dart';
import '../../providers/admin_merchant_provider.dart';
import '../../ui/design_system.dart';

/// Admin Merchant Details Screen
/// Chi tiết cửa hàng cho admin: thông tin đầy đủ, duyệt/từ chối, quản lý trạng thái.
class AdminMerchantDetailsScreen extends ConsumerStatefulWidget {
  final String shopId;

  const AdminMerchantDetailsScreen({super.key, required this.shopId});

  @override
  ConsumerState<AdminMerchantDetailsScreen> createState() =>
      _AdminMerchantDetailsScreenState();
}

class _AdminMerchantDetailsScreenState
    extends ConsumerState<AdminMerchantDetailsScreen> {
  bool _isLoading = false;

  Future<void> _onApprove() async {
    final allMerchants = await ref.read(allAdminMerchantsProvider.future);
    if (!mounted) return;
    final merchant = allMerchants.where((m) => m.id == widget.shopId).firstOrNull;
    if (merchant == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Duyệt cửa hàng',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Bạn có chắc chắn muốn duyệt cửa hàng "${merchant.name}"?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Hủy',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Duyệt',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      try {
        final repo = ref.read(merchantRepositoryProvider);
        await repo.approveMerchant(merchant.id);
        invalidateAdminMerchantProviders(ref);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã duyệt cửa hàng "${merchant.name}"'),
              backgroundColor: AppColors.success,
            ),
          );
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/admin/merchants');
          }
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
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onReject() async {
    final allMerchants = await ref.read(allAdminMerchantsProvider.future);
    if (!mounted) return;
    final merchant = allMerchants.where((m) => m.id == widget.shopId).firstOrNull;
    if (merchant == null) return;

    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Từ chối cửa hàng',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nhập lý do từ chối cửa hàng "${merchant.name}":',
              style: GoogleFonts.inter(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Lý do từ chối...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Hủy',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Từ chối',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      try {
        final repo = ref.read(merchantRepositoryProvider);
        await repo.rejectMerchant(merchant.id, reasonController.text);
        invalidateAdminMerchantProviders(ref);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã từ chối cửa hàng "${merchant.name}"'),
              backgroundColor: AppColors.danger,
            ),
          );
          context.pop();
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
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _callPhone(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final merchantAsync = ref.watch(merchantDetailProvider(widget.shopId));
    final statsAsync = ref.watch(merchantStatsProvider(widget.shopId));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: merchantAsync.when(
                    data: (merchant) {
                      if (merchant == null) {
                        return const Center(
                          child: Text('Không tìm thấy cửa hàng'),
                        );
                      }
                      return SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              _buildMerchantHeader(merchant, statsAsync),
                              const SizedBox(height: 20),
                              _buildStatusCard(merchant),
                              const SizedBox(height: 20),
                              _buildOwnerInfo(merchant),
                              const SizedBox(height: 20),
                              _buildStoreInfo(merchant),
                              const SizedBox(height: 20),
                              _buildStatsCard(statsAsync),
                              const SizedBox(height: 20),
                              _buildActionButtons(merchant),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (error, _) => Center(
                      child: Text('Lỗi: ${error.toString()}'),
                    ),
                  ),
                ),
              ],
            ),
            if (_isLoading)
              Container(
                color: Colors.black26,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 8),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.store,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Chi tiết cửa hàng',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMerchantHeader(
    AdminMerchantInfo merchant,
    AsyncValue<AdminMerchantStats> statsAsync,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        boxShadow: AppShadows.soft(0.04),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.large),
              image: merchant.imageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(merchant.imageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: merchant.imageUrl == null
                ? const Icon(Icons.store, color: AppColors.primary, size: 40)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  merchant.name,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 4),
                    Text(
                      merchant.rating?.toStringAsFixed(1) ?? '-',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '•',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${merchant.orderCount} đơn',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(AdminMerchantInfo merchant) {
    final statusDisplayName = switch (merchant.status) {
      'active' => 'Đang hoạt động',
      'pending' => 'Chờ duyệt',
      'rejected' => 'Đã từ chối',
      'inactive' => 'Tạm ngưng',
      _ => merchant.status,
    };

    final statusColor = switch (merchant.status) {
      'active' => AppColors.success,
      'pending' => const Color(0xFFF59E0B),
      'rejected' => AppColors.danger,
      _ => AppColors.textSecondary,
    };

    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        boxShadow: AppShadows.soft(0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Trạng thái', style: AppTextStyles.label14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  statusDisplayName,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatusItem(
                  icon: Icons.calendar_today_outlined,
                  label: 'Ngày đăng ký',
                  value: dateFormat.format(merchant.createdAt),
                ),
              ),
              Expanded(
                child: _buildStatusItem(
                  icon: Icons.verified_outlined,
                  label: 'Xác thực',
                  value: merchant.status == 'active'
                      ? 'Đã duyệt'
                      : (merchant.status == 'pending' ? 'Chờ duyệt' : 'Đã từ chối'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildOwnerInfo(AdminMerchantInfo merchant) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        boxShadow: AppShadows.soft(0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.person_outline,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text('Thông tin chủ cửa hàng', style: AppTextStyles.label14),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            merchant.ownerName ?? 'Chưa có thông tin',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (merchant.ownerPhone != null) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _callPhone(merchant.ownerPhone),
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: merchant.ownerPhone!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã sao chép số điện thoại')),
                );
              },
              child: Row(
                children: [
                  const Icon(
                    Icons.phone_outlined,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    merchant.ownerPhone!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStoreInfo(AdminMerchantInfo merchant) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        boxShadow: AppShadows.soft(0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.store_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text('Thông tin cửa hàng', style: AppTextStyles.label14),
            ],
          ),
          const SizedBox(height: 12),
          if (merchant.address != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    merchant.address!,
                    style: AppTextStyles.body13Secondary,
                  ),
                ),
              ],
            ),
          if (merchant.phone != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _callPhone(merchant.phone),
              child: Row(
                children: [
                  const Icon(
                    Icons.phone_outlined,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    merchant.phone!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsCard(AsyncValue<AdminMerchantStats> statsAsync) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        boxShadow: AppShadows.soft(0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Thống kê', style: AppTextStyles.heading18),
          const SizedBox(height: 16),
          statsAsync.when(
            data: (stats) {
              final revenueFormatted = _formatCurrency(stats.totalRevenue);
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          icon: Icons.receipt_long_outlined,
                          label: 'Tổng đơn',
                          value: stats.totalOrders.toString(),
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          icon: Icons.attach_money_outlined,
                          label: 'Doanh thu',
                          value: revenueFormatted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          icon: Icons.check_circle_outline,
                          label: 'Hoàn thành',
                          value: stats.completedOrders.toString(),
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          icon: Icons.restaurant_menu,
                          label: 'Sản phẩm',
                          value: stats.productsCount.toString(),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => Center(
              child: Text(
                'Lỗi tải thống kê',
                style: GoogleFonts.inter(color: AppColors.danger),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(int amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)}B';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toString();
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24, color: AppColors.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(AdminMerchantInfo merchant) {
    // Only show action buttons for pending merchants
    if (merchant.status != 'pending') {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            onPressed: _isLoading ? null : _onApprove,
            icon: const Icon(Icons.check_circle_outline, color: Colors.white),
            label: Text(
              'Duyệt cửa hàng',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: AppColors.danger),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            onPressed: _isLoading ? null : _onReject,
            icon: const Icon(Icons.close, color: AppColors.danger),
            label: Text(
              'Từ chối cửa hàng',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.danger,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
