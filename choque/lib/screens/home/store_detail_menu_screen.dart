import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../ui/design_system.dart';
import '../../ui/widgets/category_chip.dart';
import '../../ui/widgets/menu_item_card.dart';
import '../../ui/widgets/cart_summary_bar.dart';

/// Store Detail & Menu screen
/// Design: "Store Detail & Menu" (Stitch, project Chợ Quê)
class StoreDetailMenuScreen extends StatelessWidget {
  const StoreDetailMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            const AppSimpleHeader(title: 'Chi tiết cửa hàng'),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStoreInfo(),
                    const SizedBox(height: 16),
                    _buildTabs(),
                    const SizedBox(height: 16),
                    _buildCategoryChips(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Món chính'),
                    const SizedBox(height: 12),
                    _buildMainDishesList(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Đồ uống'),
                    const SizedBox(height: 12),
                    _buildDrinksList(),
                    const SizedBox(height: 100), // space for bottom bar
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CartSummaryBar(
        itemCount: 3,
        totalPrice: '120.000đ',
        subtitle: 'Chưa bao gồm phí giao hàng',
      ),
    );
  }

  Widget _buildStoreInfo() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        boxShadow: AppShadows.soft(0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gia Đình Food & Grill', style: AppTextStyles.heading20),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star, size: 16, color: Color(0xFFFACC15)),
              const SizedBox(width: 4),
              Text(
                '4.8',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              const Text('•'),
              const SizedBox(width: 6),
              Text(
                'Mở cửa đến 10:00 PM',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              const Text('•'),
              const SizedBox(width: 6),
              Text(
                '1.2 km',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline,
                      size: 16,
                      color: Color(0xFF0369A1),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Liên hệ',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0369A1),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = ['Menu', 'Đánh giá', 'Thông tin'];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: tabs.map((label) {
          final isActive = label == 'Menu';
          return Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive
                      ? const Color(0xFF0F172A)
                      : const Color(0xFF64748B),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryChips() {
    final categories = [
      'Món chính',
      'Đồ uống',
      'Khai vị',
      'Tráng miệng',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final label in categories) ...[
            _buildCategoryChip(
              label: label,
              isActive: label == 'Món chính',
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    bool isActive = false,
  }) {
    return CategoryChip(
      label: label,
      isActive: isActive,
      onTap: () {},
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _buildMainDishesList() {
    final dishes = [
      {
        'name': 'Salad Bơ Trứng',
        'description':
            'Salad tươi ngon với bơ chín, trứng chần và sốt dầu giấm.',
        'price': '45.000đ',
      },
      {
        'name': 'Bánh Pancakes Mật Ong',
        'description':
            'Bánh pancake mềm mịn dùng kèm mật ong rừng và dâu tây.',
        'price': '35.000đ',
      },
      {
        'name': 'Gà Nướng Xiên Que',
        'description':
            'Thịt gà ướp gia vị đặc trưng, nướng than hồng thơm phức.',
        'price': '40.000đ',
      },
    ];

    return Column(
      children: [
        for (final dish in dishes) ...[
          _buildMenuItemCard(
            name: dish['name'] as String,
            description: dish['description'] as String,
            price: dish['price'] as String,
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildDrinksList() {
    return _buildMenuItemCard(
      name: 'Cà Phê Sữa Đá',
      description:
          'Hạt cà phê Robusta rang xay pha phin truyền thống.',
      price: '25.000đ',
    );
  }

  Widget _buildMenuItemCard({
    required String name,
    required String description,
    required String price,
  }) {
    return MenuItemCard(
      name: name,
      description: description,
      price: price,
      onAddTap: () {},
    );
  }
}

