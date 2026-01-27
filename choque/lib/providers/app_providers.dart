import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/order_repository.dart';
import '../data/repositories/product_repository.dart';
import '../data/repositories/merchant_repository.dart';
import '../data/repositories/driver_repository.dart';
import '../data/repositories/notification_repository.dart';
import '../data/repositories/promotion_repository.dart';
import '../data/repositories/search_repository.dart';
import '../data/repositories/review_repository.dart';
import '../data/repositories/favorite_repository.dart';
import '../data/models/profile_model.dart';
import '../data/models/order_model.dart';
import '../data/models/order_item_model.dart';
import '../data/models/product_model.dart';
import '../data/models/merchant_model.dart';
import '../data/models/notification_model.dart';
import '../data/models/promotion_model.dart';
import '../data/models/search_history_model.dart';
import '../data/models/shop_review_model.dart';
import '../data/models/driver_location_model.dart';
import '../services/distance_calculator_service.dart';
import '../config/constants.dart';

/// Parameters cho shopOrdersProvider
class ShopOrdersParams {
  final String shopId;
  final String? status;
  final int limit;

  const ShopOrdersParams({
    required this.shopId,
    this.status,
    this.limit = 50,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShopOrdersParams &&
          runtimeType == other.runtimeType &&
          shopId == other.shopId &&
          status == other.status &&
          limit == other.limit;

  @override
  int get hashCode => shopId.hashCode ^ status.hashCode ^ limit.hashCode;
}

// ============================================
// REPOSITORY PROVIDERS
// ============================================

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(supabaseClientProvider));
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(ref.read(supabaseClientProvider));
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.read(supabaseClientProvider));
});

final merchantRepositoryProvider = Provider<MerchantRepository>((ref) {
  return MerchantRepository(ref.read(supabaseClientProvider));
});

final driverRepositoryProvider = Provider<DriverRepository>((ref) {
  return DriverRepository(ref.read(supabaseClientProvider));
});

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository(ref.read(supabaseClientProvider));
});

final favoriteRepositoryProvider = Provider<FavoriteRepository>((ref) {
  return FavoriteRepository(ref.read(supabaseClientProvider));
});

// ============================================
// AUTH PROVIDERS
// ============================================

final currentUserProvider = StreamProvider<User?>((ref) {
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange.map(
    (state) => state.session?.user,
  );
});

final currentProfileProvider = FutureProvider<ProfileModel?>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return null;
  return ref.watch(authRepositoryProvider).getCurrentProfile();
});

// ============================================
// PRODUCT PROVIDERS
// ============================================

final allProductsProvider = FutureProvider<List<ProductModel>>((ref) async {
  return ref.watch(productRepositoryProvider).getAllProducts();
});

final productCategoriesProvider = FutureProvider<List<String>>((ref) async {
  return ref.watch(productRepositoryProvider).getCategories();
});

/// Alias cho productCategoriesProvider - dùng trong UserHomeScreen
final categoriesProvider = productCategoriesProvider;

final productSearchProvider = FutureProvider.family<List<ProductModel>, String>((ref, query) async {
  if (query.isEmpty) return [];
  return ref.watch(productRepositoryProvider).searchProducts(query);
});

// ============================================
// SEARCH PROVIDERS
// ============================================

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository(ref.read(supabaseClientProvider));
});

/// Merchant Search Provider
final merchantSearchProvider = FutureProvider.family<List<MerchantModel>, Map<String, dynamic>>((ref, params) async {
  final marketId = params['market_id'] as String;
  final query = params['query'] as String;
  if (query.isEmpty) return [];
  return ref.watch(merchantRepositoryProvider).searchMerchants(
    marketId: marketId,
    query: query,
  );
});

/// Unified Search Provider (products + shops)
final unifiedSearchProvider = FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>((ref, params) async {
  final query = params['query'] as String;
  final marketId = params['market_id'] as String;
  if (query.isEmpty) {
    return {'products': <ProductModel>[], 'shops': <MerchantModel>[]};
  }

  final productsFuture = ref.watch(productRepositoryProvider).searchProducts(query);
  final shopsFuture = ref.watch(merchantRepositoryProvider).searchMerchants(
    marketId: marketId,
    query: query,
  );

  final results = await Future.wait([productsFuture, shopsFuture]);
  return {
    'products': results[0] as List<ProductModel>,
    'shops': results[1] as List<MerchantModel>,
  };
});

/// Search History Provider
final searchHistoryProvider = FutureProvider<List<SearchHistoryModel>>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return [];
  return ref.watch(searchRepositoryProvider).getSearchHistory(userId: user.id);
});

/// Autocomplete suggestions provider
/// Trả về suggestions từ search history và popular searches
final searchSuggestionsProvider = FutureProvider.family<List<String>, String>((ref, query) async {
  if (query.length < 2) return [];
  
  final user = ref.read(currentUserProvider).value;
  final history = user != null 
      ? await ref.read(searchRepositoryProvider).getSearchHistory(userId: user.id, limit: 5)
      : <SearchHistoryModel>[];
  
  // Filter history items that match query
  final matchingHistory = history
      .where((item) => item.query.toLowerCase().contains(query.toLowerCase()))
      .map((item) => item.query)
      .toList();
  
  // Có thể thêm popular searches sau
  return matchingHistory;
});

// ============================================
// MERCHANT PROVIDERS
// ============================================

final merchantsProvider = FutureProvider<List<MerchantModel>>((ref) async {
  return ref.watch(merchantRepositoryProvider).getMerchantsByMarket(AppConstants.defaultMarketId);
});

final merchantDetailProvider = FutureProvider.family<MerchantModel, String>((ref, shopId) async {
  return ref.watch(merchantRepositoryProvider).getMerchantDetail(shopId);
});

final shopMenuProvider = FutureProvider.family<List<ShopMenuItem>, String>((ref, shopId) async {
  return ref.watch(merchantRepositoryProvider).getShopMenu(shopId);
});

/// Shop của merchant hiện tại
final myShopProvider = FutureProvider<MerchantModel?>((ref) async {
  try {
    return await ref.watch(merchantRepositoryProvider).getMyShop();
  } catch (e) {
    return null; // Merchant chưa có shop
  }
});

/// Đơn hàng của shop
final shopOrdersProvider = FutureProvider.family<List<OrderModel>, ShopOrdersParams>(
  (ref, params) async {
    return ref.watch(merchantRepositoryProvider).getShopOrders(
      shopId: params.shopId,
      status: params.status,
      limit: params.limit,
    );
  },
);

/// Thống kê shop
final shopStatsProvider = FutureProvider.family<Map<String, dynamic>, String>(
  (ref, shopId) async {
    return ref.watch(merchantRepositoryProvider).getShopStats(shopId: shopId);
  },
);

/// Category chính của shop (category có nhiều products nhất)
final shopPrimaryCategoryProvider = FutureProvider.family<String?, String>((ref, shopId) async {
  return ref.watch(merchantRepositoryProvider).getShopPrimaryCategory(shopId);
});

/// Image URL của shop (lấy từ product đầu tiên có image)
final shopImageUrlProvider = FutureProvider.family<String?, String>((ref, shopId) async {
  return ref.watch(merchantRepositoryProvider).getShopImageUrl(shopId);
});

/// Set các status không cần hiển thị - khai báo ngoài để tránh tạo mới mỗi lần filter
const _shopExcludedStatuses = {OrderStatus.completed, OrderStatus.canceled};

/// Real-time stream đơn hàng mới (chưa hoàn thành/hủy)
/// NOTE: Supabase Realtime stream API không hỗ trợ complex filters như NOT IN
/// Vì vậy filter ở Dart là cần thiết, nhưng đã tối ưu với Set lookup O(1)
final shopOrdersStreamProvider = StreamProvider.family<List<OrderModel>, String>(
  (ref, shopId) {
    return ref.watch(supabaseClientProvider)
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('shop_id', shopId)
        .order('created_at', ascending: false)
        .map((data) {
          // Tối ưu: Dùng Set.contains() thay vì multiple == checks
          // Set lookup là O(1) thay vì O(n) với List
          return (data as List)
              .map((json) => OrderModel.fromJson(json as Map<String, dynamic>))
              .where((order) => !_shopExcludedStatuses.contains(order.status))
              .toList();
        });
  },
);

// ============================================
// REVIEW PROVIDERS
// ============================================

final shopReviewsProvider = FutureProvider.family<List<ShopReviewModel>, String>((ref, shopId) async {
  return ref.watch(reviewRepositoryProvider).getShopReviews(shopId);
});

// ============================================
// FAVORITE PROVIDERS
// ============================================

final myFavoritesProvider = FutureProvider<List<MerchantModel>>((ref) async {
  return ref.watch(favoriteRepositoryProvider).getMyFavorites();
});

final isFavoriteProvider = FutureProvider.family<bool, String>((ref, shopId) async {
  // Trigger rebuild when auth state changes
  ref.watch(currentUserProvider);
  return ref.watch(favoriteRepositoryProvider).isFavorite(shopId);
});

// ============================================
// ORDER PROVIDERS
// ============================================

final myOrdersProvider = FutureProvider<List<OrderModel>>((ref) async {
  return ref.watch(orderRepositoryProvider).getMyOrders();
});

final orderDetailProvider = FutureProvider.family<OrderModel, String>((ref, orderId) async {
  return ref.watch(orderRepositoryProvider).getOrderDetail(orderId);
});

final orderItemsProvider = FutureProvider.family<List<OrderItemModel>, String>((ref, orderId) async {
  return ref.watch(orderRepositoryProvider).getOrderItems(orderId);
});

final orderStreamProvider = StreamProvider.family<OrderModel, String>((ref, orderId) {
  return ref.watch(orderRepositoryProvider).streamOrder(orderId);
});

final pendingOrdersProvider = FutureProvider<List<OrderModel>>((ref) async {
  return ref.watch(orderRepositoryProvider).getPendingOrders(AppConstants.defaultMarketId);
});

final assignedOrdersProvider = FutureProvider<List<OrderModel>>((ref) async {
  return ref.watch(orderRepositoryProvider).getAssignedOrders();
});

// ============================================
// DRIVER PROVIDERS
// ============================================

/// Thống kê driver
final driverStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final userId = ref.watch(currentUserProvider).value?.id;
  if (userId == null) return {};
  
  return ref.watch(driverRepositoryProvider).getDriverStats();
});

/// Set các status driver cần xử lý - khai báo ngoài để tái sử dụng
const _driverActiveStatuses = {OrderStatus.assigned, OrderStatus.pickedUp};

/// Real-time stream đơn hàng được gán cho driver
/// NOTE: Supabase Realtime stream API không hỗ trợ IN filters
/// Vì vậy filter ở Dart là cần thiết, nhưng đã tối ưu với Set lookup O(1)
final driverOrdersStreamProvider = StreamProvider<List<OrderModel>>((ref) {
  final userId = ref.watch(currentUserProvider).value?.id;
  if (userId == null) return Stream.value([]);
  
  return ref.watch(supabaseClientProvider)
      .from('orders')
      .stream(primaryKey: ['id'])
      .eq('driver_id', userId)
      .order('assigned_at', ascending: false)
      .map((data) {
        // Tối ưu: Dùng Set.contains() thay vì multiple == checks
        return (data as List)
            .map((json) => OrderModel.fromJson(json as Map<String, dynamic>))
            .where((order) => _driverActiveStatuses.contains(order.status))
            .toList();
      });
});

/// Đơn hàng có sẵn trong khu vực Market (để tài xế nhận)
final availableOrdersProvider = FutureProvider.family<List<OrderModel>, String>((ref, marketId) async {
  return ref.watch(driverRepositoryProvider).getAvailableOrders(marketId);
});

/// Stream realtime đơn hàng có sẵn
final availableOrdersStreamProvider = StreamProvider.family<List<OrderModel>, String>((ref, marketId) {
  return ref.watch(supabaseClientProvider)
      .from('orders')
      .stream(primaryKey: ['id'])
      .eq('market_id', marketId)
      .map((data) => (data as List)
          .map((json) => OrderModel.fromJson(json as Map<String, dynamic>))
          .where((order) => order.status == OrderStatus.readyForPickup)
          .toList());
});

/// Stream driver location for a specific driver (used by customer/admin to track)
final specificDriverLocationProvider = StreamProvider.family<DriverLocationModel?, String>((ref, driverId) {
  return ref.watch(supabaseClientProvider)
      .from('driver_locations')
      .stream(primaryKey: ['driver_id'])
      .eq('driver_id', driverId)
      .map((data) {
        if (data.isEmpty) return null;
        return DriverLocationModel.fromJson(data.first);
      });
});

/// Current driver's own location stream (used by driver app)
final driverLocationProvider = StreamProvider<DriverLocationModel?>((ref) {
  final userId = ref.watch(currentUserProvider).value?.id;
  if (userId == null) return Stream.value(null);
  
  return ref.watch(supabaseClientProvider)
      .from('driver_locations')
      .stream(primaryKey: ['driver_id'])
      .eq('driver_id', userId)
      .map((data) {
        if (data.isEmpty) return null;
        return DriverLocationModel.fromJson(data.first);
      });
});

// ============================================
// NOTIFICATION PROVIDERS
// ============================================

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.read(supabaseClientProvider));
});

/// Danh sách notifications của user
final notificationsProvider = FutureProvider.family<List<NotificationModel>, String?>((ref, type) async {
  return ref.watch(notificationRepositoryProvider).getMyNotifications(type: type);
});

/// Stream notifications real-time
final notificationsStreamProvider = StreamProvider<List<NotificationModel>>((ref) {
  return ref.watch(notificationRepositoryProvider).streamNotifications();
});

/// Stream notifications real-time với filter theo type
final notificationsStreamFilteredProvider = StreamProvider.family<List<NotificationModel>, String?>((ref, type) {
  return ref.watch(notificationRepositoryProvider).streamNotifications().map((notifications) {
    // Filter theo type nếu có
    if (type != null && type.isNotEmpty) {
      return notifications.where((n) => n.type.toLowerCase() == type.toLowerCase()).toList();
    }
    return notifications;
  });
});

/// Số lượng notifications chưa đọc (FutureProvider - cần refresh thủ công)
final unreadNotificationsCountProvider = FutureProvider<int>((ref) async {
  return ref.watch(notificationRepositoryProvider).getUnreadCount();
});

/// Số lượng notifications chưa đọc (StreamProvider - real-time updates)
/// Sử dụng stream để tự động cập nhật khi có notification mới
final unreadNotificationsCountStreamProvider = StreamProvider<int>((ref) {
  return ref.watch(notificationRepositoryProvider).streamNotifications().map((notifications) {
    // Đếm số notifications chưa đọc từ stream
    return notifications.where((n) => !n.isRead).length;
  });
});

// ============================================
// PROMOTION PROVIDERS
// ============================================

final promotionRepositoryProvider = Provider<PromotionRepository>((ref) {
  return PromotionRepository(ref.read(supabaseClientProvider));
});

/// Danh sách promotions có thể dùng cho user
final availablePromotionsProvider = FutureProvider.family<List<PromotionModel>, Map<String, dynamic>>((ref, params) async {
  final userId = params['user_id'] as String?;
  final marketId = params['market_id'] as String;
  final orderValue = params['order_value'] as int;
  
  if (userId == null) return [];
  
  return ref.watch(promotionRepositoryProvider).getAvailablePromotions(
    userId: userId,
    marketId: marketId,
    orderValue: orderValue,
  );
});

// ============================================
// DISTANCE CALCULATOR PROVIDER
// ============================================

final distanceCalculatorProvider = Provider<DistanceCalculatorService>((ref) {
  return DistanceCalculatorService();
});
