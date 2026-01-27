import 'location_model.dart';

/// Order Status Enum
/// 
/// Các trạng thái đơn hàng theo State Machine trong Brief.
enum OrderStatus {
  pendingConfirmation,
  confirmed,
  readyForPickup,
  assigned,
  pickedUp,
  completed,
  canceled;

  static OrderStatus fromString(String s) {
    switch (s) {
      case 'PENDING_CONFIRMATION': return OrderStatus.pendingConfirmation;
      case 'CONFIRMED': return OrderStatus.confirmed;
      case 'READY_FOR_PICKUP': return OrderStatus.readyForPickup;
      case 'ASSIGNED': return OrderStatus.assigned;
      case 'PICKED_UP': return OrderStatus.pickedUp;
      case 'COMPLETED': return OrderStatus.completed;
      case 'CANCELED': return OrderStatus.canceled;
      default: return OrderStatus.pendingConfirmation;
    }
  }

  String toDbString() {
    switch (this) {
      case OrderStatus.pendingConfirmation: return 'PENDING_CONFIRMATION';
      case OrderStatus.confirmed: return 'CONFIRMED';
      case OrderStatus.readyForPickup: return 'READY_FOR_PICKUP';
      case OrderStatus.assigned: return 'ASSIGNED';
      case OrderStatus.pickedUp: return 'PICKED_UP';
      case OrderStatus.completed: return 'COMPLETED';
      case OrderStatus.canceled: return 'CANCELED';
    }
  }

  String get displayName {
    switch (this) {
      case OrderStatus.pendingConfirmation: return 'Chờ xác nhận';
      case OrderStatus.confirmed: return 'Đang chuẩn bị';
      case OrderStatus.readyForPickup: return 'Sẵn sàng';
      case OrderStatus.assigned: return 'Đã gán tài xế';
      case OrderStatus.pickedUp: return 'Đã lấy hàng';
      case OrderStatus.completed: return 'Hoàn thành';
      case OrderStatus.canceled: return 'Đã hủy';
    }
  }
}

/// Service Type Enum
enum ServiceType {
  food,
  ride,
  delivery;

  static ServiceType fromString(String s) {
    switch (s) {
      case 'ride': return ServiceType.ride;
      case 'delivery': return ServiceType.delivery;
      default: return ServiceType.food;
    }
  }
}

/// Order Model
/// 
/// Ánh xạ bảng `orders` trong Supabase.
class OrderModel {
  final String id;
  final int orderNumber;
  final String marketId;
  final ServiceType serviceType;
  final String customerId;
  final String? driverId;
  final String? shopId;
  final OrderStatus status;
  final LocationModel pickup;
  final LocationModel dropoff;
  final int deliveryFee;
  final int itemsTotal;
  final int totalAmount;
  final int discountAmount;
  final String? promotionId;
  final String? promotionCode;
  final String? customerName;
  final String? customerPhone;
  final String? note;
  final String? cancelReason;
  final String? shopName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? confirmedAt;
  final DateTime? assignedAt;
  final DateTime? pickedUpAt;
  final DateTime? completedAt;
  final DateTime? canceledAt;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.marketId,
    required this.serviceType,
    required this.customerId,
    this.driverId,
    this.shopId,
    required this.status,
    required this.pickup,
    required this.dropoff,
    required this.deliveryFee,
    required this.itemsTotal,
    required this.totalAmount,
    this.discountAmount = 0,
    this.promotionId,
    this.promotionCode,
    this.customerName,
    this.customerPhone,
    this.note,
    this.cancelReason,
    this.shopName,
    required this.createdAt,
    required this.updatedAt,
    this.confirmedAt,
    this.assignedAt,
    this.pickedUpAt,
    this.completedAt,
    this.canceledAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      orderNumber: json['order_number'] as int,
      marketId: json['market_id'] as String,
      serviceType: ServiceType.fromString(json['service_type'] as String),
      customerId: json['customer_id'] as String,
      driverId: json['driver_id'] as String?,
      shopId: json['shop_id'] as String?,
      status: OrderStatus.fromString(json['status'] as String),
      pickup: LocationModel.fromJson(json['pickup'] as Map<String, dynamic>),
      dropoff: LocationModel.fromJson(json['dropoff'] as Map<String, dynamic>),
      deliveryFee: json['delivery_fee'] as int? ?? 0,
      itemsTotal: json['items_total'] as int? ?? 0,
      totalAmount: json['total_amount'] as int? ?? 0,
      discountAmount: json['discount_amount'] as int? ?? 0,
      promotionId: json['promotion_id'] as String?,
      promotionCode: json['promotion_code'] as String?,
      customerName: json['customer_name'] as String?,
      customerPhone: json['customer_phone'] as String?,
      note: json['note'] as String?,
      cancelReason: json['cancel_reason'] as String?,
      shopName: json['shop_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      confirmedAt: json['confirmed_at'] != null ? DateTime.parse(json['confirmed_at'] as String) : null,
      assignedAt: json['assigned_at'] != null ? DateTime.parse(json['assigned_at'] as String) : null,
      pickedUpAt: json['picked_up_at'] != null ? DateTime.parse(json['picked_up_at'] as String) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
      canceledAt: json['canceled_at'] != null ? DateTime.parse(json['canceled_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'market_id': marketId,
      'service_type': serviceType.name,
      'customer_id': customerId,
      'driver_id': driverId,
      'shop_id': shopId,
      'status': status.toDbString(),
      'pickup': pickup.toJson(),
      'dropoff': dropoff.toJson(),
      'delivery_fee': deliveryFee,
      'items_total': itemsTotal,
      'total_amount': totalAmount,
      'discount_amount': discountAmount,
      'promotion_id': promotionId,
      'promotion_code': promotionCode,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'note': note,
    };
  }

  /// Kiểm tra xem đơn có thể hủy được không (chỉ khi PENDING_CONFIRMATION)
  bool get canCancel => status == OrderStatus.pendingConfirmation;
  
  /// Kiểm tra xem đơn đã hoàn thành chưa
  bool get isCompleted => status == OrderStatus.completed;
  
  /// Kiểm tra xem đơn đã bị hủy chưa
  bool get isCanceled => status == OrderStatus.canceled;

  /// Display alias for delivery fee
  int get shippingFee => deliveryFee;
}
