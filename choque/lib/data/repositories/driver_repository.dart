import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../models/order_model.dart';
import '../models/driver_location_model.dart';
import '../../config/constants.dart';

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

  /// Lấy danh sách đơn hàng có sẵn cho tài xế
  Future<List<OrderModel>> getAvailableOrders(String marketId) async {
    final response = await _client.rpc(
      'get_available_orders',
      params: {'p_market_id': marketId},
    ).timeout(AppConstants.apiTimeout);

    return (response as List).map((json) => OrderModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Tài xế nhận đơn
  Future<void> acceptOrder(String orderId) async {
    await _client.rpc(
      'driver_accept_order',
      params: {'p_order_id': orderId},
    ).timeout(AppConstants.apiTimeout);
  }

  /// Tài xế từ chối / hủy đơn (khi đang ở trạng thái ASSIGNED)
  Future<void> rejectOrder(String orderId, {String? reason}) async {
    await _client.rpc(
      'driver_reject_order',
      params: {
        'p_order_id': orderId,
        'p_reason': reason,
      },
    ).timeout(AppConstants.apiTimeout);
  }
}
