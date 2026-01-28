import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/order_model.dart';
import '../config/constants.dart';
import 'app_providers.dart';

/// Admin Order Providers
///
/// Providers for admin order management features.

// ============================================
// ORDER LIST STREAMS (Real-time)
// ============================================

/// Stream đơn chờ xác nhận (PENDING_CONFIRMATION)
final pendingAdminOrdersProvider =
    StreamProvider.autoDispose<List<OrderModel>>((ref) {
  final repo = ref.watch(orderRepositoryProvider);
  return repo.streamPendingOrders(AppConstants.defaultMarketId);
});

/// Stream đơn đã confirm, chờ gán tài xế (CONFIRMED + READY_FOR_PICKUP)
final confirmedAdminOrdersProvider =
    StreamProvider.autoDispose<List<OrderModel>>((ref) {
  final repo = ref.watch(orderRepositoryProvider);
  return repo.streamConfirmedOrders(AppConstants.defaultMarketId);
});

/// Stream đơn đang thực hiện (ASSIGNED + PICKED_UP)
final activeAdminOrdersProvider =
    StreamProvider.autoDispose<List<OrderModel>>((ref) {
  final repo = ref.watch(orderRepositoryProvider);
  return repo.streamActiveOrders(AppConstants.defaultMarketId);
});

// ============================================
// COUNT PROVIDERS (for dashboard badges)
// ============================================

/// Count pending orders
final pendingOrdersCountProvider = Provider<AsyncValue<int>>((ref) {
  return ref.watch(pendingAdminOrdersProvider).whenData((orders) => orders.length);
});

/// Count confirmed orders waiting for driver
final confirmedOrdersCountProvider = Provider<AsyncValue<int>>((ref) {
  return ref.watch(confirmedAdminOrdersProvider).whenData((orders) => orders.length);
});

/// Count active orders (in progress)
final activeOrdersCountProvider = Provider<AsyncValue<int>>((ref) {
  return ref.watch(activeAdminOrdersProvider).whenData((orders) => orders.length);
});

/// Total pending + confirmed count (for badge)
final awaitingActionOrdersCountProvider = Provider<AsyncValue<int>>((ref) {
  final pending = ref.watch(pendingOrdersCountProvider);
  final confirmed = ref.watch(confirmedOrdersCountProvider);
  
  return pending.when(
    data: (p) => confirmed.when(
      data: (c) => AsyncValue.data(p + c),
      loading: () => AsyncValue.data(p),
      error: (e, s) => AsyncValue.data(p),
    ),
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});

// ============================================
// ORDER DETAIL
// ============================================

/// Order detail by ID (already exists in app_providers.dart as orderDetailProvider)
/// Using existing orderStreamProvider for real-time updates
