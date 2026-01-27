import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/merchant_model.dart';
import '../models/order_model.dart';
import '../../config/constants.dart';

/// Shop Menu Item Model (từ View v_shop_menu)
class ShopMenuItem {
  final String shopId;
  final String productId;
  final String name;
  final String? description;
  final String? imagePath;
  final String? category;
  final int basePrice;
  final int effectivePrice;
  final bool isAvailable;
  final bool isListed;

  const ShopMenuItem({
    required this.shopId,
    required this.productId,
    required this.name,
    this.description,
    this.imagePath,
    this.category,
    required this.basePrice,
    required this.effectivePrice,
    required this.isAvailable,
    required this.isListed,
  });

  factory ShopMenuItem.fromJson(Map<String, dynamic> json) {
    return ShopMenuItem(
      shopId: json['shop_id'] as String,
      productId: json['product_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      imagePath: json['image_path'] as String?,
      category: json['category'] as String?,
      basePrice: json['base_price'] as int,
      effectivePrice: json['effective_price'] as int,
      isAvailable: json['is_available'] as bool? ?? true,
      isListed: json['is_listed'] as bool? ?? true,
    );
  }
}

/// Merchant Repository
/// 
/// Xử lý các thao tác liên quan đến cửa hàng.
class MerchantRepository {
  final SupabaseClient _client;

  MerchantRepository(this._client);

  factory MerchantRepository.instance() {
    return MerchantRepository(Supabase.instance.client);
  }

  /// Lấy danh sách cửa hàng theo market
  Future<List<MerchantModel>> getMerchantsByMarket(String marketId) async {
    final response = await _client
        .from('shops')
        .select()
        .eq('market_id', marketId)
        .eq('status', 'active')
        .order('name')
        .timeout(AppConstants.apiTimeout);

    return (response as List).map((json) => MerchantModel.fromJson(json)).toList();
  }

  /// Tìm kiếm cửa hàng theo tên
  Future<List<MerchantModel>> searchMerchants({
    required String marketId,
    required String query,
    int limit = 20,
  }) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return [];

    final response = await _client
        .from('shops')
        .select()
        .eq('market_id', marketId)
        .eq('status', 'active')
        .ilike('name', '%$trimmedQuery%')
        .limit(limit)
        .timeout(AppConstants.apiTimeout);

    return (response as List).map((json) => MerchantModel.fromJson(json)).toList();
  }

  /// Lấy chi tiết cửa hàng
  Future<MerchantModel> getMerchantDetail(String shopId) async {
    final response = await _client
        .from('shops')
        .select()
        .eq('id', shopId)
        .single()
        .timeout(AppConstants.apiTimeout);

    return MerchantModel.fromJson(response);
  }

  /// Lấy menu của cửa hàng (từ view v_shop_menu với price override)
  Future<List<ShopMenuItem>> getShopMenu(String shopId) async {
    final response = await _client
        .from('v_shop_menu')
        .select()
        .eq('shop_id', shopId)
        .eq('is_listed', true)
        .eq('is_available', true)
        .order('category')
        .order('name')
        .timeout(AppConstants.apiTimeout);

    return (response as List).map((json) => ShopMenuItem.fromJson(json)).toList();
  }

  /// Cập nhật giá và availability cho sản phẩm (Merchant)
  Future<void> setMenuOverride({
    required String shopId,
    required String productId,
    int? priceOverride,
    bool isAvailable = true,
  }) async {
    await _client.rpc(
      'set_menu_override',
      params: {
        'p_shop_id': shopId,
        'p_product_id': productId,
        'p_price_override': priceOverride,
        'p_is_available': isAvailable,
      },
    ).timeout(AppConstants.apiTimeout);
  }

  /// Lấy shop của merchant hiện tại
  Future<MerchantModel> getMyShop() async {
    final response = await _client.rpc(
      'get_my_shop',
    ).timeout(AppConstants.apiTimeout);
    
    return MerchantModel.fromJson(response as Map<String, dynamic>);
  }

  /// Lấy đơn hàng của shop
  Future<List<OrderModel>> getShopOrders({
    required String shopId,
    String? status,
    int limit = 50,
  }) async {
    final response = await _client.rpc(
      'get_shop_orders',
      params: {
        'p_shop_id': shopId,
        'p_status': status,
        'p_limit': limit,
      },
    ).timeout(AppConstants.apiTimeout);
    
    return (response as List)
        .map((json) => OrderModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Lấy thống kê shop
  Future<Map<String, dynamic>> getShopStats({
    required String shopId,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final response = await _client.rpc(
      'get_shop_stats',
      params: {
        'p_shop_id': shopId,
        'p_date_from': dateFrom?.toIso8601String(),
        'p_date_to': dateTo?.toIso8601String(),
      },
    ).timeout(AppConstants.apiTimeout);
    
    return response as Map<String, dynamic>;
  }

  /// Lấy category chính của shop (category có nhiều products nhất)
  Future<String?> getShopPrimaryCategory(String shopId) async {
    final response = await _client
        .from('v_shop_menu')
        .select('category')
        .eq('shop_id', shopId)
        .eq('is_available', true)
        .not('category', 'is', null)
        .timeout(AppConstants.apiTimeout);
    
    if (response.isEmpty) return null;
    
    // Đếm số lượng mỗi category
    final categoryCount = <String, int>{};
    for (final item in response) {
      final cat = item['category'] as String?;
      if (cat != null) {
        categoryCount[cat] = (categoryCount[cat] ?? 0) + 1;
      }
    }
    
    // Trả về category có nhiều nhất
    if (categoryCount.isEmpty) return null;
    return categoryCount.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Lấy image URL của product đầu tiên trong shop (để làm shop image)
  Future<String?> getShopImageUrl(String shopId) async {
    final response = await _client
        .from('v_shop_menu')
        .select('image_path')
        .eq('shop_id', shopId)
        .eq('is_available', true)
        .not('image_path', 'is', null)
        .limit(1)
        .timeout(AppConstants.apiTimeout);
    
    if (response.isEmpty) return null;
    final imagePath = response.first['image_path'] as String?;
    if (imagePath == null) return null;
    
    // Tạo URL từ Supabase Storage (tương tự ProductModel.imageUrl)
    return 'https://ipdwpzgbznphkmdewjdl.supabase.co/storage/v1/object/public/products/$imagePath';
  }

  /// Xác nhận đơn hàng (Merchant)
  Future<OrderModel> confirmOrder(String orderId) async {
    final response = await _client.rpc(
      'confirm_order_by_merchant',
      params: {'p_order_id': orderId},
    ).timeout(AppConstants.apiTimeout);

    return OrderModel.fromJson(response as Map<String, dynamic>);
  }

  /// Từ chối đơn hàng (Merchant)
  Future<OrderModel> rejectOrder(String orderId, String reason) async {
    final response = await _client.rpc(
      'reject_order_by_merchant',
      params: {
        'p_order_id': orderId,
        'p_reason': reason,
      },
    ).timeout(AppConstants.apiTimeout);

    return OrderModel.fromJson(response as Map<String, dynamic>);
  }

  /// Đánh dấu đơn hàng sẵn sàng để lấy (Merchant)
  Future<OrderModel> markOrderReady(String orderId) async {
    final response = await _client.rpc(
      'mark_order_ready',
      params: {'p_order_id': orderId},
    ).timeout(AppConstants.apiTimeout);

    return OrderModel.fromJson(response as Map<String, dynamic>);
  }
}
