import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/repositories/merchant_repository.dart';
import '../../providers/admin_merchant_provider.dart';
import '../../ui/design_system.dart';

/// Admin Merchant List Screen
/// Danh sách cửa hàng cho admin: xem, duyệt, quản lý trạng thái cửa hàng.
class AdminMerchantListScreen extends ConsumerStatefulWidget {
  const AdminMerchantListScreen({super.key});

  @override
  ConsumerState<AdminMerchantListScreen> createState() =>
      _AdminMerchantListScreenState();
}

class _AdminMerchantListScreenState
    extends ConsumerState<AdminMerchantListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Listener callback để có thể remove trong dispose
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<AdminMerchantInfo> _filterMerchants(List<AdminMerchantInfo> merchants) {
    if (_searchQuery.isEmpty) return merchants;
    return merchants.where((m) {
      return m.name.toLowerCase().contains(_searchQuery) ||
          (m.ownerName?.toLowerCase().contains(_searchQuery) ?? false) ||
          (m.phone?.contains(_searchQuery) ?? false);
    }).toList();
  }

  Future<void> _onApprove(AdminMerchantInfo merchant) async {
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
  }

  Future<void> _onReject(AdminMerchantInfo merchant) async {
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
  }

  @override
  Widget build(BuildContext context) {
    final allMerchants = ref.watch(allAdminMerchantsProvider);
    final pendingMerchants = ref.watch(pendingMerchantsProvider);
    final activeMerchants = ref.watch(activeMerchantsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  invalidateAdminMerchantProviders(ref);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildStatsRow(
                          allMerchants,
                          pendingMerchants,
                          activeMerchants,
                        ),
                        const SizedBox(height: 16),
                        _buildSearchBar(),
                        const SizedBox(height: 16),
                        _buildFilterTabs(pendingMerchants),
                        const SizedBox(height: 16),
                        _buildMerchantListContent(
                          allMerchants,
                          pendingMerchants,
                          activeMerchants,
                        ),
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
    );
  }

  Widget _buildHeader(BuildContext context) {
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
              'Quản lý cửa hàng',
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

  Widget _buildStatsRow(
    AsyncValue<List<AdminMerchantInfo>> allMerchants,
    AsyncValue<List<AdminMerchantInfo>> pendingMerchants,
    AsyncValue<List<AdminMerchantInfo>> activeMerchants,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildStatBox(
            label: 'Tổng cửa hàng',
            value: allMerchants.when(
              data: (list) => list.length.toString(),
              loading: () => '-',
              error: (e, s) => '!',
            ),
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatBox(
            label: 'Chờ duyệt',
            value: pendingMerchants.when(
              data: (list) => list.length.toString(),
              loading: () => '-',
              error: (e, s) => '!',
            ),
            color: const Color(0xFFF59E0B),
            badge: pendingMerchants.maybeWhen(
              data: (list) => list.isNotEmpty,
              orElse: () => false,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatBox(
            label: 'Đang hoạt động',
            value: activeMerchants.when(
              data: (list) => list.length.toString(),
              loading: () => '-',
              error: (e, s) => '!',
            ),
            color: AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildStatBox({
    required String label,
    required String value,
    required Color color,
    bool badge = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        boxShadow: AppShadows.soft(0.03),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              if (badge) ...[
                const SizedBox(width: 4),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        boxShadow: AppShadows.soft(0.03),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm cửa hàng...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
                border: InputBorder.none,
              ),
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, size: 18),
              onPressed: () => _searchController.clear(),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(AsyncValue<List<AdminMerchantInfo>> pendingMerchants) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        boxShadow: AppShadows.soft(0.03),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        tabs: [
          const Tab(text: 'Tất cả'),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Chờ duyệt'),
                pendingMerchants.maybeWhen(
                  data: (list) {
                    if (list.isEmpty) return const SizedBox.shrink();
                    return Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _tabController.index == 1
                            ? Colors.white.withValues(alpha: 0.2)
                            : AppColors.danger,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        list.length.toString(),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _tabController.index == 1
                              ? Colors.white
                              : Colors.white,
                        ),
                      ),
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const Tab(text: 'Hoạt động'),
        ],
        onTap: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildMerchantListContent(
    AsyncValue<List<AdminMerchantInfo>> allMerchants,
    AsyncValue<List<AdminMerchantInfo>> pendingMerchants,
    AsyncValue<List<AdminMerchantInfo>> activeMerchants,
  ) {
    final currentData = switch (_tabController.index) {
      0 => allMerchants,
      1 => pendingMerchants,
      2 => activeMerchants,
      _ => allMerchants,
    };

    return currentData.when(
      data: (merchants) {
        final filtered = _filterMerchants(merchants);
        if (filtered.isEmpty) {
          return _buildEmptyState();
        }
        return Column(
          children: filtered.map((merchant) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildMerchantCard(merchant),
            );
          }).toList(),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Lỗi: ${error.toString()}',
            style: GoogleFonts.inter(color: AppColors.danger),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.store_outlined,
            size: 64,
            color: AppColors.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'Không tìm thấy cửa hàng'
                : 'Chưa có cửa hàng nào',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMerchantCard(AdminMerchantInfo merchant) {
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

    return GestureDetector(
      onTap: () => context.push('/admin/merchants/${merchant.id}'),
      child: Container(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                    image: merchant.imageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(merchant.imageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: merchant.imageUrl == null
                      ? const Icon(
                          Icons.store,
                          color: AppColors.primary,
                          size: 28,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              merchant.name,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(
                              statusDisplayName,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (merchant.ownerName != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.person_outline,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              merchant.ownerName!,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      if (merchant.address != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                merchant.address!,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.star_outline,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Đánh giá: ${merchant.rating?.toStringAsFixed(1) ?? '-'}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.receipt_long_outlined,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${merchant.orderCount} đơn',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (merchant.status == 'pending')
                  Row(
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.danger),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                        onPressed: () => _onReject(merchant),
                        child: Text(
                          'Từ chối',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                        onPressed: () => _onApprove(merchant),
                        child: Text(
                          'Duyệt',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
