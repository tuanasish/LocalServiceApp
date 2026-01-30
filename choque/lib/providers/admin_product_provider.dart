import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/product_repository.dart';

/// =============================================================
/// ADMIN PRODUCT PROVIDERS
/// =============================================================

/// Provider for ProductRepository instance
final adminProductRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository.instance();
});

/// All products for admin (includes inactive)
final allAdminProductsProvider =
    FutureProvider.autoDispose<List<AdminProductInfo>>((ref) async {
  final repo = ref.watch(adminProductRepositoryProvider);
  return repo.adminGetAllProducts();
});

/// Active products only
final activeProductsProvider =
    FutureProvider.autoDispose<List<AdminProductInfo>>((ref) async {
  final repo = ref.watch(adminProductRepositoryProvider);
  return repo.adminGetAllProducts(statusFilter: 'active');
});

/// Inactive products only
final inactiveProductsProvider =
    FutureProvider.autoDispose<List<AdminProductInfo>>((ref) async {
  final repo = ref.watch(adminProductRepositoryProvider);
  return repo.adminGetAllProducts(statusFilter: 'inactive');
});

/// Products filtered by category
final productsByCategoryProvider = FutureProvider.autoDispose
    .family<List<AdminProductInfo>, String>((ref, category) async {
  final repo = ref.watch(adminProductRepositoryProvider);
  return repo.adminGetAllProducts(categoryFilter: category);
});

/// Single product detail
final productDetailProvider =
    FutureProvider.autoDispose.family<AdminProductInfo?, String>((ref, productId) async {
  final allProducts = await ref.watch(allAdminProductsProvider.future);
  return allProducts.firstWhere(
    (p) => p.id == productId,
    orElse: () => throw Exception('Product not found'),
  );
});

/// All categories (including from inactive products)
final adminCategoriesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final repo = ref.watch(adminProductRepositoryProvider);
  return repo.adminGetAllCategories();
});

/// Product counts for stats
final totalProductsCountProvider = Provider.autoDispose<AsyncValue<int>>((ref) {
  return ref.watch(allAdminProductsProvider).whenData((products) => products.length);
});

final activeProductsCountProvider = Provider.autoDispose<AsyncValue<int>>((ref) {
  return ref.watch(allAdminProductsProvider).whenData(
        (products) => products.where((p) => p.status == 'active').length,
      );
});

final categoriesCountProvider = Provider.autoDispose<AsyncValue<int>>((ref) {
  return ref.watch(adminCategoriesProvider).whenData((cats) => cats.length);
});

/// Invalidate all admin product providers (call after create/update/delete)
void invalidateAdminProductProviders(WidgetRef ref) {
  ref.invalidate(allAdminProductsProvider);
  ref.invalidate(activeProductsProvider);
  ref.invalidate(inactiveProductsProvider);
  ref.invalidate(adminCategoriesProvider);
}
