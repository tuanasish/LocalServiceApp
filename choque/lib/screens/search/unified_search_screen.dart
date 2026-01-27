import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/design_system.dart';
import '../../providers/app_providers.dart';
import '../../data/models/product_model.dart';
import '../../data/models/merchant_model.dart';
import '../../data/models/search_history_model.dart';
import '../../data/models/search_filters_model.dart';
import '../../screens/search/search_filters_sheet.dart';
import '../../providers/address_provider.dart';
import '../../utils/distance_utils.dart';
import '../../config/constants.dart';

/// Unified Search Screen
/// 
/// Tìm kiếm products và shops cùng lúc với search history và filters.
class UnifiedSearchScreen extends ConsumerStatefulWidget {
  final String? initialQuery;

  const UnifiedSearchScreen({
    super.key,
    this.initialQuery,
  });

  @override
  ConsumerState<UnifiedSearchScreen> createState() => _UnifiedSearchScreenState();
}

class _UnifiedSearchScreenState extends ConsumerState<UnifiedSearchScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  Timer? _suggestionsDebounceTimer;
  String _searchQuery = '';
  String _suggestionsQuery = ''; // Debounced query for suggestions
  String _selectedTab = 'all'; // 'all', 'products', 'shops'
  bool _isSearching = false;
  SearchFilters _filters = SearchFilters.empty;

  late TabController _tabController;
  
  // Cache cho filtered/sorted results
  List<ProductModel>? _cachedFilteredProducts;
  List<MerchantModel>? _cachedFilteredShops;
  SearchFilters? _cachedFilters;
  String? _cachedSearchQuery;
  String? _cachedTab;
  double? _cachedUserLat;
  double? _cachedUserLng;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedTab = ['all', 'products', 'shops'][_tabController.index];
        });
      }
    });
    
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _searchQuery = widget.initialQuery!;
      _isSearching = true;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _suggestionsDebounceTimer?.cancel();
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    final trimmedValue = value.trim();
    
    // Update suggestions query với debounce ngắn hơn (300ms)
    _suggestionsDebounceTimer?.cancel();
    _suggestionsDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _suggestionsQuery = trimmedValue;
      });
    });
    
    // Update search query với debounce dài hơn (400ms)
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      setState(() {
        _searchQuery = trimmedValue;
        _isSearching = trimmedValue.isNotEmpty;
      });

      // Lưu search history nếu có query và user đã đăng nhập
      if (trimmedValue.isNotEmpty) {
        final user = ref.read(currentUserProvider).value;
        if (user != null) {
          ref.read(searchRepositoryProvider).saveSearchHistory(
            userId: user.id,
            query: trimmedValue,
            searchType: _selectedTab == 'all' ? null : _selectedTab,
          );
        }
      }
    });
  }

  void _onHistoryTap(String query) {
    _searchController.text = query;
    setState(() {
      _searchQuery = query;
      _isSearching = true;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
            _buildHeader(),
            if (_isSearching) ...[
              if (_filters.hasFilters) _buildActiveFilters(),
              _buildTabs(),
            ],
            Expanded(
              child: _isSearching ? _buildSearchResults() : _buildSearchHistory(),
            ),
              ],
            ),
            // Autocomplete overlay
            if (!_isSearching && _suggestionsQuery.length >= 2)
              Positioned(
                top: 80,
                left: 0,
                right: 0,
                child: _buildAutocompleteOverlay(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppShadows.soft(0.08),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: widget.initialQuery == null,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Tìm món ăn, nhà hàng...',
                  hintStyle: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 22),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20, color: AppColors.textMuted),
                          onPressed: _clearSearch,
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.tune, color: AppColors.primary, size: 24),
                onPressed: () {
                  SearchFiltersSheet.show(
                    context,
                    initialFilters: _filters,
                    onApply: (filters) {
                      setState(() {
                        _filters = filters;
                      });
                    },
                  );
                },
              ),
              if (_filters.hasFilters)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilters() {
    final chips = <Widget>[];
    
    if (_filters.minPrice != null || _filters.maxPrice != null) {
      final min = _filters.minPrice != null ? '${(_filters.minPrice! / 1000).toStringAsFixed(0)}k' : '0';
      final max = _filters.maxPrice != null ? '${(_filters.maxPrice! / 1000).toStringAsFixed(0)}k' : '500k';
      chips.add(_buildFilterChip('Giá: $min - $max', () {
        setState(() {
          _filters = _filters.copyWith(minPrice: null, maxPrice: null);
        });
      }));
    }
    
    if (_filters.minRating != null) {
      chips.add(_buildFilterChip('Đánh giá: ${_filters.minRating}+', () {
        setState(() {
          _filters = _filters.copyWith(minRating: null);
        });
      }));
    }
    
    if (_filters.maxDistance != null) {
      final distanceText = _filters.maxDistance == null 
          ? 'Gần tôi' 
          : '< ${_filters.maxDistance!.toStringAsFixed(0)}km';
      chips.add(_buildFilterChip('Khoảng cách: $distanceText', () {
        setState(() {
          _filters = _filters.copyWith(maxDistance: null);
        });
      }));
    }
    
    if (_filters.categories != null && _filters.categories!.isNotEmpty) {
      chips.add(_buildFilterChip('Danh mục: ${_filters.categories!.length}', () {
        setState(() {
          _filters = _filters.copyWith(categories: null);
        });
      }));
    }
    
    if (chips.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: chips,
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(label, style: AppTextStyles.body13),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onRemove,
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
      deleteIconColor: AppColors.primary,
    );
  }

  Widget _buildTabs() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        tabs: const [
          Tab(text: 'Tất cả'),
          Tab(text: 'Sản phẩm'),
          Tab(text: 'Cửa hàng'),
        ],
      ),
    );
  }

  Widget _buildAutocompleteOverlay() {
    if (_suggestionsQuery.length < 2) return const SizedBox.shrink();
    
    final suggestionsAsync = ref.watch(searchSuggestionsProvider(_suggestionsQuery));
    
    return suggestionsAsync.when(
      data: (suggestions) {
        if (suggestions.isEmpty) return const SizedBox.shrink();
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppShadows.soft(0.1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: suggestions.map((suggestion) => ListTile(
              leading: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
              title: Text(suggestion, style: AppTextStyles.body13),
              onTap: () => _onHistoryTap(suggestion),
            )).toList(),
          ),
        );
      },
      loading: () => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppShadows.soft(0.1),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildSearchHistory() {
    final historyAsync = ref.watch(searchHistoryProvider);

    return historyAsync.when(
      data: (history) {
        if (history.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'Tìm kiếm món ăn hoặc cửa hàng',
                  style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Lịch sử tìm kiếm', style: AppTextStyles.heading18),
                TextButton(
                  onPressed: () async {
                    final user = ref.read(currentUserProvider).value;
                    if (user != null) {
                      await ref.read(searchRepositoryProvider).clearSearchHistory(user.id);
                      ref.invalidate(searchHistoryProvider);
                    }
                  },
                  child: Text('Xóa tất cả', style: GoogleFonts.inter(color: AppColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...history.map((item) => _buildHistoryItem(item)),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildHistoryItem(SearchHistoryModel item) {
    return ListTile(
      leading: const Icon(Icons.history, color: AppColors.textSecondary),
      title: Text(item.query, style: AppTextStyles.label14),
      trailing: IconButton(
        icon: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
        onPressed: () async {
          await ref.read(searchRepositoryProvider).deleteSearchHistory(item.id);
          ref.invalidate(searchHistoryProvider);
        },
      ),
      onTap: () => _onHistoryTap(item.query),
    );
  }

  Widget _buildSearchResults() {
    if (_searchQuery.isEmpty) return const SizedBox.shrink();

    final marketId = AppConstants.defaultMarketId;
    final searchParams = {
      'query': _searchQuery,
      'market_id': marketId,
    };

    // Get user location for distance filter
    final addressesAsync = ref.watch(userAddressesProvider);
    double? userLat;
    double? userLng;
    addressesAsync.whenData((addresses) {
      if (addresses.isNotEmpty) {
        final defaultAddress = addresses.firstWhere(
          (a) => a.isDefault,
          orElse: () => addresses.first,
        );
        userLat = defaultAddress.lat;
        userLng = defaultAddress.lng;
      }
    });
    
    // Store non-nullable values for use in filters
    final lat = userLat;
    final lng = userLng;

    if (_selectedTab == 'all') {
      final unifiedAsync = ref.watch(unifiedSearchProvider(searchParams));
      return unifiedAsync.when(
        data: (results) {
          var products = results['products'] as List<ProductModel>;
          var shops = results['shops'] as List<MerchantModel>;

          // Cache filtered/sorted results để tránh tính lại mỗi build
          if (_cachedFilters != _filters || 
              _cachedSearchQuery != _searchQuery || 
              _cachedTab != _selectedTab ||
              _cachedUserLat != userLat ||
              _cachedUserLng != userLng ||
              _cachedFilteredProducts == null ||
              _cachedFilteredShops == null) {
            // Apply filters
            products = _applyProductFilters(products);
            shops = _applyShopFilters(shops, lat, lng);

            // Sort
            products = _sortProducts(products);
            shops = _sortShops(shops, lat, lng);
            
            // Cache results
            _cachedFilteredProducts = products;
            _cachedFilteredShops = shops;
            _cachedFilters = _filters;
            _cachedSearchQuery = _searchQuery;
            _cachedTab = _selectedTab;
            _cachedUserLat = userLat;
            _cachedUserLng = userLng;
          } else {
            products = _cachedFilteredProducts!;
            shops = _cachedFilteredShops!;
          }

          if (products.isEmpty && shops.isEmpty) {
            return _buildEmptyState();
          }

          // Tính tổng số items cho ListView.builder
          final shopsHeaderCount = shops.isNotEmpty ? 2 : 0; // Header + spacing
          final productsHeaderCount = products.isNotEmpty ? 2 : 0; // Header + spacing
          final totalItems = shops.length + products.length + shopsHeaderCount + productsHeaderCount;
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: totalItems,
            itemBuilder: (context, index) {
              // Shops section
              if (shops.isNotEmpty) {
                if (index == 0) {
                  return _buildSectionHeader('Cửa hàng (${shops.length})');
                }
                if (index == 1) {
                  return const SizedBox(height: 12);
                }
                if (index >= 2 && index < 2 + shops.length) {
                  return _buildShopCard(shops[index - 2]);
                }
                if (index == 2 + shops.length) {
                  return const SizedBox(height: 24);
                }
                // Products section
                final productIndex = index - (2 + shops.length + 1);
                if (productIndex == 0) {
                  return _buildSectionHeader('Sản phẩm (${products.length})');
                }
                if (productIndex == 1) {
                  return const SizedBox(height: 12);
                }
                if (productIndex >= 2 && productIndex < 2 + products.length) {
                  return _buildProductCard(products[productIndex - 2]);
                }
              } else {
                // Chỉ có products
                if (index == 0) {
                  return _buildSectionHeader('Sản phẩm (${products.length})');
                }
                if (index == 1) {
                  return const SizedBox(height: 12);
                }
                if (index >= 2 && index < 2 + products.length) {
                  return _buildProductCard(products[index - 2]);
                }
              }
              return const SizedBox.shrink();
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
      );
    } else if (_selectedTab == 'products') {
      final productsAsync = ref.watch(productSearchProvider(_searchQuery));
      return productsAsync.when(
        data: (products) {
          // Cache filtered/sorted results
          if (_cachedFilters != _filters || 
              _cachedSearchQuery != _searchQuery || 
              _cachedTab != _selectedTab ||
              _cachedFilteredProducts == null) {
            var filteredProducts = _applyProductFilters(products);
            filteredProducts = _sortProducts(filteredProducts);
            _cachedFilteredProducts = filteredProducts;
            _cachedFilters = _filters;
            _cachedSearchQuery = _searchQuery;
            _cachedTab = _selectedTab;
          }
          
          final filteredProducts = _cachedFilteredProducts!;
          if (filteredProducts.isEmpty) return _buildEmptyState();
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) {
              return _buildProductCard(filteredProducts[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
      );
    } else {
      final shopsAsync = ref.watch(merchantSearchProvider(searchParams));
      return shopsAsync.when(
        data: (shops) {
          // Cache filtered/sorted results
          if (_cachedFilters != _filters || 
              _cachedSearchQuery != _searchQuery || 
              _cachedTab != _selectedTab ||
              _cachedUserLat != lat ||
              _cachedUserLng != lng ||
              _cachedFilteredShops == null) {
            var filteredShops = _applyShopFilters(shops, lat, lng);
            filteredShops = _sortShops(filteredShops, lat, lng);
            _cachedFilteredShops = filteredShops;
            _cachedFilters = _filters;
            _cachedSearchQuery = _searchQuery;
            _cachedTab = _selectedTab;
            _cachedUserLat = lat;
            _cachedUserLng = lng;
          }
          
          final filteredShops = _cachedFilteredShops!;
          if (filteredShops.isEmpty) return _buildEmptyState();
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredShops.length,
            itemBuilder: (context, index) {
              return _buildShopCard(filteredShops[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
      );
    }
  }

  List<ProductModel> _applyProductFilters(List<ProductModel> products) {
    var filtered = products;

    // Price filter
    if (_filters.minPrice != null || _filters.maxPrice != null) {
      filtered = filtered.where((p) {
        final price = p.basePrice.toDouble();
        if (_filters.minPrice != null && price < _filters.minPrice!) return false;
        if (_filters.maxPrice != null && price > _filters.maxPrice!) return false;
        return true;
      }).toList();
    }

    // Category filter
    if (_filters.categories != null && _filters.categories!.isNotEmpty) {
      filtered = filtered.where((p) {
        return _filters.categories!.contains(p.category);
      }).toList();
    }

    return filtered;
  }

  List<MerchantModel> _applyShopFilters(List<MerchantModel> shops, double? userLat, double? userLng) {
    var filtered = shops;

    // Rating filter
    if (_filters.minRating != null) {
      filtered = filtered.where((s) {
        return s.rating != null && s.rating! >= _filters.minRating!;
      }).toList();
    }

    // Distance filter
    if (_filters.maxDistance != null && userLat != null && userLng != null) {
      final lat = userLat;
      final lng = userLng;
      final maxDist = _filters.maxDistance!;
      filtered = filtered.where((s) {
        if (s.lat == null || s.lng == null) return false;
        final distance = DistanceUtils.calculateDistance(
          lat,
          lng,
          s.lat!,
          s.lng!,
        );
        return distance <= maxDist;
      }).toList();
    }

    // Category filter (check shop's primary category)
    if (_filters.categories != null && _filters.categories!.isNotEmpty) {
      // Note: Shop category filtering would need shop's primary category
      // For now, we'll skip this filter for shops
    }

    return filtered;
  }

  List<ProductModel> _sortProducts(List<ProductModel> products) {
    final sortBy = _filters.sortBy ?? 'relevance';
    
    switch (sortBy) {
      case 'price_asc':
        products.sort((a, b) => a.basePrice.compareTo(b.basePrice));
        break;
      case 'price_desc':
        products.sort((a, b) => b.basePrice.compareTo(a.basePrice));
        break;
      case 'relevance':
      default:
        // Keep original order
        break;
    }
    
    return products;
  }

  List<MerchantModel> _sortShops(List<MerchantModel> shops, double? userLat, double? userLng) {
    final sortBy = _filters.sortBy ?? 'relevance';
    
    switch (sortBy) {
      case 'rating':
        shops.sort((a, b) {
          final ratingA = a.rating ?? 0.0;
          final ratingB = b.rating ?? 0.0;
          return ratingB.compareTo(ratingA);
        });
        break;
      case 'distance':
        if (userLat != null && userLng != null) {
          final lat = userLat;
          final lng = userLng;
          shops.sort((a, b) {
            if (a.lat == null || a.lng == null) return 1;
            if (b.lat == null || b.lng == null) return -1;
            final distanceA = DistanceUtils.calculateDistance(
              lat,
              lng,
              a.lat!,
              a.lng!,
            );
            final distanceB = DistanceUtils.calculateDistance(
              lat,
              lng,
              b.lat!,
              b.lng!,
            );
            return distanceA.compareTo(distanceB);
          });
        }
        break;
      case 'relevance':
      default:
        // Keep original order
        break;
    }
    
    return shops;
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: AppTextStyles.heading18);
  }

  Widget _buildShopCard(MerchantModel shop) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: const Icon(Icons.store, color: AppColors.primary),
        ),
        title: Text(shop.name, style: AppTextStyles.label14),
        subtitle: Text(
          shop.address ?? '',
          style: AppTextStyles.body13Secondary,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: shop.rating != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Color(0xFFFBBF24), size: 16),
                  const SizedBox(width: 4),
                  Text(shop.rating!.toStringAsFixed(1), style: AppTextStyles.body13),
                ],
              )
            : null,
        onTap: () => context.push('/store/${shop.id}'),
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: const Icon(Icons.restaurant, color: AppColors.primary),
        ),
        title: Text(product.name, style: AppTextStyles.label14),
        subtitle: Text(
          product.description ?? product.category ?? '',
          style: AppTextStyles.body13Secondary,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          '${product.basePrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ',
          style: AppTextStyles.label14,
        ),
        onTap: () {
          // TODO: Navigate to product detail or shop that sells it
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy kết quả',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Thử tìm kiếm với từ khóa khác',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }
}
