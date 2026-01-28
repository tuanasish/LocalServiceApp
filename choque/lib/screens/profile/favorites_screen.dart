import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../ui/design_system.dart';
import '../../providers/app_providers.dart';
import '../../data/models/merchant_model.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(myFavoritesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            const AppSimpleHeader(title: 'Cửa hàng yêu thích'),
            Expanded(
              child: favoritesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Lỗi: $err')),
                data: (shops) {
                  if (shops.isEmpty) {
                    return _buildEmptyState(context);
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: shops.length,
                    itemBuilder: (context, index) {
                      final shop = shops[index];
                      return _buildFavoriteShopCard(context, ref, shop);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: AppShadows.soft(),
            ),
            child: const Icon(
              Icons.favorite_border,
              size: 64,
              color: Color(0xFFE2E8F0),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Chưa có cửa hàng yêu thích',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Hãy lưu lại những cửa hàng bạn yêu thích để tìm kiếm nhanh hơn nhé!',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => context.go('/'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            child: const Text('Khám phá ngay'),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteShopCard(
    BuildContext context,
    WidgetRef ref,
    MerchantModel shop,
  ) {
    return GestureDetector(
      onTap: () => context.push('/store/${shop.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          boxShadow: AppShadows.soft(0.04),
        ),
        child: Row(
          children: [
            // Shop Image Placeholder or actual image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: Consumer(
                builder: (context, ref, child) {
                  final imageUrlAsync = ref.watch(
                    shopImageUrlProvider(shop.id),
                  );
                  return imageUrlAsync.when(
                    data: (url) => url != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppRadius.small,
                            ),
                            child: Image.network(url, fit: BoxFit.cover),
                          )
                        : const Icon(Icons.store, color: Color(0xFF94A3B8)),
                    loading: () => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (_, _) =>
                        const Icon(Icons.store, color: Color(0xFF94A3B8)),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shop.name,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 14,
                        color: Color(0xFFFACC15),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        shop.rating?.toStringAsFixed(1) ?? 'N/A',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '•',
                        style: TextStyle(color: Color(0xFFCBD5E1)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        shop.openingHours ?? 'Đang mở cửa',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    shop.address ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.favorite, color: Colors.red, size: 22),
              onPressed: () => _removeFromFavorites(context, ref, shop.id),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeFromFavorites(
    BuildContext context,
    WidgetRef ref,
    String shopId,
  ) async {
    try {
      final repo = ref.read(favoriteRepositoryProvider);
      await repo.toggleFavorite(shopId, false);
      ref.invalidate(myFavoritesProvider);
      ref.invalidate(isFavoriteProvider(shopId));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã bỏ yêu thích cửa hàng')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }
}
