import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/design_system.dart';
import '../../providers/app_providers.dart';
import '../../data/models/search_filters_model.dart';

/// Search Filters Sheet
/// 
/// Bottom sheet với các bộ lọc: giá, đánh giá, khoảng cách, category, sort.
class SearchFiltersSheet extends ConsumerStatefulWidget {
  final SearchFilters initialFilters;
  final Function(SearchFilters) onApply;

  const SearchFiltersSheet({
    super.key,
    required this.initialFilters,
    required this.onApply,
  });

  static void show(
    BuildContext context, {
    required SearchFilters initialFilters,
    required Function(SearchFilters) onApply,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SearchFiltersSheet(
        initialFilters: initialFilters,
        onApply: onApply,
      ),
    );
  }

  @override
  ConsumerState<SearchFiltersSheet> createState() => _SearchFiltersSheetState();
}

class _SearchFiltersSheetState extends ConsumerState<SearchFiltersSheet> {
  late SearchFilters _filters;
  RangeValues _priceRange = const RangeValues(0, 500000);
  double? _selectedRating;
  double? _selectedDistance;
  List<String> _selectedCategories = [];
  String? _selectedSortBy;

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters;
    _priceRange = RangeValues(
      _filters.minPrice?.toDouble() ?? 0,
      _filters.maxPrice?.toDouble() ?? 500000,
    );
    _selectedRating = _filters.minRating;
    _selectedDistance = _filters.maxDistance;
    _selectedCategories = List<String>.from(_filters.categories ?? []);
    _selectedSortBy = _filters.sortBy;
  }

  void _applyFilters() {
    final newFilters = SearchFilters(
      minPrice: _priceRange.start > 0 ? _priceRange.start : null,
      maxPrice: _priceRange.end < 500000 ? _priceRange.end : null,
      minRating: _selectedRating,
      maxDistance: _selectedDistance,
      categories: _selectedCategories.isNotEmpty ? _selectedCategories : null,
      sortBy: _selectedSortBy,
    );
    widget.onApply(newFilters);
    Navigator.pop(context);
  }

  void _resetFilters() {
    setState(() {
      _priceRange = const RangeValues(0, 500000);
      _selectedRating = null;
      _selectedDistance = null;
      _selectedCategories = [];
      _selectedSortBy = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(productCategoriesProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'Bộ lọc',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _resetFilters,
                      child: Text(
                        'Đặt lại',
                        style: GoogleFonts.inter(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price Range
                      _buildSectionTitle('Khoảng giá'),
                      const SizedBox(height: 12),
                      RangeSlider(
                        values: _priceRange,
                        min: 0,
                        max: 500000,
                        divisions: 50,
                        labels: RangeLabels(
                          '${(_priceRange.start / 1000).toStringAsFixed(0)}k',
                          '${(_priceRange.end / 1000).toStringAsFixed(0)}k',
                        ),
                        onChanged: (values) {
                          setState(() {
                            _priceRange = values;
                          });
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('0đ', style: AppTextStyles.body13Secondary),
                          Text('500.000đ', style: AppTextStyles.body13Secondary),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Rating
                      _buildSectionTitle('Đánh giá'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildRatingChip('4.0+', 4.0),
                          _buildRatingChip('4.5+', 4.5),
                          _buildRatingChip('5.0', 5.0),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Distance
                      _buildSectionTitle('Khoảng cách'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildDistanceChip('Gần tôi', null),
                          _buildDistanceChip('< 1km', 1.0),
                          _buildDistanceChip('< 3km', 3.0),
                          _buildDistanceChip('< 5km', 5.0),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Categories
                      _buildSectionTitle('Danh mục'),
                      const SizedBox(height: 12),
                      categoriesAsync.when(
                        data: (categories) => Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: categories.map((cat) => _buildCategoryChip(cat)).toList(),
                        ),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 24),
                      
                      // Sort By
                      _buildSectionTitle('Sắp xếp theo'),
                      const SizedBox(height: 12),
                      _buildSortDropdown(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              
              // Apply Button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Áp dụng',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildRatingChip(String label, double rating) {
    final isSelected = _selectedRating == rating;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 16, color: Color(0xFFFBBF24)),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedRating = selected ? rating : null;
        });
      },
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
    );
  }

  Widget _buildDistanceChip(String label, double? distance) {
    final isSelected = _selectedDistance == distance;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedDistance = selected ? distance : null;
        });
      },
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategories.contains(category);
    return FilterChip(
      label: Text(category),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedCategories.add(category);
          } else {
            _selectedCategories.remove(category);
          }
        });
      },
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderSoft),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String>(
        value: _selectedSortBy ?? 'relevance',
        isExpanded: true,
        underline: const SizedBox.shrink(),
        items: const [
          DropdownMenuItem(value: 'relevance', child: Text('Liên quan nhất')),
          DropdownMenuItem(value: 'price_asc', child: Text('Giá thấp đến cao')),
          DropdownMenuItem(value: 'price_desc', child: Text('Giá cao đến thấp')),
          DropdownMenuItem(value: 'rating', child: Text('Đánh giá cao nhất')),
          DropdownMenuItem(value: 'distance', child: Text('Gần nhất')),
        ],
        onChanged: (value) {
          setState(() {
            _selectedSortBy = value;
          });
        },
      ),
    );
  }
}
