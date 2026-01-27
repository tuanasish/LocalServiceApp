import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../../config/constants.dart';

/// Driver Location Model
class DriverLocationModel {
  final String driverId;
  final String? orderId;
  final double lat;
  final double lng;
  final double? heading;
  final double? speed;
  final double? accuracy;
  final DateTime updatedAt;

  const DriverLocationModel({
    required this.driverId,
    this.orderId,
    required this.lat,
    required this.lng,
    this.heading,
    this.speed,
    this.accuracy,
    required this.updatedAt,
  });

  factory DriverLocationModel.fromJson(Map<String, dynamic> json) {
    return DriverLocationModel(
      driverId: json['driver_id'] as String,
      orderId: json['order_id'] as String?,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

/// Driver Repository
/// 
/// Xử lý các thao tác dành cho tài xế.
class DriverRepository {
  final SupabaseClient _client;

  DriverRepository(this._client);

  factory DriverRepository.instance() {
    return DriverRepository(Supabase.instance.client);
  }

  /// Bật trạng thái Online
  Future<ProfileModel> goOnline() async {
    final response = await _client.rpc('driver_go_online')
        .timeout(AppConstants.apiTimeout);

    return ProfileModel.fromJson(response as Map<String, dynamic>);
  }

  /// Tắt trạng thái (Offline)
  Future<ProfileModel> goOffline() async {
    final response = await _client.rpc('driver_go_offline')
        .timeout(AppConstants.apiTimeout);

    return ProfileModel.fromJson(response as Map<String, dynamic>);
  }

  /// Cập nhật vị trí tài xế
  Future<DriverLocationModel> updateLocation({
    String? orderId,
    required double lat,
    required double lng,
    double? heading,
    double? speed,
    double? accuracy,
  }) async {
    final response = await _client.rpc(
      'update_driver_location',
      params: {
        'p_order_id': orderId,
        'p_lat': lat,
        'p_lng': lng,
        'p_heading': heading,
        'p_speed': speed,
        'p_accuracy': accuracy,
      },
    ).timeout(AppConstants.apiTimeout);

    return DriverLocationModel.fromJson(response as Map<String, dynamic>);
  }

  /// Lấy danh sách tài xế online (Admin)
  Future<List<Map<String, dynamic>>> getAvailableDrivers(String marketId) async {
    final response = await _client
        .from('v_available_drivers')
        .select()
        .eq('market_id', marketId)
        .timeout(AppConstants.apiTimeout);

    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Lấy thống kê driver
  Future<Map<String, dynamic>> getDriverStats({
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');
    
    final response = await _client.rpc(
      'get_driver_stats',
      params: {
        'p_driver_id': userId,
        'p_date_from': dateFrom?.toIso8601String(),
        'p_date_to': dateTo?.toIso8601String(),
      },
    ).timeout(AppConstants.apiTimeout);
    
    return response as Map<String, dynamic>;
  }
}
