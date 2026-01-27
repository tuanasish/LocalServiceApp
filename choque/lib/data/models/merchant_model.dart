/// Merchant Model (Shop)
/// 
/// Ánh xạ bảng `shops` trong Supabase.
class MerchantModel {
  final String id;
  final String marketId;
  final String name;
  final String? address;
  final String? phone;
  final String? ownerUserId;
  final double? rating;
  final String? openingHours;
  final double? lat;
  final double? lng;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MerchantModel({
    required this.id,
    required this.marketId,
    required this.name,
    this.address,
    this.phone,
    this.ownerUserId,
    this.rating,
    this.openingHours,
    this.lat,
    this.lng,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MerchantModel.fromJson(Map<String, dynamic> json) {
    return MerchantModel(
      id: json['id'] as String,
      marketId: json['market_id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      ownerUserId: json['owner_user_id'] as String?,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      openingHours: json['opening_hours'] as String?,
      lat: json['lat'] != null ? (json['lat'] as num).toDouble() : null,
      lng: json['lng'] != null ? (json['lng'] as num).toDouble() : null,
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'market_id': marketId,
      'name': name,
      'address': address,
      'phone': phone,
      'owner_user_id': ownerUserId,
      'rating': rating,
      'opening_hours': openingHours,
      'lat': lat,
      'lng': lng,
      'status': status,
    };
  }
}
