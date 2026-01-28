import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../ui/design_system.dart';
import '../../providers/app_providers.dart';
import '../../data/models/product_model.dart';

/// Product Picker Screen
/// Cho phép merchant chọn sản phẩm từ Master Catalog để thêm vào shop.
class ProductPickerScreen extends ConsumerStatefulWidget {
  final String shopId;
  const ProductPickerScreen({super.key, required this.shopId});

  @override
  ConsumerState<ProductPickerScreen> createState() =>
      _ProductPickerScreenState();
}

class _ProductPickerScreenState extends ConsumerState<ProductPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _isSearching = false;
  List<ProductModel> _results = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleSearch(String value) async {
    if (value.trim().isEmpty) {
      setState(() {
        _query = '';
        _results = [];
      });
      return;
    }

    setState(() {
      _query = value;
      _isSearching = true;
    });

    try {
      final results = await ref
          .read(merchantRepositoryProvider)
          .searchMasterCatalog(query: value);
      setState(() {
        _results = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tìm kiếm: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _handleAddProduct(ProductModel product) async {
    try {
      await ref
          .read(merchantRepositoryProvider)
          .addProductToShop(shopId: widget.shopId, productId: product.id);

      if (mounted) {
        ref.invalidate(shopMenuProvider(widget.shopId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã thêm ${product.name} vào menu'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Thêm món từ Catalog',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchHeader(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        onChanged: _handleSearch,
        decoration: InputDecoration(
          hintText: 'Tìm món ăn (Phở, Cơm, Bún...)',
          prefixIcon: const Icon(Icons.search, color: AppColors.primary),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _handleSearch('');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.backgroundLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_query.isEmpty) {
      return _buildEmptyState('Nhập từ khóa để tìm kiếm món ăn trong hệ thống');
    }

    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_results.isEmpty) {
      return _buildEmptyState('Không tìm thấy món nào khớp với "$_query"');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final product = _results[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        boxShadow: AppShadows.soft(0.02),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
            child: product.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.small),
                    child: Image.network(product.imageUrl!, fit: BoxFit.cover),
                  )
                : const Icon(Icons.restaurant, color: AppColors.textMuted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Text(
                  product.category ?? 'Món ăn',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${product.basePrice}đ',
                  style: GoogleFonts.inter(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _handleAddProduct(product),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              minimumSize: const Size(0, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
