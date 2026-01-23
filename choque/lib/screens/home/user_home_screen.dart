import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/cart_provider.dart';
import '../../ui/design_system.dart';
import '../../ui/widgets/merchant_card.dart';
import '../../ui/widgets/app_search_bar.dart';

/// User Home Screen - Chuyển đổi từ Stitch design
/// Design: User Home Screen (Project: 13405594091078915398)
/// Colors: Primary #1E7F43, Font: Inter, Roundness: ROUND_TWELVE
class UserHomeScreen extends ConsumerWidget {
  const UserHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header với địa chỉ giao hàng
            _buildHeader(context),
            
            // Nội dung chính
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    
                    // Category Grid
                    _buildCategoryGrid(),
                    
                    const SizedBox(height: 32),
                    
                    // Featured Merchants
                    _buildFeaturedMerchants(context),
                    
                    const SizedBox(height: 32),
                    
                    // Popular Near You
                    _buildPopularNearYou(),
                    
                    const SizedBox(height: 100), // Space cho bottom nav
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context, ref),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 48),
          
          // Address và Notification
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'DELIVERY ADDRESS',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Home, 123 Green Street',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: const Icon(
                    Icons.notifications_none,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Search Bar
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: AppSearchBar(hintText: 'Search for food, cuisines...'),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final categories = [
      {'icon': Icons.rice_bowl, 'label': 'Rice', 'color': Colors.orange},
      {'icon': Icons.ramen_dining, 'label': 'Noodles', 'color': Colors.yellow},
      {'icon': Icons.local_bar, 'label': 'Drinks', 'color': Colors.blue},
      {'icon': Icons.bakery_dining, 'label': 'Snacks', 'color': Colors.red},
      {'icon': Icons.lunch_dining, 'label': 'Burgers', 'color': Colors.amber},
      {'icon': Icons.local_pizza, 'label': 'Pizza', 'color': Colors.pink},
      {'icon': Icons.icecream, 'label': 'Desserts', 'color': Colors.pink},
      {'icon': Icons.spa, 'label': 'Healthy', 'color': Colors.green},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 24,
          crossAxisSpacing: 16,
          // Tránh lỗi "BOTTOM OVERFLOW" trên máy nhỏ: tăng chiều cao mỗi ô.
          mainAxisExtent: 96,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return _buildCategoryItem(
            icon: category['icon'] as IconData,
            label: category['label'] as String,
            color: category['color'] as MaterialColor,
          );
        },
      ),
    );
  }

  Widget _buildCategoryItem({
    required IconData icon,
    required String label,
    required MaterialColor color,
  }) {
    return GestureDetector(
      onTap: () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: color.shade600,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedMerchants(BuildContext context) {
    // Chiều cao list card tỉ lệ theo chiều ngang màn hình để responsive.
    final screenWidth = MediaQuery.of(context).size.width;
    final listHeight = screenWidth * 0.8; // ~288px trên màn 360px, đủ cho card + shadow.

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Featured Merchants',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'View all',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: listHeight,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _buildMerchantCard(
                context: context,
                name: 'Premium Pizza Kitchen',
                rating: 4.9,
                reviews: '2.4k+',
                deliveryTime: '20-30 min',
                deliveryFee: '\$2.99 Del.',
                cuisine: 'Italian',
                distance: '1.2 mi',
                // Dùng URL thật từ Stitch (tránh lỗi DNS của placeholder)
                imageUrl:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuAhcTDwwD0Xqpp9_-KJd-lt2YLaEcq3IUku90eq6HuefbvV6wKynN8LSqXoEdcLF4fnhUQjTDNoLDVn7viu9fxWe1CcKHSvrPb6Q3KrwaBg8wNIB6EvgxWAF7VrJsO8-V1-R_9ilD4DONJWVjTrQlIIzuncGUCl-gEQXm-loBzArvSwYaM0YLxuI03Kx3dYkyG2ymHUhrFPT2LNxq942nB381LsGbcw6IgaYgs2wDoUKogUoFhAUfvQ5JNaBdjMmDUgYTLXBFCBWpwv',
              ),
              const SizedBox(width: 20),
              _buildMerchantCard(
                context: context,
                name: 'Downtown Burger Co.',
                rating: 4.7,
                reviews: '1.1k',
                deliveryTime: '15-25 min',
                deliveryFee: 'Free Delivery',
                cuisine: 'American',
                distance: '0.8 mi',
                isFreeDelivery: true,
                imageUrl:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuDhXyLw3WkD452ZHfi55FpFDYuK1HuxHFMEecx0n3YZpObZNQHFmMjkAg2_7pkrzF9G8Jzh3kScP88AnxYM_dE-fQtwJqYohnWFLM6-438iXqxGNZBlZCiwrvoUkln1RVLBeiwOy9M8UgLpSrd3fYeEVxlSDTs4De5FFtyx7EWV7_XVnwl0B2ZqzuKzRwrTM_-BDY2hF6e_DavAFlTkUOrSzS0XSDOpSEpjblI7fi3tf6On3xtNbOasUeZD2JtcVATiPfvXwOVNMZ_e',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMerchantCard({
    required BuildContext context,
    required String name,
    required double rating,
    required String reviews,
    required String deliveryTime,
    required String deliveryFee,
    required String cuisine,
    required String distance,
    required String imageUrl,
    bool isFreeDelivery = false,
  }) {
    return MerchantCard(
      name: name,
      rating: rating,
      reviews: reviews,
      deliveryTime: deliveryTime,
      deliveryFee: deliveryFee,
      cuisine: cuisine,
      distance: distance,
      imageUrl: imageUrl,
      isFreeDelivery: isFreeDelivery,
      onTap: () => context.push('/store/123'),
    );
  }

  Widget _buildPopularNearYou() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Popular Near You',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildPopularItem(
            name: 'Fresh Green Salads',
            rating: 4.8,
            cuisine: 'Healthy • Vegetarian',
            distance: '0.5 mi',
            deliveryTime: '10-20 min',
            imageUrl:
                'https://lh3.googleusercontent.com/aida-public/AB6AXuB_wD380068tKw45VMRcdrNs2qLq4dGlAMjj_Ifb_hE5K60UIDCQJ5zrUFvOaVYMM87huddbMzUlS5ZxMxTuwmkH7rk_1_sZovUpGzijtvYwEzAj73VhYdPKjwEH82-JVATdQ1QoUxQalBCm0aMxA0q4F5xInCuJJRlfL3tjk1UaDYo-GlVVZo_beGMZc9Nav127KxbL6WrgWR9tUbWCRSFCXk-JvoMusLFPV7sPLF9yA7ioGreTocr8_fFrMAdsRcE4RaQDl1jF4HT',
          ),
          const SizedBox(height: 16),
          _buildPopularItem(
            name: 'Bento Express',
            rating: 4.5,
            cuisine: 'Japanese • Bento',
            distance: '1.8 mi',
            deliveryTime: '25-35 min',
            imageUrl:
                'https://lh3.googleusercontent.com/aida-public/AB6AXuAp4yTIqtb8H1freHpJU-3s-zZBRbmlqe3hRFGdqnADIDxkX2b7s1NHpvrpp4n7KQ4IxXORrZtFpBWmlMeC6gfxGInOGdLwh3Vyu5Z-sgAeiYizriEZPVV_DsiNmDuVg_FHylqy75gi-2s7xwOQ7r5j8lvv1n3TxOxB60LahN-UEVQ0lhrLtwV0jNYIK6ZHkxqu7TipJSeqEbCdZHKf-JfSBeUHKU-D0xpmAT5UYCVhvbpC3HVJ4D8dqP6b2vF084eUM7JmHaUqfkgY',
          ),
        ],
      ),
    );
  }

  Widget _buildPopularItem({
    required String name,
    required double rating,
    required String cuisine,
    required String distance,
    required String deliveryTime,
    required String imageUrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              imageUrl,
              width: 96,
              height: 96,
              fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 96,
              height: 96,
              color: const Color(0xFFE2E8F0),
              alignment: Alignment.center,
              child: const Icon(Icons.image, size: 22, color: Color(0xFF94A3B8)),
            ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 14,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          rating.toString(),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  cuisine,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.near_me,
                          color: Color(0xFF1E7F43),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          distance,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.schedule,
                          color: Color(0xFF1E7F43),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          deliveryTime,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavItem(Icons.home, 'Home', isActive: true),
          _buildNavItem(Icons.receipt_long, 'Orders', isActive: false),
          _buildNavItem(Icons.shopping_cart_outlined, 'Cart', isActive: false, badgeCount: ref.watch(cartProvider.select((items) => items.length))),
          _buildNavItem(Icons.person_outline, 'Profile', isActive: false),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, {bool isActive = false, int badgeCount = 0}) {
    return GestureDetector(
      onTap: () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Icon(
                icon,
                size: 26,
                color: isActive
                    ? const Color(0xFF1E7F43)
                    : const Color(0xFF94A3B8),
              ),
              if (badgeCount > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: Text(
                      badgeCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
              color: isActive
                  ? const Color(0xFF1E7F43)
                  : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}
