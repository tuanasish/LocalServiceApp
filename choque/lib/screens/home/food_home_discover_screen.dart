import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../ui/design_system.dart';
import '../../ui/widgets/category_chip.dart';
import '../../ui/widgets/merchant_card.dart';
import '../../ui/widgets/app_search_bar.dart';

/// Food Home - Discover screen
/// Design: "Food Home - Discover" (Stitch, project Chợ Quê)
class FoodHomeDiscoverScreen extends StatelessWidget {
  const FoodHomeDiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildCategoryChips(),
                    const SizedBox(height: 16),
                    _buildSortFilters(),
                    const SizedBox(height: 24),
                    _buildFeaturedStoresSection(context),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: location + actions
          Row(
            children: [
              const Icon(
                Icons.location_on,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Giao đến',
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Text(
                          '123 Đường ABC, Quận 1',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.expand_more,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              _buildCircleIcon(Icons.notifications_none),
              const SizedBox(width: 10),
              _buildCircleIcon(Icons.shopping_bag_outlined),
            ],
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.only(top: 20),
            child: AppSearchBar(hintText: 'Tìm món, quán ăn...'),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleIcon(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Widget _buildCategoryChips() {
    final categories = [
      {'icon': Icons.rice_bowl, 'label': 'Cơm'},
      {'icon': Icons.ramen_dining, 'label': 'Phở'},
      {'icon': Icons.local_bar, 'label': 'Đồ uống'},
      {'icon': Icons.cookie, 'label': 'Ăn vặt'},
      {'icon': Icons.icecream, 'label': 'Tráng miệng'},
      {'icon': Icons.more_horiz, 'label': 'Thêm'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final cat in categories) ...[
            _buildCategoryChip(
              icon: cat['icon'] as IconData,
              label: cat['label'] as String,
              isActive: cat['label'] == 'Cơm',
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryChip({
    required IconData icon,
    required String label,
    bool isActive = false,
  }) {
    return CategoryChip(
      icon: icon,
      label: label,
      isActive: isActive,
      onTap: () {},
    );
  }

  Widget _buildSortFilters() {
    final filters = [
      'Tất cả',
      'Gần nhất',
      'Bán chạy',
      'Giá tốt',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final filter in filters) ...[
            _buildFilterChip(
              label: filter,
              isActive: filter == 'Tất cả',
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    bool isActive = false,
  }) {
    final bgColor = isActive ? const Color(0xFF1E7F43) : Colors.white;
    final textColor = isActive ? Colors.white : const Color(0xFF0F172A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isActive ? const Color(0xFF15803D) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.expand_more,
            size: 16,
            color: Color(0xFF64748B),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedStoresSection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardHeight = screenWidth * 0.9;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cửa hàng nổi bật',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                'Xem tất cả',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E7F43),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: cardHeight,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildStoreCard(
                name: 'Cơm Tấm Phúc Lộc Thọ - Xuân Thủy',
                badgeText: 'Ưu đãi 20%',
                rating: 4.8,
                reviews: '500+',
                time: '15-20 phút',
                distance: '1.2 km',
                isOpen: true,
                imageUrl:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuA-UwbRV0stLruRQgWvypbxS3H_vrDG-x9yO1efQ9okxqjm7nFy2A46CHPpfY7i-DXox2SYxFHyrtSqOOBMn2oz2devWf-I3Wnda9kfRfryEwde50tW6JYML3ozS48duQuhYsdlHaFPnhPcLl-yFohzOfcE9qKkX2nwlg5Fvb9ST6syTnHA_z15Y7O6OQPfARI3Shs63xT-_szRSZbyCmQqyrHWFm5fynbJeTWIN59-cSyZm815NY7Ksoew9fCfiOGf9ifyU3Jt5nwp',
              ),
              const SizedBox(width: 16),
              _buildStoreCard(
                name: 'Phở Gia Truyền - Lý Quốc Sư',
                rating: 4.5,
                reviews: '1.2k',
                time: '20-30 phút',
                distance: '2.5 km',
                isOpen: true,
                imageUrl:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuBQrx9bfPZF6_r5k1geoPVDdcEwWOWtZ4t2fr3m22KRbpDSA-KlJ4bJD3u4u-SiKIvferQe_87LWsS5-7OMrUgdFj9kDC79HZBHVINbdasJCd2kCuy6N0AYXG9Jp5Fz1naYa64XlznZKhqCYX8hHWgYWlF78xLN0ZM5oT3Zv6FpbK1aG75lPx5_uJGHvBUm5zDQSytNVxyBw68qSoTgbEyLGaKxwG4oc8tEXPd7JBzwNKHtX6kZWWbvfrh1dE-5w6wotQSpccw6ptGu',
              ),
              const SizedBox(width: 16),
              _buildStoreCard(
                name: 'The Coffee House - Trần Cao Vân',
                rating: 4.7,
                reviews: '2k+',
                time: '10-15 phút',
                distance: '0.8 km',
                isOpen: true,
                imageUrl:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuDvrYU5aa9bAnUaBrcu3lK17_jFMVVOMXtywwzGpGs1UJ0aZ66kjmhuU86gFPZ0yYbw5zPcMtR_x71W9rcUgJ3_W9emjon-Hl92kAEzUmayStlDFrb93mgYBw3nVMXr5qXW7IfTadIT4vCKLzG3-StAU1DX0XWSHrugE_szRaCUQcYTJTvfRFFi4IS425Q0TKOxeT7W7oHrcwjX0OTUKq2U-ly6HvMMIkRxWmqaHpkNQsO4mSwU5aG983MYMbgErFXUd_33hDUZxxre',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStoreCard({
    required String name,
    required double rating,
    required String reviews,
    required String time,
    required String distance,
    required bool isOpen,
    required String imageUrl,
    String? badgeText,
  }) {
    return MerchantCard(
      name: name,
      rating: rating,
      reviews: reviews,
      deliveryTime: time,
      deliveryFee: badgeText ?? '',
      cuisine: isOpen ? 'Đang mở' : 'Đã đóng',
      distance: distance,
      imageUrl: imageUrl,
      onTap: () {},
    );
  }
}

