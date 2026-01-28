import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_model.dart';
import '../models/order_item_model.dart';
import '../models/location_model.dart';
import '../../config/constants.dart';

/// Order Repository
///
/// Xử lý tất cả các thao tác liên quan đến đơn hàng với Supabase.
class OrderRepository {
  final SupabaseClient _client;

  OrderRepository(this._client);

  // Factory constructor sử dụng default client
  factory OrderRepository.instance() {
    return OrderRepository(Supabase.instance.client);
  }

  // ============================================
  // CUSTOMER FUNCTIONS
  // ============================================

  /// Tạo đơn hàng mới
  Future<OrderModel> createOrder({
    required String marketId,
    required ServiceType serviceType,
    String? shopId,
    required LocationModel pickup,
    required LocationModel dropoff,
    int deliveryFee = 0,
    List<Map<String, dynamic>> items = const [],
    String? customerName,
    String? customerPhone,
    String? note,
    String? promotionId,
    String? promotionCode,
    int discountAmount = 0,
  }) async {
    final params = <String, dynamic>{
      'p_market_id': marketId,
      'p_service_type': serviceType.name,
      'p_shop_id': shopId,
      'p_pickup': pickup.toJson(),
      'p_dropoff': dropoff.toJson(),
      'p_items': items,
      'p_delivery_fee': deliveryFee,
      'p_customer_name': customerName,
      'p_customer_phone': customerPhone,
      'p_note': note,
    };

    // Thêm promotion params nếu có
    if (promotionId != null) {
      params['p_promotion_id'] = promotionId;
      params['p_discount_amount'] = discountAmount;
    }

    final response = await _client
        .rpc('create_order', params: params)
        .timeout(AppConstants.apiTimeout);

    final order = OrderModel.fromJson(response as Map<String, dynamic>);

    // Nếu có promotion, apply sau khi tạo order
    if (promotionId != null && discountAmount > 0) {
      try {
        await _client
            .rpc(
              'apply_promotion',
              params: {'p_order_id': order.id, 'p_promotion_id': promotionId},
            )
            .timeout(AppConstants.apiTimeout);

        // Fetch lại order để lấy discount đã apply
        final updatedOrder = await _client
            .from('orders')
            .select()
            .eq('id', order.id)
            .single()
            .timeout(AppConstants.apiTimeout);

        return OrderModel.fromJson(updatedOrder);
      } catch (e) {
        // Nếu apply promotion fail, vẫn trả về order đã tạo
        return order;
      }
    }

    return order;
  }

  /// Hủy đơn hàng (chỉ khi PENDING_CONFIRMATION)
  Future<OrderModel> cancelOrderByCustomer(
    String orderId, {
    String? reason,
  }) async {
    final response = await _client
        .rpc(
          'cancel_order_by_customer',
          params: {'p_order_id': orderId, 'p_reason': reason},
        )
        .timeout(AppConstants.apiTimeout);

    return OrderModel.fromJson(response as Map<String, dynamic>);
  }

  /// Lấy danh sách đơn hàng của customer
  Future<List<OrderModel>> getMyOrders({int limit = 50}) async {
    final response = await _client
        .from('orders')
        .select()
        .order('created_at', ascending: false)
        .limit(limit)
        .timeout(AppConstants.apiTimeout);

    return (response as List).map((json) => OrderModel.fromJson(json)).toList();
  }

  /// Lấy chi tiết đơn hàng
  Future<OrderModel> getOrderDetail(String orderId) async {
    final response = await _client
        .from('orders')
        .select()
        .eq('id', orderId)
        .single()
        .timeout(AppConstants.apiTimeout);

    return OrderModel.fromJson(response);
  }

  /// Lấy danh sách items trong đơn hàng
  Future<List<OrderItemModel>> getOrderItems(String orderId) async {
    final response = await _client
        .from('order_items')
        .select()
        .eq('order_id', orderId)
        .timeout(AppConstants.apiTimeout);

    return (response as List)
        .map((json) => OrderItemModel.fromJson(json))
        .toList();
  }

  /// Stream theo dõi thay đổi đơn hàng (realtime)
  Stream<OrderModel> streamOrder(String orderId) {
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', orderId)
        .map((data) => OrderModel.fromJson(data.first));
  }

  // ============================================
  // ADMIN FUNCTIONS
  // ============================================

  /// Lấy danh sách đơn hàng đang chờ xác nhận
  Future<List<OrderModel>> getPendingOrders(String marketId) async {
    final response = await _client
        .from('orders')
        .select()
        .eq('market_id', marketId)
        .eq('status', 'PENDING_CONFIRMATION')
        .order('created_at')
        .timeout(AppConstants.apiTimeout);

    return (response as List).map((json) => OrderModel.fromJson(json)).toList();
  }

  /// Xác nhận đơn hàng (Admin)
  Future<OrderModel> confirmOrder(String orderId) async {
    final response = await _client
        .rpc('confirm_order', params: {'p_order_id': orderId})
        .timeout(AppConstants.apiTimeout);

    return OrderModel.fromJson(response as Map<String, dynamic>);
  }

  /// Gán tài xế cho đơn hàng (Admin)
  Future<OrderModel> assignDriver(String orderId, String driverId) async {
    final response = await _client
        .rpc(
          'assign_driver',
          params: {'p_order_id': orderId, 'p_driver_id': driverId},
        )
        .timeout(AppConstants.apiTimeout);

    return OrderModel.fromJson(response as Map<String, dynamic>);
  }

  /// Hủy đơn hàng bởi Admin
  Future<OrderModel> cancelOrderByAdmin(String orderId, String reason) async {
    final response = await _client
        .rpc(
          'cancel_order_by_admin',
          params: {'p_order_id': orderId, 'p_reason': reason},
        )
        .timeout(AppConstants.apiTimeout);

    return OrderModel.fromJson(response as Map<String, dynamic>);
  }

  /// Lấy đơn đã confirm, chờ gán tài xế (CONFIRMED + READY_FOR_PICKUP)
  Future<List<OrderModel>> getConfirmedOrders(String marketId) async {
    final response = await _client
        .from('orders')
        .select()
        .eq('market_id', marketId)
        .inFilter('status', ['CONFIRMED', 'READY_FOR_PICKUP'])
        .order('created_at')
        .timeout(AppConstants.apiTimeout);

    return (response as List).map((json) => OrderModel.fromJson(json)).toList();
  }

  /// Lấy đơn đang thực hiện (ASSIGNED + PICKED_UP)
  Future<List<OrderModel>> getActiveOrders(String marketId) async {
    final response = await _client
        .from('orders')
        .select()
        .eq('market_id', marketId)
        .inFilter('status', ['ASSIGNED', 'PICKED_UP'])
        .order('assigned_at', ascending: false)
        .timeout(AppConstants.apiTimeout);

    return (response as List).map((json) => OrderModel.fromJson(json)).toList();
  }

  /// Gán lại tài xế với lý do (Admin)
  Future<OrderModel> reassignDriver(
    String orderId,
    String newDriverId,
    String reason,
  ) async {
    final response = await _client
        .rpc(
          'reassign_driver',
          params: {
            'p_order_id': orderId,
            'p_new_driver_id': newDriverId,
            'p_reason': reason,
          },
        )
        .timeout(AppConstants.apiTimeout);

    return OrderModel.fromJson(response as Map<String, dynamic>);
  }

  /// Stream đơn chờ xác nhận (real-time)
  Stream<List<OrderModel>> streamPendingOrders(String marketId) {
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('market_id', marketId)
        .map((data) => data
            .where((json) => json['status'] == 'PENDING_CONFIRMATION')
            .map((json) => OrderModel.fromJson(json))
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt)));
  }

  /// Stream đơn chờ gán tài xế (real-time)
  Stream<List<OrderModel>> streamConfirmedOrders(String marketId) {
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('market_id', marketId)
        .map((data) => data
            .where((json) =>
                json['status'] == 'CONFIRMED' ||
                json['status'] == 'READY_FOR_PICKUP')
            .map((json) => OrderModel.fromJson(json))
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt)));
  }

  /// Stream đơn đang thực hiện (real-time)
  Stream<List<OrderModel>> streamActiveOrders(String marketId) {
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('market_id', marketId)
        .map((data) => data
            .where((json) =>
                json['status'] == 'ASSIGNED' || json['status'] == 'PICKED_UP')
            .map((json) => OrderModel.fromJson(json))
            .toList()
          ..sort((a, b) => (b.assignedAt ?? b.createdAt)
              .compareTo(a.assignedAt ?? a.createdAt)));
  }

  // ============================================
  // DRIVER FUNCTIONS
  // ============================================

  /// Lấy danh sách đơn hàng được gán cho driver
  Future<List<OrderModel>> getAssignedOrders() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final response = await _client
        .from('orders')
        .select()
        .eq('driver_id', userId)
        .inFilter('status', ['ASSIGNED', 'PICKED_UP'])
        .order('assigned_at', ascending: false)
        .timeout(AppConstants.apiTimeout);

    return (response as List).map((json) => OrderModel.fromJson(json)).toList();
  }

  /// Cập nhật trạng thái đơn hàng (Driver)
  Future<OrderModel> updateOrderStatus(
    String orderId,
    OrderStatus newStatus,
  ) async {
    final response = await _client
        .rpc(
          'update_order_status',
          params: {
            'p_order_id': orderId,
            'p_new_status': newStatus.toDbString(),
          },
        )
        .timeout(AppConstants.apiTimeout);

    return OrderModel.fromJson(response as Map<String, dynamic>);
  }
}
