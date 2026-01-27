import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../ui/design_system.dart';
import '../providers/cart_provider.dart';
import '../providers/address_provider.dart';
import '../providers/app_providers.dart';
import '../providers/auth_provider.dart';
import '../models/user_address.dart';
import '../config/constants.dart';
import '../data/models/location_model.dart';
import '../data/models/order_model.dart';
import '../data/models/promotion_model.dart';
import '../services/vietmap_api_service.dart';
import '../providers/order_notifier.dart';

/// Phí giao hàng cố định (VND)
const int _fixedDeliveryFee = 15000;

/// Checkout - Fixed Fee Variant
/// Kết nối với cartProvider và addressProvider để hiển thị dữ liệu thật
class CheckoutFixedFeeScreen extends ConsumerStatefulWidget {
  const CheckoutFixedFeeScreen({super.key});

  @override
  ConsumerState<CheckoutFixedFeeScreen> createState() => _CheckoutFixedFeeScreenState();
}

class _CheckoutFixedFeeScreenState extends ConsumerState<CheckoutFixedFeeScreen> {
  UserAddress? _selectedAddress;
  LocationModel? _temporaryAddress;
  bool _isUsingTemporaryAddress = false;
  PromotionModel? _selectedPromotion;
  int _voucherDiscount = 0;
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _voucherCodeController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    _voucherCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final cartTotal = ref.watch(cartTotalProvider);
    final addressesAsync = ref.watch(userAddressesProvider);
    // Tính toán discount khi có promotion (async, sẽ update sau)
    if (_selectedPromotion != null) {
      _calculateDiscount(cartTotal, _fixedDeliveryFee);
    }

    // Lắng nghe trạng thái đặt hàng
    ref.listen<OrderState>(orderNotifierProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi đặt hàng: ${next.error}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
      
      if (next.lastCreatedOrder != null && next.lastCreatedOrder != previous?.lastCreatedOrder) {
        context.go('/orders/${next.lastCreatedOrder!.id}');
      }
    });

    final orderState = ref.watch(orderNotifierProvider);
    final isPlacingOrder = orderState.isPlacing;

    // Nếu giỏ hàng trống, quay về trang trước
    if (cartItems.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Giỏ hàng trống')),
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final shopName = cartItems.first.shopName;
    final grandTotal = cartTotal + _fixedDeliveryFee - _voucherDiscount;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            const AppSimpleHeader(title: 'Xác nhận đơn hàng'),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildAddressCard(addressesAsync),
                      const SizedBox(height: 20),
                      _buildOrderSummary(shopName, cartItems),
                      const SizedBox(height: 16),
                      _buildDeliveryFeeInfo(),
                      const SizedBox(height: 16),
                      _buildVoucherTile(),
                      const SizedBox(height: 10),
                      _buildPaymentMethodTile(),
                      const SizedBox(height: 20),
                      _buildNoteField(),
                      const SizedBox(height: 20),
                      _buildPriceBreakdown(cartTotal, grandTotal),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(grandTotal),
    );
  }

  Widget _buildAddressCard(AsyncValue<List<UserAddress>> addressesAsync) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        boxShadow: AppShadows.soft(0.04),
      ),
      child: addressesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildNoAddressUI(),
        data: (addresses) {
          if (addresses.isEmpty) {
            return _buildNoAddressUI();
          }

          // Chọn địa chỉ mặc định nếu chưa chọn và không đang dùng temporary address
          if (!_isUsingTemporaryAddress) {
            _selectedAddress ??= addresses.firstWhere(
              (a) => a.isDefault,
              orElse: () => addresses.first,
            );
          }

          // Hiển thị địa chỉ tạm thời hoặc địa chỉ đã lưu
          final displayAddress = _isUsingTemporaryAddress && _temporaryAddress != null
              ? _temporaryAddress!.address ?? _temporaryAddress!.label
              : _selectedAddress!.details;
          final displayLabel = _isUsingTemporaryAddress
              ? null
              : (_selectedAddress!.label.isNotEmpty ? _selectedAddress!.label : null);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('Địa chỉ giao hàng', style: AppTextStyles.label14),
                  if (_isUsingTemporaryAddress) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withAlpha(25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Địa chỉ mới',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                displayAddress,
                style: AppTextStyles.body13Secondary,
              ),
              if (displayLabel != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    displayLabel,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _showAddressSelector(addresses),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Thay đổi',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNoAddressUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.location_on, color: AppColors.danger, size: 20),
            const SizedBox(width: 8),
            Text('Chưa có địa chỉ giao hàng', style: AppTextStyles.label14),
          ],
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () {
            context.push('/profile/addresses/add');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: const Icon(Icons.add, size: 18, color: Colors.white),
          label: Text(
            'Thêm địa chỉ',
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  void _showAddressSelector(List<UserAddress> addresses) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chọn địa chỉ giao hàng', style: AppTextStyles.heading18),
            const SizedBox(height: 16),
            ...addresses.map((address) => ListTile(
              leading: Icon(
                (!_isUsingTemporaryAddress && _selectedAddress?.id == address.id)
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: AppColors.primary,
              ),
              title: Text(address.label.isNotEmpty ? address.label : 'Địa chỉ'),
              subtitle: Text(address.details, maxLines: 2, overflow: TextOverflow.ellipsis),
              onTap: () {
                setState(() {
                  _selectedAddress = address;
                  _isUsingTemporaryAddress = false;
                  _temporaryAddress = null;
                });
                Navigator.pop(context);
              },
            )),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(
                _isUsingTemporaryAddress
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: AppColors.primary,
              ),
              title: const Text('Chọn địa chỉ mới trên bản đồ'),
              subtitle: const Text('Chọn địa chỉ tạm thời, không lưu vào profile'),
              onTap: () async {
                Navigator.pop(context);
                final result = await context.push<LocationModel?>('/address/map-picker');
                if (result != null) {
                  setState(() {
                    _temporaryAddress = result;
                    _isUsingTemporaryAddress = true;
                    _selectedAddress = null;
                  });
                }
              },
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // Check authentication before navigating
                final isAuthenticated = ref.read(isAuthenticatedProvider);
                if (!isAuthenticated) {
                  // Show dialog to require login
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      _showLoginRequiredDialog(context);
                    }
                  });
                } else {
                  // Đợi modal đóng hoàn toàn trước khi push route mới
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      context.push('/profile/addresses/add');
                    }
                  });
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Thêm địa chỉ mới vào profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(String shopName, List<CartItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Tóm tắt đơn hàng', style: AppTextStyles.heading18)),
            Text(
              shopName,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildOrderItemRow(
            title: item.name,
            quantity: item.quantity,
            price: _formatPrice(item.subtotal),
          ),
        )),
      ],
    );
  }

  Widget _buildOrderItemRow({
    required String title,
    required int quantity,
    required String price,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'x$quantity - $price',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.local_shipping_outlined,
            size: 22,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Phí giao hàng', style: AppTextStyles.label14),
                    Text(
                      _formatPrice(_fixedDeliveryFee),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Áp dụng phí đồng giá cho mọi đơn hàng trong khu vực.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherTile() {
    return GestureDetector(
      onTap: () => _showVoucherDialog(),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          boxShadow: AppShadows.soft(0.03),
        ),
        child: Row(
          children: [
            const Icon(Icons.confirmation_number_outlined, size: 22, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _selectedPromotion != null
                    ? '${_selectedPromotion!.name} - Giảm ${_formatPrice(_voucherDiscount)}'
                    : 'Chọn hoặc nhập mã giảm giá',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _voucherDiscount > 0 ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ),
            if (_selectedPromotion != null)
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  setState(() {
                    _selectedPromotion = null;
                    _voucherDiscount = 0;
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Future<void> _showVoucherDialog() async {
    final cartTotal = ref.read(cartTotalProvider);
    final currentUserAsync = ref.read(currentUserProvider);
    final profile = ref.read(currentProfileProvider).value;
    
    final currentUser = currentUserAsync.asData?.value;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để sử dụng voucher')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _VoucherSelectionSheet(
        userId: currentUser.id,
        marketId: profile?.marketId ?? AppConstants.defaultMarketId,
        orderValue: cartTotal,
        selectedPromotion: _selectedPromotion,
        onPromotionSelected: (promo) {
          setState(() {
            _selectedPromotion = promo;
          });
          _calculateDiscount(cartTotal, _fixedDeliveryFee);
          Navigator.pop(context);
        },
        onCodeEntered: (code) async {
          await _applyVoucherCode(code, cartTotal);
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _applyVoucherCode(String code, int cartTotal) async {
    if (code.trim().isEmpty) return;

    final currentUserAsync = ref.read(currentUserProvider);
    final profile = ref.read(currentProfileProvider).value;
    final promoRepo = ref.read(promotionRepositoryProvider);

    final currentUser = currentUserAsync.asData?.value;
    if (currentUser == null || profile == null) return;

    try {
      final promo = await promoRepo.validatePromoCode(
        code: code,
        userId: currentUser.id,
        marketId: profile.marketId,
        orderValue: cartTotal,
      );

      if (promo == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mã giảm giá không hợp lệ hoặc đã hết hạn')),
          );
        }
        return;
      }

      setState(() {
        _selectedPromotion = promo;
      });
      _calculateDiscount(cartTotal, _fixedDeliveryFee);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Áp dụng ${promo.name} thành công!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  Future<void> _calculateDiscount(int cartTotal, int deliveryFee) async {
    if (_selectedPromotion == null) {
      setState(() => _voucherDiscount = 0);
      return;
    }

    final promoRepo = ref.read(promotionRepositoryProvider);
    try {
      final discount = await promoRepo.calculateDiscount(
        promotionId: _selectedPromotion!.id,
        deliveryFee: deliveryFee,
        itemsTotal: cartTotal,
      );
      setState(() => _voucherDiscount = discount);
    } catch (e) {
      setState(() => _voucherDiscount = 0);
    }
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
          const Icon(Icons.payment_outlined, size: 22, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Thanh toán khi nhận hàng',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF94A3B8)),
        ],
      ),
    );
  }

  Widget _buildNoteField() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        boxShadow: AppShadows.soft(0.03),
      ),
      child: TextField(
        controller: _noteController,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: 'Ghi chú cho cửa hàng (tùy chọn)',
          border: InputBorder.none,
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textMuted,
          ),
        ),
        style: GoogleFonts.inter(fontSize: 14),
      ),
    );
  }

  Widget _buildPriceBreakdown(int subtotal, int grandTotal) {
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
          _buildPriceRow(label: 'Tạm tính', value: _formatPrice(subtotal)),
          const SizedBox(height: 8),
          _buildPriceRow(label: 'Phí giao hàng (Fixed)', value: _formatPrice(_fixedDeliveryFee)),
          if (_voucherDiscount > 0) ...[
            const SizedBox(height: 8),
            _buildPriceRow(
              label: 'Giảm giá voucher',
              value: '-${_formatPrice(_voucherDiscount)}',
              valueColor: AppColors.danger,
            ),
          ],
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          _buildPriceRow(
            label: 'Tổng cộng',
            value: _formatPrice(grandTotal),
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow({
    required String label,
    required String value,
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(int grandTotal) {
    final hasAddress = _isUsingTemporaryAddress 
        ? (_temporaryAddress != null)
        : (_selectedAddress != null);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tổng số tiền',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatPrice(grandTotal),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Giao hàng trong 25-35 phút',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: hasAddress ? AppColors.primary : Colors.grey,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
            onPressed: (hasAddress && !isPlacingOrder) ? _placeOrder : null,
            icon: isPlacingOrder
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(
                    Icons.arrow_forward,
                    size: 18,
                    color: Colors.white,
                  ),
            label: Text(
              isPlacingOrder ? 'Đang xử lý...' : 'Đặt đơn ngay',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(int price) {
    final formatted = price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '$formattedđ';
  }

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Yêu cầu đăng nhập',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Bạn cần đăng nhập để thêm địa chỉ vào profile. Bạn có muốn đăng nhập ngay bây giờ không?',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Hủy',
              style: GoogleFonts.inter(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/login?redirect=${Uri.encodeComponent('/profile/addresses/add')}');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: Text(
              'Đăng nhập',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder() async {
    final cartItems = ref.read(cartProvider);
    
    await ref.read(orderNotifierProvider.notifier).placeOrder(
      cartItems: cartItems,
      selectedAddress: _selectedAddress,
      temporaryAddress: _temporaryAddress,
      isUsingTemporaryAddress: _isUsingTemporaryAddress,
      selectedPromotion: _selectedPromotion,
      voucherDiscount: _voucherDiscount,
      deliveryFee: _fixedDeliveryFee,
      note: _noteController.text.trim(),
    );
  }
}

/// Voucher Selection Sheet
class _VoucherSelectionSheet extends ConsumerStatefulWidget {
  final String userId;
  final String marketId;
  final int orderValue;
  final PromotionModel? selectedPromotion;
  final Function(PromotionModel) onPromotionSelected;
  final Function(String) onCodeEntered;

  const _VoucherSelectionSheet({
    required this.userId,
    required this.marketId,
    required this.orderValue,
    this.selectedPromotion,
    required this.onPromotionSelected,
    required this.onCodeEntered,
  });

  @override
  ConsumerState<_VoucherSelectionSheet> createState() => _VoucherSelectionSheetState();
}

class _VoucherSelectionSheetState extends ConsumerState<_VoucherSelectionSheet> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final promotionsAsync = ref.watch(availablePromotionsProvider({
      'user_id': widget.userId,
      'market_id': widget.marketId,
      'order_value': widget.orderValue,
    }));

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Chọn mã giảm giá',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // Nhập mã
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _codeController,
                        decoration: InputDecoration(
                          hintText: 'Nhập mã giảm giá',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        textCapitalization: TextCapitalization.characters,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (_codeController.text.trim().isNotEmpty) {
                          widget.onCodeEntered(_codeController.text.trim());
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Áp dụng'),
                    ),
                  ],
                ),
              ),

              // Danh sách promotions
              Expanded(
                child: promotionsAsync.when(
                  data: (promotions) {
                    if (promotions.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.confirmation_number_outlined,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Không có mã giảm giá khả dụng',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: promotions.length,
                      itemBuilder: (context, index) {
                        final promo = promotions[index];
                        final isSelected = widget.selectedPromotion?.id == promo.id;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: () => widget.onPromotionSelected(promo),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.1)
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.grey[300]!,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.local_offer,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          promo.name,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        if (promo.description != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            promo.description!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 4),
                                        Text(
                                          promo.shortDescription,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle,
                                      color: AppColors.primary,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Text('Lỗi: $error'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}