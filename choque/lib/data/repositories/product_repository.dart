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

    return (response as List)
        .map((json) => ProductModel.fromJson(json))
        .toList();
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

    return (response as List)
        .map((json) => ProductModel.fromJson(json))
        .toList();
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
        .or(
          'name.ilike.%$trimmedQuery%,description.ilike.%$trimmedQuery%,category.ilike.%$trimmedQuery%',
        )
        .limit(50)
        .timeout(AppConstants.apiTimeout);

    return (response as List)
        .map((json) => ProductModel.fromJson(json))
        .toList();
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

  // ============================================================
  // ADMIN METHODS
  // ============================================================

  /// [Admin] Get all products with optional filtering
  Future<List<AdminProductInfo>> adminGetAllProducts({
    String? statusFilter,
    String? categoryFilter,
  }) async {
    final response = await _client.rpc(
      'admin_get_all_products',
      params: {
        'p_status_filter': statusFilter,
        'p_category_filter': categoryFilter,
      },
    ).timeout(AppConstants.apiTimeout);

    return (response as List)
        .map((json) => AdminProductInfo.fromJson(json))
        .toList();
  }

  /// [Admin] Create a new product
  Future<ProductModel> adminCreateProduct({
    required String name,
    String? description,
    required int basePrice,
    String? category,
    String? imagePath,
  }) async {
    final response = await _client.rpc(
      'admin_create_product',
      params: {
        'p_name': name,
        'p_description': description,
        'p_base_price': basePrice,
        'p_category': category,
        'p_image_path': imagePath,
      },
    ).timeout(AppConstants.apiTimeout);

    return ProductModel.fromJson(response);
  }

  /// [Admin] Update an existing product
  Future<ProductModel> adminUpdateProduct({
    required String productId,
    String? name,
    String? description,
    int? basePrice,
    String? category,
    String? imagePath,
    String? status,
  }) async {
    final response = await _client.rpc(
      'admin_update_product',
      params: {
        'p_product_id': productId,
        'p_name': name,
        'p_description': description,
        'p_base_price': basePrice,
        'p_category': category,
        'p_image_path': imagePath,
        'p_status': status,
      },
    ).timeout(AppConstants.apiTimeout);

    return ProductModel.fromJson(response);
  }

  /// [Admin] Delete a product (soft delete)
  Future<ProductModel> adminDeleteProduct(String productId) async {
    final response = await _client.rpc(
      'admin_delete_product',
      params: {'p_product_id': productId},
    ).timeout(AppConstants.apiTimeout);

    return ProductModel.fromJson(response);
  }

  /// [Admin] Assign a product to a shop menu
  Future<void> adminAssignProductToShop({
    required String shopId,
    required String productId,
    int? customPrice,
  }) async {
    await _client.rpc(
      'admin_assign_product_to_shop',
      params: {
        'p_shop_id': shopId,
        'p_product_id': productId,
        'p_custom_price': customPrice,
      },
    ).timeout(AppConstants.apiTimeout);
  }

  /// [Admin] Remove a product from a shop menu
  Future<void> adminRemoveProductFromShop({
    required String shopId,
    required String productId,
  }) async {
    await _client.rpc(
      'admin_remove_product_from_shop',
      params: {
        'p_shop_id': shopId,
        'p_product_id': productId,
      },
    ).timeout(AppConstants.apiTimeout);
  }

  /// [Admin] Get all categories (including inactive products)
  Future<List<String>> adminGetAllCategories() async {
    final response = await _client
        .from('products')
        .select('category')
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

// ============================================================
// ADMIN PRODUCT MODELS
// ============================================================

/// Admin Product Info model (from admin_get_all_products RPC)
class AdminProductInfo {
  final String id;
  final String name;
  final String? description;
  final String? imagePath;
  final int basePrice;
  final String? category;
  final String status;
  final int shopCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AdminProductInfo({
    required this.id,
    required this.name,
    this.description,
    this.imagePath,
    required this.basePrice,
    this.category,
    required this.status,
    required this.shopCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdminProductInfo.fromJson(Map<String, dynamic> json) {
    return AdminProductInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      imagePath: json['image_path'] as String?,
      basePrice: json['base_price'] as int? ?? 0,
      category: json['category'] as String?,
      status: json['status'] as String? ?? 'active',
      shopCount: json['shop_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Get image URL from Supabase Storage
  String? get imageUrl => imagePath != null
      ? 'https://ipdwpzgbznphkmdewjdl.supabase.co/storage/v1/object/public/products/$imagePath'
      : null;
}
