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

  // Driver approval fields
  final String? driverApprovalStatus; // pending/approved/rejected
  final DateTime? driverApprovedAt;
  final String? driverApprovedBy;
  final String? driverRejectionReason;
  final Map<String, dynamic>? driverVehicleInfo;
  final Map<String, dynamic>? driverLicenseInfo;
  final List<String>? driverDocuments;

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
    // Driver approval fields
    this.driverApprovalStatus,
    this.driverApprovedAt,
    this.driverApprovedBy,
    this.driverRejectionReason,
    this.driverVehicleInfo,
    this.driverLicenseInfo,
    this.driverDocuments,
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
      // Driver approval fields
      driverApprovalStatus: json['driver_approval_status'] as String?,
      driverApprovedAt: json['driver_approved_at'] != null
          ? DateTime.parse(json['driver_approved_at'] as String)
          : null,
      driverApprovedBy: json['driver_approved_by'] as String?,
      driverRejectionReason: json['driver_rejection_reason'] as String?,
      driverVehicleInfo: json['driver_vehicle_info'] as Map<String, dynamic>?,
      driverLicenseInfo: json['driver_license_info'] as Map<String, dynamic>?,
      driverDocuments: (json['driver_documents'] as List<dynamic>?)
          ?.cast<String>(),
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
      // Driver approval fields
      'driver_approval_status': driverApprovalStatus,
      'driver_approved_at': driverApprovedAt?.toIso8601String(),
      'driver_approved_by': driverApprovedBy,
      'driver_rejection_reason': driverRejectionReason,
      'driver_vehicle_info': driverVehicleInfo,
      'driver_license_info': driverLicenseInfo,
      'driver_documents': driverDocuments,
    };
  }

  bool get isCustomer => roles.contains('customer');
  bool get isDriver => roles.contains('driver');
  bool get isMerchant => roles.contains('merchant');
  bool get isSuperAdmin => roles.contains('super_admin');

  // Driver approval status helpers
  bool get isDriverPending => driverApprovalStatus == 'pending';
  bool get isDriverApproved => driverApprovalStatus == 'approved';
  bool get isDriverRejected => driverApprovalStatus == 'rejected';

  // Can driver accept orders?
  bool get canAcceptOrders => isDriver && isDriverApproved;
}
