import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../ui/design_system.dart';
import '../../providers/app_providers.dart';
import '../../data/repositories/merchant_repository.dart';
import 'price_edit_modal.dart';
// For OrderStatus if needed, but ShopMenuItem is here

/// Merchant Price Management Screen
/// Màn quản lý giá bán: danh sách món ăn, chỉnh sửa giá, cập nhật hàng loạt.
class MerchantPriceManagementScreen extends ConsumerStatefulWidget {
  const MerchantPriceManagementScreen({super.key});

  @override
  ConsumerState<MerchantPriceManagementScreen> createState() =>
      _MerchantPriceManagementScreenState();
}

class _MerchantPriceManagementScreenState
    extends ConsumerState<MerchantPriceManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shopAsync = ref.watch(myShopProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: shopAsync.when(
          data: (shop) {
            if (shop == null) {
              return _buildNoShopState();
            }
            return _buildContent(shop.id);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorState(error.toString()),
        ),
      ),
    );
  }

  Widget _buildNoShopState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.store_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có cửa hàng',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bạn chưa được gán vào cửa hàng nào. Vui lòng liên hệ admin.',
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
              onPressed: () => ref.invalidate(myShopProvider),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(String shopId) {
    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(shopMenuProvider(shopId));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildSearchBar(),
                    const SizedBox(height: 16),
                    _buildCategoryFilter(shopId),
                    const SizedBox(height: 16),
                    _buildMenuItemList(shopId),
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
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Quản lý thực đơn',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final shop = ref.read(myShopProvider).value;
              if (shop != null) {
                context.push('/merchant/menu/add', extra: {'shopId': shop.id});
              }
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Thêm món'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
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
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Tìm kiếm món ăn...',
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
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(String shopId) {
    final menuAsync = ref.watch(shopMenuProvider(shopId));

    return menuAsync.when(
      data: (menuItems) {
        final categories =
            menuItems.map((item) => item.category ?? 'Khác').toSet().toList()
              ..sort();
        categories.insert(0, 'Tất cả');

        return SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: categories.map((category) {
              final isActive =
                  _selectedCategory == category ||
                  (_selectedCategory == null && category == 'Tất cả');
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildCategoryChip(
                  category,
                  isActive: isActive,
                  onTap: () {
                    setState(() {
                      _selectedCategory = category == 'Tất cả'
                          ? null
                          : category;
                    });
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
      loading: () => const SizedBox(height: 40),
      error: (_, _) => const SizedBox(height: 40),
    );
  }

  Widget _buildCategoryChip(
    String label, {
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.borderSoft,
          ),
          boxShadow: isActive ? AppShadows.soft(0.03) : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItemList(String shopId) {
    final menuAsync = ref.watch(shopMenuProvider(shopId));

    return menuAsync.when(
      data: (menuItems) {
        // Filter by category and search
        var filteredItems = menuItems;
        if (_selectedCategory != null) {
          filteredItems = filteredItems
              .where((item) => (item.category ?? 'Khác') == _selectedCategory)
              .toList();
        }
        if (_searchQuery.isNotEmpty) {
          filteredItems = filteredItems
              .where((item) => item.name.toLowerCase().contains(_searchQuery))
              .toList();
        }

        if (filteredItems.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          children: filteredItems.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildMenuItemCard(item, shopId),
            );
          }).toList(),
        );
      },
      loading: () => Column(
        children: List.generate(
          3,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildMenuItemCardSkeleton(),
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
                'Lỗi tải menu',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(shopMenuProvider(shopId)),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItemCard(ShopMenuItem item, String shopId) {
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.category ?? 'Khác',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: item.isAvailable,
                onChanged: (value) async {
                  try {
                    await ref
                        .read(merchantRepositoryProvider)
                        .setMenuOverride(
                          shopId: shopId,
                          productId: item.productId,
                          priceOverride: item.effectivePrice != item.basePrice
                              ? item.effectivePrice
                              : null,
                          isAvailable: value,
                        );
                    ref.invalidate(shopMenuProvider(shopId));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(value ? 'Đã bật món' : 'Đã tắt món'),
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
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.danger,
                  size: 20,
                ),
                onPressed: () => _confirmRemove(context, item, shopId),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Giá bán',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                        border: Border.all(color: AppColors.borderSoft),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _formatPrice(item.effectivePrice),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (item.effectivePrice != item.basePrice)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Đã chỉnh',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                  ),
                ),
                onPressed: () {
                  PriceEditModal.show(
                    context,
                    itemName: item.name,
                    currentPrice: item.effectivePrice.toString(),
                    onSave: (newPriceStr) async {
                      final newPrice = int.tryParse(newPriceStr);
                      if (newPrice == null || newPrice <= 0) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Giá không hợp lệ'),
                              backgroundColor: AppColors.danger,
                            ),
                          );
                        }
                        return;
                      }

                      try {
                        await ref
                            .read(merchantRepositoryProvider)
                            .setMenuOverride(
                              shopId: shopId,
                              productId: item.productId,
                              priceOverride: newPrice != item.basePrice
                                  ? newPrice
                                  : null,
                              isAvailable: item.isAvailable,
                            );
                        ref.invalidate(shopMenuProvider(shopId));
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã cập nhật giá thành công'),
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
                  );
                },
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
                label: Text(
                  'Sửa',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItemCardSkeleton() {
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 150,
                    height: 16,
                    color: AppColors.borderSoft,
                  ),
                  const SizedBox(height: 4),
                  Container(width: 80, height: 12, color: AppColors.borderSoft),
                ],
              ),
              Container(width: 40, height: 24, color: AppColors.borderSoft),
            ],
          ),
          const SizedBox(height: 16),
          Container(width: 200, height: 40, color: AppColors.borderSoft),
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
            Icons.restaurant_menu_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy món ăn',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _selectedCategory != null
                ? 'Thử thay đổi bộ lọc hoặc từ khóa tìm kiếm'
                : 'Chưa có món ăn nào trong menu',
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

  Future<void> _confirmRemove(
    BuildContext context,
    ShopMenuItem item,
    String shopId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa khỏi thực đơn?'),
        content: Text(
          'Bạn có chắc muốn xóa "${item.name}" khỏi thực đơn của quán?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(merchantRepositoryProvider)
            .removeProductFromShop(shopId: shopId, productId: item.productId);
        ref.invalidate(shopMenuProvider(shopId));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa món khỏi thực đơn')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: $e'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  String _formatPrice(int price) {
    final formatted = price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '$formattedđ';
  }
}
