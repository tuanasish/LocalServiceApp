/// Address type enum for ShopeeFood-style categorization
enum AddressType {
  home,
  work,
  other;

  String get displayName {
    switch (this) {
      case AddressType.home:
        return 'Nhà riêng';
      case AddressType.work:
        return 'Công ty';
      case AddressType.other:
        return 'Khác';
    }
  }

  static AddressType fromString(String? value) {
    switch (value) {
      case 'home':
        return AddressType.home;
      case 'work':
        return AddressType.work;
      default:
        return AddressType.other;
    }
  }
}

/// User Address model - maps to Supabase addresses table
/// ShopeeFood-style with extended fields
class UserAddress {
  final String id;
  final String userId;
  final String label; // Display label derived from addressType
  final String details; // Full address text
  final double? lat;
  final double? lng;
  final bool isDefault;
  final DateTime createdAt;
  
  // ShopeeFood-style new fields
  final AddressType addressType;
  final String? building; // Tòa nhà, Số tầng
  final String? gate; // Cổng
  final String? driverNote; // Ghi chú cho Tài xế
  final String? recipientName; // Tên người nhận
  final String? recipientPhone; // SĐT người nhận

  UserAddress({
    required this.id,
    required this.userId,
    required this.label,
    required this.details,
    this.lat,
    this.lng,
    this.isDefault = false,
    required this.createdAt,
    this.addressType = AddressType.other,
    this.building,
    this.gate,
    this.driverNote,
    this.recipientName,
    this.recipientPhone,
  });

  factory UserAddress.fromJson(Map<String, dynamic> json) {
    final addressType = AddressType.fromString(json['address_type'] as String?);
    return UserAddress(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      label: json['label'] as String? ?? addressType.displayName,
      details: json['details'] as String,
      lat: json['lat'] != null ? (json['lat'] as num).toDouble() : null,
      lng: json['lng'] != null ? (json['lng'] as num).toDouble() : null,
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      addressType: addressType,
      building: json['building'] as String?,
      gate: json['gate'] as String?,
      driverNote: json['driver_note'] as String?,
      recipientName: json['recipient_name'] as String?,
      recipientPhone: json['recipient_phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'label': label,
      'details': details,
      'lat': lat,
      'lng': lng,
      'is_default': isDefault,
      'address_type': addressType.name,
      'building': building,
      'gate': gate,
      'driver_note': driverNote,
      'recipient_name': recipientName,
      'recipient_phone': recipientPhone,
    };
  }

  UserAddress copyWith({
    String? label,
    String? details,
    double? lat,
    double? lng,
    bool? isDefault,
    AddressType? addressType,
    String? building,
    String? gate,
    String? driverNote,
    String? recipientName,
    String? recipientPhone,
  }) {
    return UserAddress(
      id: id,
      userId: userId,
      label: label ?? this.label,
      details: details ?? this.details,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt,
      addressType: addressType ?? this.addressType,
      building: building ?? this.building,
      gate: gate ?? this.gate,
      driverNote: driverNote ?? this.driverNote,
      recipientName: recipientName ?? this.recipientName,
      recipientPhone: recipientPhone ?? this.recipientPhone,
    );
  }
  
  /// Get full display address including building and gate
  String get fullDisplayAddress {
    final parts = <String>[details];
    if (building != null && building!.isNotEmpty) {
      parts.add(building!);
    }
    if (gate != null && gate!.isNotEmpty) {
      parts.add('Cổng: $gate');
    }
    return parts.join(', ');
  }
}
