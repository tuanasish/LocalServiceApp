/// Profile Model
/// 
/// Ánh xạ bảng `profiles` trong Supabase.
/// Quản lý thông tin người dùng và vai trò (customer, driver, merchant, super_admin).
class ProfileModel {
  final String userId;
  final String? phone;
  final String? fullName;
  final List<String> roles;
  final String marketId;
  final String? driverStatus; // offline/online/busy
  final String? deviceId;
  final String? fcmToken;
  final bool isGuest;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProfileModel({
    required this.userId,
    this.phone,
    this.fullName,
    required this.roles,
    required this.marketId,
    this.driverStatus,
    this.deviceId,
    this.fcmToken,
    this.isGuest = false,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      userId: json['user_id'] as String,
      phone: json['phone'] as String?,
      fullName: json['full_name'] as String?,
      roles: (json['roles'] as List<dynamic>?)?.cast<String>() ?? ['customer'],
      marketId: json['market_id'] as String? ?? 'default',
      driverStatus: json['driver_status'] as String?,
      deviceId: json['device_id'] as String?,
      fcmToken: json['fcm_token'] as String?,
      isGuest: json['is_guest'] as bool? ?? false,
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'phone': phone,
      'full_name': fullName,
      'roles': roles,
      'market_id': marketId,
      'driver_status': driverStatus,
      'device_id': deviceId,
      'fcm_token': fcmToken,
      'is_guest': isGuest,
      'status': status,
    };
  }

  bool get isCustomer => roles.contains('customer');
  bool get isDriver => roles.contains('driver');
  bool get isMerchant => roles.contains('merchant');
  bool get isSuperAdmin => roles.contains('super_admin');
}
