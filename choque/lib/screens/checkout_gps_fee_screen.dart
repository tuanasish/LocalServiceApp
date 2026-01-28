import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../ui/design_system.dart';
import '../ui/widgets/checkout_address_card.dart';
import '../ui/widgets/checkout_order_item.dart';

/// Checkout - GPS Fee Variant
/// Design: "Checkout - GPS Fee Variant" (Stitch, project Chợ Quê)
class CheckoutGpsFeeScreen extends StatelessWidget {
  const CheckoutGpsFeeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            const AppSimpleHeader(title: 'Thanh toán'),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildAddressCard(),
                      const SizedBox(height: 20),
                      _buildOrderSummary(),
                      const SizedBox(height: 16),
                      _buildDeliveryFeeInfo(),
                      const SizedBox(height: 16),
                      _buildNoteSection(),
                      const SizedBox(height: 16),
                      _buildPaymentMethodTile(),
                      const SizedBox(height: 20),
                      _buildPriceBreakdown(),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildAddressCard() {
    return CheckoutAddressCard(
      name: 'Nguyễn Văn A',
      phone: '0901234567',
      address: '123 Đường Lê Lợi, Phường Bến Thành, Quận 1, TP. Hồ Chí Minh',
      onTap: () {},
    );
  }

  Widget _buildOrderSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Đơn hàng của bạn', style: AppTextStyles.heading18),
        const SizedBox(height: 12),
        const CheckoutOrderItem(
          title: 'Phở Bò Tái Lăn',
          quantity: 1,
          price: '65.000đ',
        ),
        const SizedBox(height: 10),
        const CheckoutOrderItem(title: 'Trà Đá', quantity: 1, price: '5.000đ'),
      ],
    );
  }

  Widget _buildDeliveryFeeInfo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        boxShadow: AppShadows.soft(0.03),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Phí giao hàng', style: AppTextStyles.label14),
              ),
              Text(
                '22.000đ',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.navigation_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Ước tính 5.000đ/km (Khoảng cách 4.4km)',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoteSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        boxShadow: AppShadows.soft(0.03),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ghi chú cho cửa hàng', style: AppTextStyles.label14),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: 'Nhập ghi chú...',
              hintStyle: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTile() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        boxShadow: AppShadows.soft(0.03),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.payments_outlined,
            size: 22,
            color: Color(0xFF0EA5E9),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tiền mặt',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBreakdown() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        boxShadow: AppShadows.soft(0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng thanh toán',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '92.000đ',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Bao gồm VAT',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
        onPressed: () {},
        child: Text(
          'Đặt đơn',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
