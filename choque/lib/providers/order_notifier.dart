import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/order_model.dart';
import '../data/models/location_model.dart';
import '../models/user_address.dart';
import '../models/cart_item.dart';
import '../providers/cart_provider.dart';
import '../providers/address_provider.dart';
import '../providers/app_providers.dart';
import '../providers/auth_provider.dart';
import '../config/constants.dart';
import '../data/models/promotion_model.dart';

/// Trạng thái của quá trình đặt hàng
class OrderState {
  final bool isPlacing;
  final String? error;
  final OrderModel? lastCreatedOrder;

  const OrderState({
    this.isPlacing = false,
    this.error,
    this.lastCreatedOrder,
  });

  OrderState copyWith({
    bool? isPlacing,
    String? error,
    OrderModel? lastCreatedOrder,
  }) {
    return OrderState(
      isPlacing: isPlacing ?? this.isPlacing,
      error: error,
      lastCreatedOrder: lastCreatedOrder ?? this.lastCreatedOrder,
    );
  }
}

class OrderNotifier extends Notifier<OrderState> {
  @override
  OrderState build() {
    return const OrderState();
  }

  Future<OrderModel?> placeOrder({
    required List<CartItem> cartItems,
    required UserAddress? selectedAddress,
    required LocationModel? temporaryAddress,
    required bool isUsingTemporaryAddress,
    required PromotionModel? selectedPromotion,
    required int voucherDiscount,
    required int deliveryFee,
    String? note,
  }) async {
    if (isUsingTemporaryAddress && temporaryAddress == null) {
      state = state.copyWith(error: 'Vui lòng chọn địa chỉ giao hàng');
      return null;
    }
    if (!isUsingTemporaryAddress && selectedAddress == null) {
      state = state.copyWith(error: 'Vui lòng chọn địa chỉ giao hàng');
      return null;
    }

    state = state.copyWith(isPlacing: true, error: null);

    try {
      final profile = ref.read(currentProfileProvider).value;
      final merchantRepo = ref.read(merchantRepositoryProvider);
      final orderRepo = ref.read(orderRepositoryProvider);

      if (cartItems.isEmpty) throw Exception('Giỏ hàng trống');

      final shopId = cartItems.first.shopId;
      final shopDetail = await merchantRepo.getMerchantDetail(shopId);

      // 1. Chuẩn bị dữ liệu items
      final itemsJson = cartItems
          .map((item) => {
                'product_id': item.id,
                'product_name': item.name,
                'quantity': item.quantity,
                'unit_price': item.price,
                'subtotal': item.subtotal,
                'note': '', 
              })
          .toList();

      // 2. Xác định Dropoff Location (Tối ưu: dùng lat/lng có sẵn)
      LocationModel dropoff;
      if (isUsingTemporaryAddress) {
        dropoff = temporaryAddress!;
      } else {
        dropoff = LocationModel(
          label: selectedAddress!.label,
          address: selectedAddress.details,
          lat: selectedAddress.lat ?? 0,
          lng: selectedAddress.lng ?? 0,
        );
        
        // Fallback geocoding nếu thiếu tọa độ (chỉ dành cho đia chỉ cũ chưa update)
        if (dropoff.lat == 0 || dropoff.lng == 0) {
           // Ở đây có thể call Vietmap nếu cần, nhưng plan là ép user có tọa độ
           // Để đơn giản hóa Phase 2, ta giả định user đã có tọa độ từ MapPicker
        }
      }

      // 3. Xác định Pickup Location (Tối ưu: dùng lat/lng có sẵn từ shop)
      final pickup = LocationModel(
        label: shopDetail.name,
        address: shopDetail.address ?? '',
        lat: shopDetail.lat ?? 0,
        lng: shopDetail.lng ?? 0,
      );

      // 4. Gọi Repository để tạo đơn
      final createdOrder = await orderRepo.createOrder(
        marketId: profile?.marketId ?? AppConstants.defaultMarketId,
        serviceType: ServiceType.food,
        shopId: shopId,
        pickup: pickup,
        dropoff: dropoff,
        deliveryFee: deliveryFee,
        items: itemsJson,
        customerName: profile?.fullName,
        customerPhone: profile?.phone,
        note: note,
        promotionId: selectedPromotion?.id,
        promotionCode: selectedPromotion?.code,
        discountAmount: voucherDiscount,
      );

      // 5. Cleanup & Update state
      ref.read(cartProvider.notifier).clear();
      ref.invalidate(myOrdersProvider);
      
      state = state.copyWith(isPlacing: false, lastCreatedOrder: createdOrder);
      return createdOrder;
    } catch (e) {
      state = state.copyWith(isPlacing: false, error: e.toString());
      return null;
    }
  }

  void resetState() {
    state = const OrderState();
  }
}

final orderNotifierProvider = NotifierProvider<OrderNotifier, OrderState>(() {
  return OrderNotifier();
});
