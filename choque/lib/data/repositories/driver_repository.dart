import 'package:flutter/foundation.dart';
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
    final response = await _client
        .rpc('driver_go_online')
        .timeout(AppConstants.apiTimeout);

    return ProfileModel.fromJson(response as Map<String, dynamic>);
  }

  /// Tắt trạng thái (Offline)
  Future<ProfileModel> goOffline() async {
    final response = await _client
        .rpc('driver_go_offline')
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
    try {
      final response = await _client
          .rpc(
            'update_driver_location',
            params: {
              'p_order_id': orderId,
              'p_lat': lat,
              'p_lng': lng,
              'p_heading': heading,
              'p_speed': speed,
              'p_accuracy': accuracy,
            },
          )
          .timeout(AppConstants.apiTimeout);

      // Log success (for debugging)
      if (kDebugMode) {
        print(
          '[DriverRepo] Location updated: ($lat, $lng) for order: $orderId',
        );
      }

      return DriverLocationModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      // Log error
      if (kDebugMode) {
        print('[DriverRepo] Failed to update location: $e');
      }

      // Re-throw để LocationTrackingService có thể retry
      rethrow;
    }
  }

  /// Lấy danh sách tài xế online (Admin)
  Future<List<Map<String, dynamic>>> getAvailableDrivers(
    String marketId,
  ) async {
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

    final response = await _client
        .rpc(
          'get_driver_stats',
          params: {
            'p_driver_id': userId,
            'p_date_from': dateFrom?.toIso8601String(),
            'p_date_to': dateTo?.toIso8601String(),
          },
        )
        .timeout(AppConstants.apiTimeout);

    return response as Map<String, dynamic>;
  }

  /// Lấy danh sách đơn hàng có sẵn cho tài xế
  Future<List<OrderModel>> getAvailableOrders(String marketId) async {
    final response = await _client
        .rpc('get_available_orders', params: {'p_market_id': marketId})
        .timeout(AppConstants.apiTimeout);

    return (response as List)
        .map((json) => OrderModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Tài xế nhận đơn
  Future<void> acceptOrder(String orderId) async {
    await _client
        .rpc('driver_accept_order', params: {'p_order_id': orderId})
        .timeout(AppConstants.apiTimeout);
  }

  /// Tài xế từ chối / hủy đơn (khi đang ở trạng thái ASSIGNED)
  Future<void> rejectOrder(String orderId, {String? reason}) async {
    await _client
        .rpc(
          'driver_reject_order',
          params: {'p_order_id': orderId, 'p_reason': reason},
        )
        .timeout(AppConstants.apiTimeout);
  }

  // ============================================
  // ADMIN METHODS - Driver Management
  // ============================================

  /// Get all drivers (Admin only)
  /// Filters: approvalStatus (pending/approved/rejected), driverStatus (online/offline/busy)
  Future<List<ProfileModel>> getAllDrivers({
    String? approvalStatus,
    String? driverStatus,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final response = await _client
          .rpc(
            'get_all_drivers',
            params: {
              'p_approval_status': approvalStatus,
              'p_driver_status': driverStatus,
              'p_limit': limit,
              'p_offset': offset,
            },
          )
          .timeout(AppConstants.apiTimeout);

      if (kDebugMode) {
        print('[DriverRepo] Fetched ${response.length} drivers');
      }

      return (response as List)
          .map((json) => ProfileModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('[DriverRepo] Failed to get all drivers: $e');
      }
      rethrow;
    }
  }

  /// Approve driver (Admin only)
  Future<ProfileModel> approveDriver(String driverId, {String? notes}) async {
    try {
      final response = await _client
          .rpc(
            'approve_driver',
            params: {'p_driver_id': driverId, 'p_admin_notes': notes},
          )
          .timeout(AppConstants.apiTimeout);

      if (kDebugMode) {
        print('[DriverRepo] Approved driver: $driverId');
      }

      return ProfileModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) {
        print('[DriverRepo] Failed to approve driver: $e');
      }
      rethrow;
    }
  }

  /// Reject driver (Admin only)
  Future<ProfileModel> rejectDriver(String driverId, String reason) async {
    try {
      final response = await _client
          .rpc(
            'reject_driver',
            params: {'p_driver_id': driverId, 'p_reason': reason},
          )
          .timeout(AppConstants.apiTimeout);

      if (kDebugMode) {
        print('[DriverRepo] Rejected driver: $driverId');
      }

      return ProfileModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) {
        print('[DriverRepo] Failed to reject driver: $e');
      }
      rethrow;
    }
  }

  /// Get driver statistics (Admin or driver themselves)
  Future<Map<String, dynamic>> getDriverStatistics(String driverId) async {
    try {
      final response = await _client
          .rpc('get_driver_statistics', params: {'p_driver_id': driverId})
          .timeout(AppConstants.apiTimeout);

      if (kDebugMode) {
        print('[DriverRepo] Fetched statistics for driver: $driverId');
      }

      return response as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('[DriverRepo] Failed to get driver statistics: $e');
      }
      rethrow;
    }
  }

  /// Get driver order history (Admin only)
  Future<List<OrderModel>> getDriverOrderHistory(
    String driverId, {
    int limit = 50,
  }) async {
    try {
      final response = await _client
          .from('orders')
          .select()
          .eq('driver_id', driverId)
          .order('created_at', ascending: false)
          .limit(limit)
          .timeout(AppConstants.apiTimeout);

      if (kDebugMode) {
        print(
          '[DriverRepo] Fetched ${(response as List).length} orders for driver: $driverId',
        );
      }

      return (response as List)
          .map((json) => OrderModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('[DriverRepo] Failed to get driver order history: $e');
      }
      rethrow;
    }
  }

  /// Get driver by ID (Admin only)
  Future<ProfileModel> getDriverById(String driverId) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('user_id', driverId)
          .single()
          .timeout(AppConstants.apiTimeout);

      if (kDebugMode) {
        print('[DriverRepo] Fetched driver profile: $driverId');
      }

      return ProfileModel.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        print('[DriverRepo] Failed to get driver by ID: $e');
      }
      rethrow;
    }
  }
}
