import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Model for Promotion
class Promotion {
  final String id;
  final String marketId;
  final String? code;
  final String name;
  final String? description;
  final String promoType;
  final String discountType;
  final int discountValue;
  final int? maxDiscount;
  final int minOrderValue;
  final String serviceType;
  final int? maxTotalUses;
  final int maxUsesPerUser;
  final int currentUses;
  final DateTime validFrom;
  final DateTime? validTo;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Promotion({
    required this.id,
    required this.marketId,
    this.code,
    required this.name,
    this.description,
    required this.promoType,
    required this.discountType,
    required this.discountValue,
    this.maxDiscount,
    required this.minOrderValue,
    required this.serviceType,
    this.maxTotalUses,
    required this.maxUsesPerUser,
    required this.currentUses,
    required this.validFrom,
    this.validTo,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      id: json['id'] as String,
      marketId: json['market_id'] as String,
      code: json['code'] as String?,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      promoType: json['promo_type'] as String? ?? 'voucher',
      discountType: json['discount_type'] as String? ?? 'fixed',
      discountValue: json['discount_value'] as int? ?? 0,
      maxDiscount: json['max_discount'] as int?,
      minOrderValue: json['min_order_value'] as int? ?? 0,
      serviceType: json['service_type'] as String? ?? 'food',
      maxTotalUses: json['max_total_uses'] as int?,
      maxUsesPerUser: json['max_uses_per_user'] as int? ?? 1,
      currentUses: json['current_uses'] as int? ?? 0,
      validFrom: DateTime.parse(json['valid_from'] as String),
      validTo: json['valid_to'] != null ? DateTime.parse(json['valid_to'] as String) : null,
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // Helper getters
  bool get isActive => status == 'active';
  bool get isPaused => status == 'paused';
  bool get isExpired => validTo != null && validTo!.isBefore(DateTime.now());
  bool get hasUsageLimit => maxTotalUses != null;
  bool get isUsageLimitReached => hasUsageLimit && currentUses >= maxTotalUses!;

  String get promoTypeLabel {
    switch (promoType) {
      case 'first_order':
        return 'Đơn đầu tiên';
      case 'voucher':
        return 'Mã voucher';
      case 'all_orders':
        return 'Tất cả đơn';
      default:
        return promoType;
    }
  }

  String get discountTypeLabel {
    switch (discountType) {
      case 'freeship':
        return 'Miễn phí ship';
      case 'fixed':
        return 'Giảm cố định';
      case 'percent':
        return 'Giảm %';
      default:
        return discountType;
    }
  }

  String get discountDisplay {
    switch (discountType) {
      case 'freeship':
        return 'Freeship tối đa ${_formatMoney(discountValue)}';
      case 'fixed':
        return '-${_formatMoney(discountValue)}';
      case 'percent':
        final cap = maxDiscount != null ? ' (max ${_formatMoney(maxDiscount!)})' : '';
        return '-$discountValue%$cap';
      default:
        return '';
    }
  }

  String _formatMoney(int value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}k';
    }
    return '$valueđ';
  }
}

/// Model for Promotion Stats
class PromotionStats {
  final int totalUses;
  final int totalDiscountApplied;
  final int uniqueUsers;
  final int revenueImpact;

  PromotionStats({
    required this.totalUses,
    required this.totalDiscountApplied,
    required this.uniqueUsers,
    required this.revenueImpact,
  });

  factory PromotionStats.fromJson(Map<String, dynamic> json) {
    return PromotionStats(
      totalUses: json['total_uses'] as int? ?? 0,
      totalDiscountApplied: json['total_discount_applied'] as int? ?? 0,
      uniqueUsers: json['unique_users'] as int? ?? 0,
      revenueImpact: json['revenue_impact'] as int? ?? 0,
    );
  }
}

final _supabase = Supabase.instance.client;
const String _marketId = 'default';

/// Provider to get all promotions
final adminPromotionsProvider = FutureProvider.autoDispose<List<Promotion>>((ref) async {
  final response = await _supabase.rpc('admin_get_all_promotions', params: {
    'p_market_id': _marketId,
  });
  
  return (response as List).map((e) => Promotion.fromJson(e as Map<String, dynamic>)).toList();
});

/// Provider to get active promotions count
final activePromotionsCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final promos = await ref.watch(adminPromotionsProvider.future);
  return promos.where((p) => p.isActive && !p.isExpired).length;
});

/// Provider to get promotion stats
final promotionStatsProvider = FutureProvider.autoDispose.family<PromotionStats, String>((ref, promoId) async {
  final response = await _supabase.rpc('admin_get_promotion_stats', params: {
    'p_promo_id': promoId,
  });
  
  return PromotionStats.fromJson(response as Map<String, dynamic>);
});

/// Create promotion
Future<Promotion> adminCreatePromotion({
  required String name,
  String? code,
  String? description,
  required String promoType,
  required String discountType,
  required int discountValue,
  int? maxDiscount,
  int minOrderValue = 0,
  int? maxTotalUses,
  int maxUsesPerUser = 1,
  DateTime? validFrom,
  DateTime? validTo,
}) async {
  final response = await _supabase.rpc('admin_create_promotion', params: {
    'p_market_id': _marketId,
    'p_code': code?.isNotEmpty == true ? code : null,
    'p_name': name,
    'p_description': description,
    'p_promo_type': promoType,
    'p_discount_type': discountType,
    'p_discount_value': discountValue,
    'p_max_discount': maxDiscount,
    'p_min_order_value': minOrderValue,
    'p_max_total_uses': maxTotalUses,
    'p_max_uses_per_user': maxUsesPerUser,
    'p_valid_from': (validFrom ?? DateTime.now()).toIso8601String(),
    'p_valid_to': validTo?.toIso8601String(),
  });
  
  return Promotion.fromJson(response as Map<String, dynamic>);
}

/// Update promotion
Future<Promotion> adminUpdatePromotion({
  required String promoId,
  String? name,
  String? description,
  int? discountValue,
  int? maxDiscount,
  int? minOrderValue,
  int? maxTotalUses,
  int? maxUsesPerUser,
  DateTime? validFrom,
  DateTime? validTo,
  String? status,
}) async {
  final response = await _supabase.rpc('admin_update_promotion', params: {
    'p_promo_id': promoId,
    'p_name': name,
    'p_description': description,
    'p_discount_value': discountValue,
    'p_max_discount': maxDiscount,
    'p_min_order_value': minOrderValue,
    'p_max_total_uses': maxTotalUses,
    'p_max_uses_per_user': maxUsesPerUser,
    'p_valid_from': validFrom?.toIso8601String(),
    'p_valid_to': validTo?.toIso8601String(),
    'p_status': status,
  });
  
  return Promotion.fromJson(response as Map<String, dynamic>);
}

/// Toggle promotion status (pause/resume)
Future<Promotion> adminTogglePromotionStatus({
  required String promoId,
  required String status,
}) async {
  final response = await _supabase.rpc('admin_toggle_promotion_status', params: {
    'p_promo_id': promoId,
    'p_status': status,
  });
  
  return Promotion.fromJson(response as Map<String, dynamic>);
}

/// Invalidate promotion providers
void invalidatePromotionProviders(WidgetRef ref) {
  ref.invalidate(adminPromotionsProvider);
  ref.invalidate(activePromotionsCountProvider);
}
