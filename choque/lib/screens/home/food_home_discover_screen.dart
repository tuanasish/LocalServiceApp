import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/design_system.dart';
import '../../ui/widgets/app_search_bar.dart';
import '../../providers/app_providers.dart';
import '../../providers/address_provider.dart';
import '../../models/user_address.dart';
import '../../data/models/product_model.dart';
import '../../data/models/merchant_model.dart';

/// Food Home - Discover screen
/// Hiển thị danh sách cửa hàng, tìm kiếm món ăn và lọc theo danh mục.
class FoodHomeDiscoverScreen extends ConsumerStatefulWidget {
  const FoodHomeDiscoverScreen({super.key});

  @override
  ConsumerState<FoodHomeDiscoverScreen> createState() => _FoodHomeDiscoverScreenState();
}

class _FoodHomeDiscoverScreenState extends ConsumerState<FoodHomeDiscoverScreen> {
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(productCategoriesProvider);
    final userProfile = ref.watch(currentProfileProvider).value;
    
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, userProfile),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(productCategoriesProvider);
                  ref.invalidate(merchantsProvider);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      _buildCategorySection(categoriesAsync),
                      
                      if (_searchQuery.isNotEmpty)
                        _buildSearchResultsSection()
                      else if (_selectedCategory != null)
                        _buildCategoryProductsSection()
                      else ...[
                        const SizedBox(height: 12),
                        const _SortFilters(),
                        const SizedBox(height: 16),
                        const _FeaturedStoresSection(),
                      ],
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic profile) {
    final addressesAsync = ref.watch(userAddressesProvider);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.primary, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: addressesAsync.when(
                  data: (addresses) {
                    UserAddress? defaultAddress;
                    if (addresses.isNotEmpty) {
                      try {
                        defaultAddress = addresses.firstWhere((a) => a.isDefault);
                      } catch (e) {
                        defaultAddress = addresses.first;
                      }
                    }
                    
                    final displayAddress = defaultAddress?.details ?? 
                                         defaultAddress?.fullDisplayAddress ?? 
                                         'Chưa có địa chỉ';
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GIAO ĐẾN',
                          style: GoogleFonts.inter(
                            color: Colors.grey[600],
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          displayAddress,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF0F172A),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    );
                  },
                  loading: () => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GIAO ĐẾN',
                        style: GoogleFonts.inter(
                          color: Colors.grey[600],
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ],
                  ),
                  error: (_, __) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GIAO ĐẾN',
                        style: GoogleFonts.inter(
                          color: Colors.grey[600],
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Chưa có địa chỉ',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF0F172A),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              _buildTappableCircleIcon(
                icon: Icons.notifications_none,
                onTap: () => context.push('/notifications'),
              ),
              const SizedBox(width: 12),
              _buildTappableCircleIcon(
                icon: Icons.shopping_bag_outlined,
                onTap: () => context.push('/checkout'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => context.push('/search'),
            child: AppSearchBar(
              hintText: 'Tìm món ăn, nhà hàng…',
              onChanged: null, // Disable inline search, navigate to unified search
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTappableCircleIcon({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.1),
              AppColors.primary.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
    );
  }

  Widget _buildCategorySection(AsyncValue<List<String>> categoriesAsync) {
    return categoriesAsync.when(
      data: (categories) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _buildCategoryChip(
              label: 'Tất cả',
              icon: Icons.auto_awesome_mosaic,
              isSelected: _selectedCategory == null,
              onTap: () => setState(() => _selectedCategory = null),
            ),
            ...categories.map((cat) => _buildCategoryChip(
                  label: cat,
                  icon: _getCategoryIcon(cat),
                  isSelected: _selectedCategory == cat,
                  onTap: () => setState(() => _selectedCategory = cat),
                )),
          ],
        ),
      ),
      loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    // Màu sắc cho icon dựa trên category
    final categoryColor = _getCategoryColor(label);
    final iconColor = isSelected 
        ? AppColors.primary 
        : categoryColor.withOpacity(0.7);
    final bgColor = isSelected 
        ? AppColors.primary.withOpacity(0.15)
        : categoryColor.withOpacity(0.1);
    
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppColors.primary.withOpacity(0.1) 
                    : categoryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected 
                      ? AppColors.primary 
                      : categoryColor.withOpacity(0.2),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('cơm')) return Colors.orange;
    if (lower.contains('phở') || lower.contains('bún')) return Colors.amber;
    if (lower.contains('uống') || lower.contains('cafe')) return Colors.blue;
    if (lower.contains('vặt')) return Colors.red;
    if (lower.contains('tráng miệng') || lower.contains('bánh')) return Colors.pink;
    return AppColors.primary;
  }

  Widget _buildSearchResultsSection() {
    final searchResults = ref.watch(productSearchProvider(_searchQuery));
    return searchResults.when(
      data: (products) => _buildProductListSection('Kết quả tìm kiếm', products),
      loading: () => const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(20),
        child: Text('Lỗi: $e'),
      ),
    );
  }

  Widget _buildCategoryProductsSection() {
    // Để đơn giản, ta fetch toàn bộ sản phẩm và lọc
    final productsAsync = ref.watch(allProductsProvider);
    return productsAsync.when(
      data: (all) {
        final filtered = all.where((p) => p.category == _selectedCategory).toList();
        return _buildProductListSection('Danh mục: $_selectedCategory', filtered);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Lỗi: $e')),
    );
  }

  Widget _buildProductListSection(String title, List<ProductModel> products) {
    if (products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(child: Text('Không tìm thấy sản phẩm nào', style: AppTextStyles.body13Secondary)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(title, style: AppTextStyles.heading18),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final p = products[index];
            return ListTile(
              title: Text(p.name, style: AppTextStyles.label14),
              subtitle: Text(p.description ?? '', maxLines: 1),
              trailing: Text(_formatPrice(p.basePrice), style: AppTextStyles.label14),
              onTap: () {
                // Hiện tại ta chưa có màn hình chi tiết sản phẩm đơn lẻ (vì sp thuộc shop)
                // Nhưng có thể redirect tới các shop bán sp này? 
                // Ở MVP này ta chỉ hiển thị.
              },
            );
          },
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    category = category.toLowerCase();
    if (category.contains('cơm')) return Icons.rice_bowl;
    if (category.contains('phở') || category.contains('bún')) return Icons.ramen_dining;
    if (category.contains('uống') || category.contains('cafe')) return Icons.local_cafe;
    if (category.contains('vặt')) return Icons.cookie;
    if (category.contains('tráng miệng') || category.contains('bánh')) return Icons.cake;
    return Icons.category;
  }

  String _formatPrice(int price) {
    return '${price.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}đ';
  }
}

class _SortFilters extends StatelessWidget {
  const _SortFilters();
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _FilterChip(label: 'Gần tôi', icon: Icons.near_me, isActive: true),
          const SizedBox(width: 8),
          _FilterChip(label: 'Giá thấp', icon: Icons.payments_outlined),
          const SizedBox(width: 8),
          _FilterChip(label: 'Đánh giá 4.5+', icon: Icons.star_outline),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  const _FilterChip({required this.label, required this.icon, this.isActive = false});
  
  Color _getFilterColor() {
    if (label.contains('Gần tôi')) return Colors.blue;
    if (label.contains('Giá thấp')) return Colors.green;
    if (label.contains('Đánh giá')) return Colors.amber;
    return AppColors.primary;
  }
  
  @override
  Widget build(BuildContext context) {
    final filterColor = _getFilterColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive 
            ? AppColors.primary
            : filterColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive 
              ? AppColors.primary 
              : filterColor.withOpacity(0.3),
          width: isActive ? 2 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Icon(
            icon, 
            size: 16, 
            color: isActive 
                ? Colors.white 
                : filterColor.withOpacity(0.8),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive 
                  ? Colors.white 
                  : filterColor.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedStoresSection extends ConsumerWidget {
  const _FeaturedStoresSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final merchantsAsync = ref.watch(merchantsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Cửa hàng nổi bật', style: AppTextStyles.heading18),
              Text(
                'Xem tất cả',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        merchantsAsync.when(
          data: (merchants) => ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: merchants.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _VerticalStoreCard(merchant: merchants[index]),
              );
            },
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Lỗi: $err')),
        ),
      ],
    );
  }
}

class _VerticalStoreCard extends StatelessWidget {
  final MerchantModel merchant;

  const _VerticalStoreCard({required this.merchant});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/store/${merchant.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.large),
          boxShadow: AppShadows.soft(0.04),
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.large)),
              child: Container(
                height: 140,
                width: double.infinity,
                color: Colors.grey[200],
                child: const Icon(Icons.store, size: 48, color: AppColors.primary),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(merchant.name, style: AppTextStyles.label16),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Color(0xFFFBBF24), size: 16),
                          const SizedBox(width: 4),
                          Text('4.8', style: AppTextStyles.label14),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('\$\$ • Bún, Phở • 1.2km', style: AppTextStyles.body13Secondary),
                      const SizedBox(width: 8),
                      const Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Text('20-30m', style: AppTextStyles.body12),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFF0FDFA), borderRadius: BorderRadius.circular(4)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.flash_on, color: Color(0xFF0D9488), size: 12),
                        const SizedBox(width: 4),
                        Text(
                          'Giảm 15k cho đơn từ 100k',
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF0D9488)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
