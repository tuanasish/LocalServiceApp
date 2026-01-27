import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';
import '../../config/constants.dart';

/// Product Repository
/// 
/// Xử lý các thao tác liên quan đến sản phẩm/menu.
class ProductRepository {
  final SupabaseClient _client;

  ProductRepository(this._client);

  factory ProductRepository.instance() {
    return ProductRepository(Supabase.instance.client);
  }

  /// Lấy danh sách tất cả sản phẩm active
  Future<List<ProductModel>> getAllProducts() async {
    final response = await _client
        .from('products')
        .select()
        .eq('status', 'active')
        .order('category')
        .order('name')
        .timeout(AppConstants.apiTimeout);

    return (response as List).map((json) => ProductModel.fromJson(json)).toList();
  }

  /// Lấy sản phẩm theo danh mục
  Future<List<ProductModel>> getProductsByCategory(String category) async {
    final response = await _client
        .from('products')
        .select()
        .eq('status', 'active')
        .eq('category', category)
        .order('name')
        .timeout(AppConstants.apiTimeout);

    return (response as List).map((json) => ProductModel.fromJson(json)).toList();
  }

  /// Lấy chi tiết sản phẩm
  Future<ProductModel> getProductDetail(String productId) async {
    final response = await _client
        .from('products')
        .select()
        .eq('id', productId)
        .single()
        .timeout(AppConstants.apiTimeout);

    return ProductModel.fromJson(response);
  }

  /// Tìm kiếm sản phẩm (name, description, category)
  Future<List<ProductModel>> searchProducts(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return [];

    final response = await _client
        .from('products')
        .select()
        .eq('status', 'active')
        .or('name.ilike.%$trimmedQuery%,description.ilike.%$trimmedQuery%,category.ilike.%$trimmedQuery%')
        .limit(50)
        .timeout(AppConstants.apiTimeout);

    return (response as List).map((json) => ProductModel.fromJson(json)).toList();
  }

  /// Lấy danh sách danh mục
  Future<List<String>> getCategories() async {
    final response = await _client
        .from('products')
        .select('category')
        .eq('status', 'active')
        .not('category', 'is', null)
        .timeout(AppConstants.apiTimeout);

    final categories = (response as List)
        .map((json) => json['category'] as String?)
        .where((c) => c != null)
        .cast<String>()
        .toSet()
        .toList();
    
    categories.sort();
    return categories;
  }
}
