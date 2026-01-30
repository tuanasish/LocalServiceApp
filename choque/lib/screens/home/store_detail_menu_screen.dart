import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../ui/design_system.dart';
import '../../ui/widgets/category_chip.dart';
import '../../ui/widgets/menu_item_card.dart';
import '../../ui/widgets/cart_summary_bar.dart';
import '../../providers/app_providers.dart';
import '../../providers/cart_provider.dart';
import '../../providers/address_provider.dart';
import '../../data/repositories/merchant_repository.dart';
import '../../data/models/merchant_model.dart';
import '../../utils/distance_utils.dart';
import 'package:geolocator/geolocator.dart';

/// Store Detail & Menu screen
/// Hiển thị thông tin cửa hàng và menu sản phẩm từ Supabase
class StoreDetailMenuScreen extends ConsumerStatefulWidget {
  final String shopId;

  const StoreDetailMenuScreen({super.key, required this.shopId});

  @override
  ConsumerState<StoreDetailMenuScreen> createState() =>
      _StoreDetailMenuScreenState();
}

class _StoreDetailMenuScreenState extends ConsumerState<StoreDetailMenuScreen> {
  String? _selectedCategory;
  String _selectedTab = 'Menu';
  double? _userLat;
  double? _userLng;
  String? _distanceToShop;
  bool _distanceCalculated = false;
  bool _isFavorite = false;
  bool _isTogglingFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  Future<void> _loadUserLocation() async {
    // Lấy user location từ saved address hoặc current location
    final addressesAsync = ref.read(userAddressesProvider);
    addressesAsync.whenData((addresses) {
      if (addresses.isEmpty) return;
      final defaultAddress = addresses.firstWhere(
        (a) => a.isDefault,
        orElse: () => addresses.first,
      );
      if (defaultAddress.lat != null && defaultAddress.lng != null) {
        setState(() {
          _userLat = defaultAddress.lat;
          _userLng = defaultAddress.lng;
        });
      }
    });

    // Nếu không có từ address, thử lấy current location
    if (_userLat == null || _userLng == null) {
      try {
        final position = await Geolocator.getCurrentPosition();
        setState(() {
          _userLat = position.latitude;
          _userLng = position.longitude;
        });
      } catch (e) {
        // Ignore location error
      }
    }
  }

  /// Tính khoảng cách từ user đến shop - chỉ gọi 1 lần khi có đủ data
  void _calculateDistanceOnce(MerchantModel merchant) {
    if (_distanceCalculated) return;
    if (_userLat == null || _userLng == null) return;
    if (merchant.lat == null || merchant.lng == null) return;

    _distanceCalculated = true;
    final distanceInMeters = DistanceUtils.calculateDistance(
      _userLat!,
      _userLng!,
      merchant.lat!,
      merchant.lng!,
    );
    // Dùng Future.microtask để tránh setState trong build
    Future.microtask(() {
      if (mounted) {
        setState(() {
          _distanceToShop = DistanceUtils.formatDistance(distanceInMeters);
        });
      }
    });
  }

  Future<void> _toggleFavorite() async {
    if (_isTogglingFavorite) return;

    final user = ref.read(currentUserProvider).asData?.value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để lưu yêu thích')),
      );
      return;
    }

    setState(() => _isTogglingFavorite = true);
    try {
      final repo = ref.read(favoriteRepositoryProvider);
      await repo.toggleFavorite(widget.shopId, !_isFavorite);
      setState(() => _isFavorite = !_isFavorite);
      // Invalidate providers
      ref.invalidate(myFavoritesProvider);
      ref.invalidate(isFavoriteProvider(widget.shopId));
    } catch (e) {
      if (mounted) {
        if (context.canPop()) {
          context.pop();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      setState(() => _isTogglingFavorite = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItemCount = ref.watch(cartItemCountProvider);
    final cartTotal = ref.watch(cartTotalProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            Consumer(
              builder: (context, ref, child) {
                final isFavAsync = ref.watch(isFavoriteProvider(widget.shopId));
                _isFavorite = isFavAsync.value ?? false;

                return AppSimpleHeader(
                  title: 'Chi tiết cửa hàng',
                  actions: [
                    IconButton(
                      icon: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite ? Colors.red : AppColors.textPrimary,
                      ),
                      onPressed: _toggleFavorite,
                    ),
                  ],
                );
              },
            ),
            Expanded(
              // Tách merchant và menu thành các Consumer riêng biệt
              child: _MerchantContentConsumer(
                shopId: widget.shopId,
                selectedCategory: _selectedCategory,
                selectedTab: _selectedTab,
                distanceToShop: _distanceToShop,
                onCategorySelected: (cat) =>
                    setState(() => _selectedCategory = cat),
                onTabSelected: (tab) => setState(() => _selectedTab = tab),
                onMerchantLoaded: _calculateDistanceOnce,
                onRefresh: () {
                  ref.invalidate(merchantDetailProvider(widget.shopId));
                  ref.invalidate(shopMenuProvider(widget.shopId));
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: cartItemCount > 0
          ? CartSummaryBar(
              itemCount: cartItemCount,
              totalPrice: _formatPrice(cartTotal),
              subtitle: 'Chưa bao gồm phí giao hàng',
              onViewCartTap: () => context.push('/checkout'),
            )
          : null,
    );
  }

  String _formatPrice(int price) {
    final formatted = price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '$formattedđ';
  }
}

/// Consumer widget riêng để watch merchant và menu providers
/// Tách ra để tránh nested AsyncValue.when() và cải thiện performance
class _MerchantContentConsumer extends ConsumerWidget {
  final String shopId;
  final String? selectedCategory;
  final String selectedTab;
  final String? distanceToShop;
  final void Function(String?) onCategorySelected;
  final void Function(String) onTabSelected;
  final void Function(MerchantModel) onMerchantLoaded;
  final VoidCallback onRefresh;

  const _MerchantContentConsumer({
    required this.shopId,
    required this.selectedCategory,
    required this.selectedTab,
    required this.distanceToShop,
    required this.onCategorySelected,
    required this.onTabSelected,
    required this.onMerchantLoaded,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final merchantAsync = ref.watch(merchantDetailProvider(shopId));

    return merchantAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _MerchantErrorWidget(
        message: 'Không thể tải thông tin cửa hàng',
        onRetry: onRefresh,
      ),
      data: (merchant) {
        // Callback để tính khoảng cách (chỉ gọi 1 lần nhờ flag ở parent)
        onMerchantLoaded(merchant);

        // Menu content là Consumer widget riêng
        return _MenuContentConsumer(
          shopId: shopId,
          merchant: merchant,
          selectedCategory: selectedCategory,
          selectedTab: selectedTab,
          distanceToShop: distanceToShop,
          onCategorySelected: onCategorySelected,
          onTabSelected: onTabSelected,
          onRefresh: onRefresh,
        );
      },
    );
  }
}

/// Consumer widget riêng để watch menu provider
/// Chỉ rebuild khi menu thay đổi, không rebuild khi merchant thay đổi
class _MenuContentConsumer extends ConsumerWidget {
  final String shopId;
  final MerchantModel merchant;
  final String? selectedCategory;
  final String selectedTab;
  final String? distanceToShop;
  final void Function(String?) onCategorySelected;
  final void Function(String) onTabSelected;
  final VoidCallback onRefresh;

  const _MenuContentConsumer({
    required this.shopId,
    required this.merchant,
    required this.selectedCategory,
    required this.selectedTab,
    required this.distanceToShop,
    required this.onCategorySelected,
    required this.onTabSelected,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuAsync = ref.watch(shopMenuProvider(shopId));

    return menuAsync.when(
      loading: () => _buildLoadingWithMerchant(context),
      error: (error, stack) => _MerchantErrorWidget(
        message: 'Không thể tải menu',
        onRetry: onRefresh,
      ),
      data: (menuItems) => _buildContent(context, ref, menuItems),
    );
  }

  Widget _buildLoadingWithMerchant(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StoreInfoWidget(merchant: merchant, distanceToShop: distanceToShop),
          const SizedBox(height: 16),
          _TabsWidget(selectedTab: selectedTab, onTabSelected: onTabSelected),
          const SizedBox(height: 24),
          const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<ShopMenuItem> menuItems,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StoreInfoWidget(merchant: merchant, distanceToShop: distanceToShop),
          const SizedBox(height: 16),
          _TabsWidget(selectedTab: selectedTab, onTabSelected: onTabSelected),
          const SizedBox(height: 16),
          if (selectedTab == 'Menu')
            _MenuTabContent(
              merchant: merchant,
              menuItems: menuItems,
              selectedCategory: selectedCategory,
              onCategorySelected: onCategorySelected,
            )
          else if (selectedTab == 'Đánh giá')
            _ReviewsTabContent(merchant: merchant)
          else if (selectedTab == 'Thông tin')
            _InfoTabContent(merchant: merchant),
          const SizedBox(height: 100), // space for bottom bar
        ],
      ),
    );
  }
}

/// Widget hiển thị error với nút retry
class _MerchantErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _MerchantErrorWidget({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(message, style: AppTextStyles.body15Secondary),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}

/// Widget hiển thị thông tin cửa hàng
class _StoreInfoWidget extends StatelessWidget {
  final MerchantModel merchant;
  final String? distanceToShop;

  const _StoreInfoWidget({required this.merchant, this.distanceToShop});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        boxShadow: AppShadows.soft(0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(merchant.name, style: AppTextStyles.heading20),
          const SizedBox(height: 8),
          Row(
            children: [
              if (merchant.rating != null) ...[
                const Icon(Icons.star, size: 16, color: Color(0xFFFACC15)),
                const SizedBox(width: 4),
                Text(
                  merchant.rating!.toStringAsFixed(1),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else ...[
                Text(
                  'Chưa có đánh giá',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (merchant.rating != null &&
                  (merchant.openingHours != null ||
                      distanceToShop != null)) ...[
                const SizedBox(width: 6),
                const Text('•'),
              ],
              if (merchant.openingHours != null) ...[
                const SizedBox(width: 6),
                Text(
                  merchant.openingHours!,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (distanceToShop != null) ...[
                if (merchant.rating != null ||
                    merchant.openingHours != null) ...[
                  const SizedBox(width: 6),
                  const Text('•'),
                ],
                const SizedBox(width: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.near_me,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      distanceToShop!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          if (merchant.address != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    merchant.address!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _buildContactButton(
                icon: Icons.chat_bubble_outline,
                label: 'Liên hệ',
                onTap: () {
                  if (merchant.phone != null) {
                    // TODO: Mở Zalo hoặc gọi điện
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2FE),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF0369A1)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0369A1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget tabs Menu/Đánh giá/Thông tin
class _TabsWidget extends StatelessWidget {
  final String selectedTab;
  final void Function(String) onTabSelected;

  const _TabsWidget({required this.selectedTab, required this.onTabSelected});

  @override
  Widget build(BuildContext context) {
    final tabs = ['Menu', 'Đánh giá', 'Thông tin'];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: tabs.map((label) {
          final isActive = label == selectedTab;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTabSelected(label),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive
                        ? const Color(0xFF0F172A)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Widget nội dung tab Menu
class _MenuTabContent extends ConsumerWidget {
  final MerchantModel merchant;
  final List<ShopMenuItem> menuItems;
  final String? selectedCategory;
  final void Function(String?) onCategorySelected;

  const _MenuTabContent({
    required this.merchant,
    required this.menuItems,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Lấy danh sách categories từ menu
    final categories = menuItems
        .map((item) => item.category ?? 'Khác')
        .toSet()
        .toList();

    // Lọc menu theo category đã chọn
    final filteredItems = selectedCategory == null
        ? menuItems
        : menuItems
              .where((item) => (item.category ?? 'Khác') == selectedCategory)
              .toList();

    // Nhóm theo category để hiển thị
    final groupedItems = <String, List<ShopMenuItem>>{};
    for (final item in filteredItems) {
      final cat = item.category ?? 'Khác';
      groupedItems.putIfAbsent(cat, () => []).add(item);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCategoryChips(categories),
        const SizedBox(height: 24),
        if (filteredItems.isEmpty)
          _buildEmptyMenu()
        else
          ...groupedItems.entries.expand(
            (entry) => [
              _buildSectionTitle(entry.key),
              const SizedBox(height: 12),
              ...entry.value.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _MenuItemWidget(merchant: merchant, item: item),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
      ],
    );
  }

  Widget _buildCategoryChips(List<String> categories) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          CategoryChip(
            label: 'Tất cả',
            isActive: selectedCategory == null,
            onTap: () => onCategorySelected(null),
          ),
          const SizedBox(width: 8),
          ...categories.map(
            (category) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CategoryChip(
                label: category,
                isActive: selectedCategory == category,
                onTap: () => onCategorySelected(category),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMenu() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text('Chưa có sản phẩm nào', style: AppTextStyles.body15Secondary),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0F172A),
        ),
      ),
    );
  }
}

/// Widget hiển thị menu item với logic thêm giỏ hàng
class _MenuItemWidget extends ConsumerWidget {
  final MerchantModel merchant;
  final ShopMenuItem item;

  const _MenuItemWidget({required this.merchant, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MenuItemCard(
      name: item.name,
      description: item.description ?? '',
      price: _formatPrice(item.effectivePrice),
      onAddTap: () {
        final cart = ref.read(cartProvider.notifier);
        if (cart.hasItemsFromOtherShop(item.shopId)) {
          _showClearCartDialog(context, ref);
        } else {
          _addToCart(context, ref);
        }
      },
    );
  }

  void _addToCart(BuildContext context, WidgetRef ref) {
    ref
        .read(cartProvider.notifier)
        .addItem(
          CartItem(
            id: item.productId,
            shopId: item.shopId,
            shopName: merchant.name,
            name: item.name,
            description: item.description,
            imageUrl: item.imagePath,
            price: item.effectivePrice,
          ),
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text('Đã thêm ${item.name} vào giỏ hàng')),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.success,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showClearCartDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa giỏ hàng?'),
        content: const Text(
          'Giỏ hàng của bạn đang có sản phẩm từ cửa hàng khác. '
          'Bạn muốn xóa và thêm sản phẩm mới?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(cartProvider.notifier).clear();
              _addToCart(context, ref);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Xóa và thêm'),
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
}

/// Widget tab đánh giá
class _ReviewsTabContent extends ConsumerWidget {
  final MerchantModel merchant;

  const _ReviewsTabContent({required this.merchant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(shopReviewsProvider(merchant.id));

    return reviewsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Lỗi: $err')),
      data: (reviews) {
        if (reviews.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.star_outline,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có đánh giá',
                    style: AppTextStyles.body15Secondary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Trở thành người đầu tiên đánh giá cửa hàng này',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: reviews.length,
          separatorBuilder: (_, _) => const Divider(height: 24),
          itemBuilder: (context, index) {
            final review = reviews[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      backgroundImage: review.userAvatar != null
                          ? NetworkImage(review.userAvatar!)
                          : null,
                      child: review.userAvatar == null
                          ? Text(
                              (review.isAnonymous
                                      ? 'A'
                                      : (review.userName?[0] ?? 'U'))
                                  .toUpperCase(),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            review.isAnonymous
                                ? 'Người dùng ẩn danh'
                                : (review.userName ?? 'Người dùng Chợ Quê'),
                            style: AppTextStyles.label14,
                          ),
                          Text(
                            _formatDate(review.createdAt),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          Icons.star,
                          size: 14,
                          color: i < review.rating
                              ? Colors.amber
                              : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  ],
                ),
                if (review.comment != null && review.comment!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(review.comment!, style: AppTextStyles.body13),
                ],
              ],
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Widget tab thông tin
class _InfoTabContent extends StatelessWidget {
  final MerchantModel merchant;

  const _InfoTabContent({required this.merchant});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (merchant.address != null) ...[
            _buildInfoRow(
              icon: Icons.location_on_outlined,
              label: 'Địa chỉ',
              value: merchant.address!,
            ),
            const SizedBox(height: 16),
          ],
          if (merchant.phone != null) ...[
            _buildInfoRow(
              icon: Icons.phone_outlined,
              label: 'Số điện thoại',
              value: merchant.phone!,
            ),
            const SizedBox(height: 16),
          ],
          if (merchant.openingHours != null) ...[
            _buildInfoRow(
              icon: Icons.access_time,
              label: 'Giờ mở cửa',
              value: merchant.openingHours!,
            ),
            const SizedBox(height: 16),
          ],
          if (merchant.rating != null) ...[
            _buildInfoRow(
              icon: Icons.star,
              label: 'Đánh giá',
              value: '${merchant.rating!.toStringAsFixed(1)}/5.0',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(value, style: AppTextStyles.body15Secondary),
            ],
          ),
        ),
      ],
    );
  }
}
