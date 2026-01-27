/// Order Item Model
/// 
/// Ánh xạ bảng `order_items` trong Supabase.
class OrderItemModel {
  final String id;
  final String orderId;
  final String? productId;
  final String productName;
  final int quantity;
  final int unitPrice;
  final int subtotal;
  final String? note;
  final DateTime createdAt;

  const OrderItemModel({
    required this.id,
    required this.orderId,
    this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.note,
    required this.createdAt,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      productId: json['product_id'] as String?,
      productName: json['product_name'] as String,
      quantity: json['quantity'] as int,
      unitPrice: json['unit_price'] as int,
      subtotal: json['subtotal'] as int,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'subtotal': subtotal,
      'note': note,
    };
  }
}
