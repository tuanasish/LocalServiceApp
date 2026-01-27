import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/promotion_model.dart';
import '../../config/constants.dart';

/// Promotion Repository
/// 
/// Xử lý các thao tác liên quan đến promotions và vouchers.
class PromotionRepository {
  final SupabaseClient _client;

  PromotionRepository(this._client);

  factory PromotionRepository.instance() {
    return PromotionRepository(Supabase.instance.client);
  }

  /// Lấy danh sách promotions có thể dùng cho user
  /// Sử dụng RPC function get_available_promotions
  Future<List<PromotionModel>> getAvailablePromotions({
    required String userId,
    required String marketId,
    required int orderValue,
  }) async {
    try {
      final response = await _client.rpc(
        'get_available_promotions',
        params: {
          'p_user_id': userId,
          'p_market_id': marketId,
          'p_order_value': orderValue,
        },
      ).timeout(AppConstants.apiTimeout);

      // RPC trả về simplified data, cần fetch full promotion details
      final promoList = (response as List).cast<Map<String, dynamic>>();
      
      if (promoList.isEmpty) return [];

      // Lấy full promotion details từ bảng promotions
      final promoIds = promoList.map((p) => p['id'] as String).toList();
      final fullPromos = await _client
          .from('promotions')
          .select()
          .inFilter('id', promoIds)
          .eq('status', 'active')
          .timeout(AppConstants.apiTimeout);

      return (fullPromos as List)
          .map((json) => PromotionModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Nếu RPC không có, fallback về query trực tiếp
      return _getAvailablePromotionsFallback(marketId, orderValue);
    }
  }

  /// Fallback method nếu RPC không có
  Future<List<PromotionModel>> _getAvailablePromotionsFallback(
    String marketId,
    int orderValue,
  ) async {
    final now = DateTime.now().toIso8601String();
    
    final response = await _client
        .from('promotions')
        .select()
        .eq('market_id', marketId)
        .eq('status', 'active')
        .lte('min_order_value', orderValue)
        .or('valid_from.is.null,valid_from.lte.$now')
        .or('valid_to.is.null,valid_to.gte.$now')
        .timeout(AppConstants.apiTimeout);

      return (response as List)
          .map((json) => PromotionModel.fromJson(json))
          .where((promo) => promo.isValid)
          .toList();
  }

  /// Validate và lấy promotion theo code
  Future<PromotionModel?> validatePromoCode({
    required String code,
    required String userId,
    required String marketId,
    required int orderValue,
  }) async {
    try {
      // Tìm promotion theo code
      final response = await _client
          .from('promotions')
          .select()
          .eq('code', code.toUpperCase().trim())
          .eq('market_id', marketId)
          .eq('status', 'active')
          .single()
          .timeout(AppConstants.apiTimeout);

      final promo = PromotionModel.fromJson(response as Map<String, dynamic>);

      // Kiểm tra validity
      if (!promo.isValid) return null;
      if (orderValue < promo.minOrderValue) return null;

      // Kiểm tra user đã dùng chưa
      final usageCount = await _client
          .from('user_promotions')
          .select('id')
          .eq('user_id', userId)
          .eq('promotion_id', promo.id)
          .timeout(AppConstants.apiTimeout);

      if ((usageCount as List).length >= promo.maxUsesPerUser) {
        return null; // User đã dùng hết lượt
      }

      return promo;
    } catch (e) {
      return null;
    }
  }

  /// Tính toán discount amount từ promotion
  /// Sử dụng RPC function calculate_discount hoặc tính local
  Future<int> calculateDiscount({
    required String promotionId,
    required int deliveryFee,
    required int itemsTotal,
  }) async {
    try {
      final response = await _client.rpc(
        'calculate_discount',
        params: {
          'p_promotion_id': promotionId,
          'p_delivery_fee': deliveryFee,
          'p_items_total': itemsTotal,
        },
      ).timeout(AppConstants.apiTimeout);

      return response as int? ?? 0;
    } catch (e) {
      // Fallback: tính local
      return _calculateDiscountLocal(
        promotionId: promotionId,
        deliveryFee: deliveryFee,
        itemsTotal: itemsTotal,
      );
    }
  }

  /// Tính discount local nếu RPC không có
  Future<int> _calculateDiscountLocal({
    required String promotionId,
    required int deliveryFee,
    required int itemsTotal,
  }) async {
    try {
      final response = await _client
          .from('promotions')
          .select()
          .eq('id', promotionId)
          .single()
          .timeout(AppConstants.apiTimeout);

      final promo = PromotionModel.fromJson(response as Map<String, dynamic>);

      switch (promo.discountType) {
        case 'freeship':
          // Freeship: giảm tối đa = delivery_fee, nhưng không quá discount_value
          return deliveryFee < promo.discountValue 
              ? deliveryFee 
              : promo.discountValue;
        case 'fixed':
          // Fixed: giảm cố định
          return promo.discountValue;
        case 'percent':
          // Percent: % của tổng đơn, cap bởi max_discount
          int discount = (itemsTotal * promo.discountValue / 100).round();
          if (promo.maxDiscount != null && discount > promo.maxDiscount!) {
            discount = promo.maxDiscount!;
          }
          return discount;
        default:
          return 0;
      }
    } catch (e) {
      return 0;
    }
  }

  /// Lấy promotion theo ID
  Future<PromotionModel?> getPromotionById(String promotionId) async {
    try {
      final response = await _client
          .from('promotions')
          .select()
          .eq('id', promotionId)
          .single()
          .timeout(AppConstants.apiTimeout);

      return PromotionModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }
}
