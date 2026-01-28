import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../design_system.dart';
import '../../data/models/order_model.dart';
import '../../data/models/location_model.dart';
import '../../services/navigation_service.dart';

/// Bottom sheet hiển thị order request với timer, earnings, và timeline
class OrderRequestBottomSheet extends StatefulWidget {
  final OrderModel order;
  final LocationModel pickup;
  final LocationModel dropoff;
  final int? remainingSeconds;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const OrderRequestBottomSheet({
    super.key,
    required this.order,
    required this.pickup,
    required this.dropoff,
    this.remainingSeconds,
    this.onAccept,
    this.onReject,
  });

  @override
  State<OrderRequestBottomSheet> createState() =>
      _OrderRequestBottomSheetState();
}

class _OrderRequestBottomSheetState extends State<OrderRequestBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  int? _remainingSeconds;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.remainingSeconds ?? 30;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _controller.forward();

    // Start countdown timer
    if (_remainingSeconds != null && _remainingSeconds! > 0) {
      _startCountdown();
    }
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted && _remainingSeconds != null && _remainingSeconds! > 0) {
        setState(() {
          _remainingSeconds = _remainingSeconds! - 1;
        });
        return _remainingSeconds! > 0;
      }
      return false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _formatPrice(int price) {
    final formatted = price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '$formattedđ';
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppRadius.large),
            topRight: Radius.circular(AppRadius.large),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 24,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle / Timer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAF9),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.large),
                  topRight: Radius.circular(AppRadius.large),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.borderSoft,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.timer,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _remainingSeconds != null
                            ? _formatTime(_remainingSeconds!)
                            : '0:00',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  // Drag handle
                  Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderSoft,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Distance placeholder
                  Text(
                    '2.1 km',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Estimated Earnings
                  Column(
                    children: [
                      Text(
                        _formatPrice(widget.order.deliveryFee),
                        style: GoogleFonts.inter(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accentYellow,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Thu nhập ước tính',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Timeline
                  _buildTimeline(),
                  const SizedBox(height: 24),
                  // Action Buttons
                  Row(
                    children: [
                      // Close button
                      SizedBox(
                        width: 56,
                        height: 56,
                        child: OutlinedButton(
                          onPressed: widget.onReject,
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            side: const BorderSide(color: AppColors.borderSoft),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.medium),
                            ),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Accept button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: widget.onAccept,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.medium),
                            ),
                            elevation: 4,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Nhận đơn',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward,
                                size: 20,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    return Column(
      children: [
        // Pickup location
        _buildTimelineItem(
          icon: Icons.storefront,
          iconColor: AppColors.primary,
          title: widget.order.shopName ?? 'Cửa hàng',
          subtitle: 'Lấy hàng • ${_calculateDistance(widget.pickup, widget.dropoff)}',
          location: widget.pickup,
          isCompleted: false,
        ),
        const SizedBox(height: 16),
        // Dropoff location
        _buildTimelineItem(
          icon: Icons.person_pin_circle,
          iconColor: AppColors.textSecondary,
          title: widget.order.customerName ?? 'Khách hàng',
          subtitle: 'Giao hàng • Khu dân cư',
          location: widget.dropoff,
          isCompleted: false,
        ),
      ],
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required LocationModel location,
    required bool isCompleted,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: iconColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        // Navigation Preview Button
        IconButton(
          onPressed: () => NavigationService.openNavigationApp(
            lat: location.lat,
            lng: location.lng,
            label: title,
          ),
          icon: Icon(
            Icons.map_outlined,
            size: 20,
            color: iconColor.withValues(alpha: 0.7),
          ),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  String _calculateDistance(LocationModel from, LocationModel to) {
    // TODO: Calculate actual distance
    return '0.5 km';
  }
}
