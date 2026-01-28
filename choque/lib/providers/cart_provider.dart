import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/order_model.dart';
import '../data/models/order_item_model.dart';

/// CartItem - Đại diện cho một món hàng trong giỏ hàng
class CartItem {
  final String id; // productId
  final String shopId; // ID cửa hàng
  final String shopName; // Tên cửa hàng
  final String name; // Tên sản phẩm
  final String? description; // Mô tả sản phẩm
  final String? imageUrl; // Link hình ảnh
  final int price; // Giá (đơn vị: VND)
  final int quantity; // Số lượng

  const CartItem({
    required this.id,
    required this.shopId,
    required this.shopName,
    required this.name,
    this.description,
    this.imageUrl,
    required this.price,
    this.quantity = 1,
  });

  CartItem copyWith({int? quantity}) {
    return CartItem(
      id: id,
      shopId: shopId,
      shopName: shopName,
      name: name,
      description: description,
      imageUrl: imageUrl,
      price: price,
      quantity: quantity ?? this.quantity,
    );
  }

  /// Tổng tiền của item này
  int get subtotal => price * quantity;
}

/// CartNotifier - Quản lý trạng thái giỏ hàng
class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() {
    return [];
  }

  /// Thêm item vào giỏ hàng
  void addItem(CartItem item) {
    final existingIndex = state.indexWhere(
      (i) => i.id == item.id && i.shopId == item.shopId,
    );
    if (existingIndex != -1) {
      // Tăng số lượng nếu đã có
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == existingIndex)
            state[i].copyWith(quantity: state[i].quantity + 1)
          else
            state[i],
      ];
    } else {
      state = [...state, item];
    }
  }

  /// Tăng số lượng item
  void increaseQuantity(String itemId, String shopId) {
    state = [
      for (final item in state)
        if (item.id == itemId && item.shopId == shopId)
          item.copyWith(quantity: item.quantity + 1)
        else
          item,
    ];
  }

  /// Giảm số lượng item (xóa nếu quantity = 0)
  void decreaseQuantity(String itemId, String shopId) {
    state = [
      for (final item in state)
        if (item.id == itemId && item.shopId == shopId)
          if (item.quantity > 1)
            item.copyWith(quantity: item.quantity - 1)
          else
            null // Mark for removal
        else
          item,
    ].whereType<CartItem>().toList();
  }

  /// Xóa item khỏi giỏ
  void removeItem(String itemId, String shopId) {
    state = state
        .where((item) => !(item.id == itemId && item.shopId == shopId))
        .toList();
  }

  /// Xóa toàn bộ giỏ hàng
  void clear() {
    state = [];
  }

  /// Xóa tất cả items của một cửa hàng cụ thể
  void clearShop(String shopId) {
    state = state.where((item) => item.shopId != shopId).toList();
  }

  /// Tổng tiền giỏ hàng
  int get totalPrice => state.fold(0, (sum, item) => sum + item.subtotal);

  /// Tổng số lượng items
  int get itemCount => state.fold(0, (sum, item) => sum + item.quantity);

  /// Lấy số lượng của một item cụ thể trong giỏ
  int getItemQuantity(String itemId, String shopId) {
    final item = state
        .where((i) => i.id == itemId && i.shopId == shopId)
        .firstOrNull;
    return item?.quantity ?? 0;
  }

  /// Kiểm tra giỏ hàng có items từ cửa hàng khác không
  bool hasItemsFromOtherShop(String currentShopId) {
    return state.any((item) => item.shopId != currentShopId);
  }

  /// Lấy ID cửa hàng hiện tại trong giỏ (nếu có)
  String? get currentShopId => state.isNotEmpty ? state.first.shopId : null;

  /// Reorder từ một order đã hoàn thành
  /// Returns true nếu thành công, false nếu cần confirm (cart có items từ shop khác)
  bool reorderFromOrder({
    required OrderModel order,
    required List<OrderItemModel> orderItems,
    required String shopName,
    bool forceClear = false,
  }) {
    if (orderItems.isEmpty) return false;

    // Nếu force clear hoặc cart rỗng, clear và add items
    if (forceClear || state.isEmpty) {
      state = orderItems
          .map(
            (item) => CartItem(
              id: item.productId ?? item.id, // Fallback nếu productId null
              shopId: order.shopId ?? '',
              shopName: shopName,
              name: item.productName,
              price: item.unitPrice,
              quantity: item.quantity,
            ),
          )
          .toList();
      return true;
    }

    // Check conflict: cart có items từ shop khác
    final currentShopId = state.first.shopId;
    if (order.shopId != null && currentShopId != order.shopId) {
      return false; // Cần confirm từ user
    }

    // Add items vào cart hiện tại
    for (final item in orderItems) {
      addItem(
        CartItem(
          id: item.productId ?? item.id,
          shopId: order.shopId ?? '',
          shopName: shopName,
          name: item.productName,
          price: item.unitPrice,
          quantity: item.quantity,
        ),
      );
    }
    return true;
  }
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(
  CartNotifier.new,
);

/// Provider để lấy tổng tiền giỏ hàng
final cartTotalProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0, (sum, item) => sum + item.subtotal);
});

/// Provider để lấy tổng số lượng items
final cartItemCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0, (sum, item) => sum + item.quantity);
});
