import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/merchant_repository.dart';
import 'app_providers.dart';

/// Provider for MerchantRepository
final merchantRepositoryProvider = Provider<MerchantRepository>((ref) {
  final client = ref.read(supabaseClientProvider);
  return MerchantRepository(client);
});

/// All merchants for admin (includes pending, active, rejected)
final allAdminMerchantsProvider =
    FutureProvider.autoDispose<List<AdminMerchantInfo>>((ref) async {
  final repo = ref.read(merchantRepositoryProvider);
  const marketId = 'default'; // TODO: Get from config or user selection
  return await repo.getAllMerchantsForAdmin(marketId: marketId);
});

/// Pending merchants awaiting approval
final pendingMerchantsProvider =
    FutureProvider.autoDispose<List<AdminMerchantInfo>>((ref) async {
  final repo = ref.read(merchantRepositoryProvider);
  const marketId = 'default';
  return await repo.getAllMerchantsForAdmin(
    marketId: marketId,
    statusFilter: 'pending',
  );
});

/// Active (approved) merchants
final activeMerchantsProvider =
    FutureProvider.autoDispose<List<AdminMerchantInfo>>((ref) async {
  final repo = ref.read(merchantRepositoryProvider);
  const marketId = 'default';
  return await repo.getAllMerchantsForAdmin(
    marketId: marketId,
    statusFilter: 'active',
  );
});

/// Rejected merchants
final rejectedMerchantsProvider =
    FutureProvider.autoDispose<List<AdminMerchantInfo>>((ref) async {
  final repo = ref.read(merchantRepositoryProvider);
  const marketId = 'default';
  return await repo.getAllMerchantsForAdmin(
    marketId: marketId,
    statusFilter: 'rejected',
  );
});

/// Merchant detail by ID
final merchantDetailProvider = FutureProvider.autoDispose
    .family<AdminMerchantInfo?, String>((ref, shopId) async {
  final allMerchants = await ref.watch(allAdminMerchantsProvider.future);
  return allMerchants.where((m) => m.id == shopId).firstOrNull;
});

/// Merchant stats by ID
final merchantStatsProvider = FutureProvider.autoDispose
    .family<AdminMerchantStats, String>((ref, shopId) async {
  final repo = ref.read(merchantRepositoryProvider);
  return await repo.getMerchantStatsForAdmin(shopId);
});

/// Count of pending merchants for badge
final pendingMerchantsCountProvider = Provider<AsyncValue<int>>((ref) {
  return ref.watch(pendingMerchantsProvider).whenData((list) => list.length);
});

/// Invalidate all merchant providers (for refresh)
void invalidateAdminMerchantProviders(WidgetRef ref) {
  ref.invalidate(allAdminMerchantsProvider);
  ref.invalidate(pendingMerchantsProvider);
  ref.invalidate(activeMerchantsProvider);
  ref.invalidate(rejectedMerchantsProvider);
}
