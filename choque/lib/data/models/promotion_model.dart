/// Promotion Model
///
/// Ánh xạ bảng `promotions` trong Supabase.
/// Hỗ trợ freeship đơn đầu và voucher code.
class PromotionModel {
  final String id;
  final String marketId;
  final String? code;
  final String name;
  final String? description;
  final String promoType; // first_order, voucher, all_orders
  final String discountType; // freeship, fixed, percent
  final int discountValue;
  final int? maxDiscount;
  final int minOrderValue;
  final String serviceType;
  final int? maxTotalUses;
  final int maxUsesPerUser;
  final int currentUses;
  final DateTime? validFrom;
  final DateTime? validTo;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PromotionModel({
    required this.id,
    required this.marketId,
    this.code,
    required this.name,
    this.description,
    required this.promoType,
    required this.discountType,
    required this.discountValue,
    this.maxDiscount,
    this.minOrderValue = 0,
    this.serviceType = 'food',
    this.maxTotalUses,
    this.maxUsesPerUser = 1,
    this.currentUses = 0,
    this.validFrom,
    this.validTo,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PromotionModel.fromJson(Map<String, dynamic> json) {
    return PromotionModel(
      id: json['id'] as String,
      marketId: json['market_id'] as String,
      code: json['code'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      promoType: json['promo_type'] as String,
      discountType: json['discount_type'] as String,
      discountValue: json['discount_value'] as int,
      maxDiscount: json['max_discount'] as int?,
      minOrderValue: json['min_order_value'] as int? ?? 0,
      serviceType: json['service_type'] as String? ?? 'food',
      maxTotalUses: json['max_total_uses'] as int?,
      maxUsesPerUser: json['max_uses_per_user'] as int? ?? 1,
      currentUses: json['current_uses'] as int? ?? 0,
      validFrom: json['valid_from'] != null
          ? DateTime.parse(json['valid_from'] as String)
          : null,
      validTo: json['valid_to'] != null
          ? DateTime.parse(json['valid_to'] as String)
          : null,
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'market_id': marketId,
      'code': code,
      'name': name,
      'description': description,
      'promo_type': promoType,
      'discount_type': discountType,
      'discount_value': discountValue,
      'max_discount': maxDiscount,
      'min_order_value': minOrderValue,
      'service_type': serviceType,
      'max_total_uses': maxTotalUses,
      'max_uses_per_user': maxUsesPerUser,
    };
  }

  /// Kiểm tra xem promotion còn hiệu lực không
  bool get isValid {
    final now = DateTime.now();
    if (status != 'active') return false;
    if (validFrom != null && now.isBefore(validFrom!)) return false;
    if (validTo != null && now.isAfter(validTo!)) return false;
    if (maxTotalUses != null && currentUses >= maxTotalUses!) return false;
    return true;
  }

  /// Là promotion tự động apply (không cần nhập code)
  bool get isAutoApply => code == null;

  /// Là freeship promotion
  bool get isFreeship => discountType == 'freeship';

  /// Mô tả ngắn gọn cho UI
  String get shortDescription {
    switch (discountType) {
      case 'freeship':
        return 'Miễn phí giao hàng';
      case 'fixed':
        return 'Giảm $discountValueđ';
      case 'percent':
        return 'Giảm $discountValue%${maxDiscount != null ? " (tối đa $maxDiscountđ)" : ""}';
      default:
        return name;
    }
  }
}
