/// Search Filters Model
/// 
/// Lưu trữ các bộ lọc cho search results.
class SearchFilters {
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  final double? maxDistance; // km
  final List<String>? categories;
  final String? sortBy; // 'relevance', 'price_asc', 'price_desc', 'rating', 'distance'

  const SearchFilters({
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.maxDistance,
    this.categories,
    this.sortBy,
  });

  SearchFilters copyWith({
    double? minPrice,
    double? maxPrice,
    double? minRating,
    double? maxDistance,
    List<String>? categories,
    String? sortBy,
  }) {
    return SearchFilters(
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minRating: minRating ?? this.minRating,
      maxDistance: maxDistance ?? this.maxDistance,
      categories: categories ?? this.categories,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  bool get hasFilters => 
    minPrice != null ||
    maxPrice != null ||
    minRating != null ||
    maxDistance != null ||
    (categories != null && categories!.isNotEmpty) ||
    sortBy != null;

  static const SearchFilters empty = SearchFilters();
}
