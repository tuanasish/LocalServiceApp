/// User Profile model - maps to Supabase profiles table
/// Supports multi-role: roles is an array ['customer', 'driver', 'merchant', 'admin']
class UserProfile {
  final String userId;
  final String? phone;
  final String? fullName;
  final List<String> roles;
  final String marketId;
  final String? driverStatus; // offline/online/busy
  final String? deviceId;
  final String? fcmToken;
  final bool isGuest;
  final String? avatarUrl;
  final String status;
  final DateTime? birthDate;
  final String? gender;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.userId,
    this.phone,
    this.fullName,
    this.avatarUrl,
    required this.roles,
    required this.marketId,
    this.driverStatus,
    this.deviceId,
    this.fcmToken,
    this.isGuest = false,
    this.status = 'active',
    this.birthDate,
    this.gender,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory constructor từ Supabase JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'] as String,
      phone: json['phone'] as String?,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      roles: (json['roles'] as List<dynamic>?)?.cast<String>() ?? ['customer'],
      marketId: json['market_id'] as String? ?? 'default',
      driverStatus: json['driver_status'] as String?,
      deviceId: json['device_id'] as String?,
      fcmToken: json['fcm_token'] as String?,
      isGuest: json['is_guest'] as bool? ?? false,
      status: json['status'] as String? ?? 'active',
      birthDate: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'] as String)
          : null,
      gender: json['gender'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'phone': phone,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'roles': roles,
      'market_id': marketId,
      'driver_status': driverStatus,
      'device_id': deviceId,
      'fcm_token': fcmToken,
      'is_guest': isGuest,
      'status': status,
      'birth_date': birthDate?.toIso8601String().split('T')[0], // YYYY-MM-DD
      'gender': gender,
    };
  }

  /// Check if user has a specific role
  bool hasRole(String role) => roles.contains(role);

  /// Check if user has multiple roles
  bool get isMultiRole => roles.length > 1;

  /// Get primary role (first in array)
  String get primaryRole => roles.isNotEmpty ? roles.first : 'customer';

  /// Check specific roles
  bool get isCustomer => hasRole('customer');
  bool get isDriver => hasRole('driver');
  bool get isMerchant => hasRole('merchant');
  bool get isAdmin => hasRole('admin');

  /// Get display name for UI
  String get displayName => fullName ?? phone ?? 'Khách';

  /// CopyWith for updates
  UserProfile copyWith({
    String? phone,
    String? fullName,
    String? avatarUrl,
    List<String>? roles,
    String? driverStatus,
    String? fcmToken,
  }) {
    return UserProfile(
      userId: userId,
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      roles: roles ?? this.roles,
      marketId: marketId,
      driverStatus: driverStatus ?? this.driverStatus,
      deviceId: deviceId,
      fcmToken: fcmToken ?? this.fcmToken,
      isGuest: isGuest,
      status: status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

/// Enum for role types
enum UserRole {
  customer,
  driver,
  merchant,
  admin;

  String get displayName {
    switch (this) {
      case UserRole.customer:
        return 'Khách hàng';
      case UserRole.driver:
        return 'Tài xế';
      case UserRole.merchant:
        return 'Chủ cửa hàng';
      case UserRole.admin:
        return 'Quản trị viên';
    }
  }

  String get icon {
    switch (this) {
      case UserRole.customer:
        return '🛒';
      case UserRole.driver:
        return '🚗';
      case UserRole.merchant:
        return '🏪';
      case UserRole.admin:
        return '⚙️';
    }
  }

  String get route {
    switch (this) {
      case UserRole.customer:
        return '/';
      case UserRole.driver:
        return '/driver';
      case UserRole.merchant:
        return '/merchant';
      case UserRole.admin:
        return '/admin';
    }
  }

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => UserRole.customer,
    );
  }
}
