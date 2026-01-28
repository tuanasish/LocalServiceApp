import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../design_system.dart';
import '../../data/models/order_model.dart';

/// Horizontal timeline stepper với 4 bước cho driver order fulfillment
class OrderTimelineStepper extends StatelessWidget {
  final OrderStatus currentStatus;

  const OrderTimelineStepper({
    super.key,
    required this.currentStatus,
  });

  int _getCurrentStep() {
    switch (currentStatus) {
      case OrderStatus.assigned:
        return 0; // Đến điểm lấy
      case OrderStatus.pickedUp:
        return 2; // Đang giao hàng (đã lấy hàng, đang giao)
      case OrderStatus.completed:
        return 3; // Hoàn tất
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = _getCurrentStep();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        boxShadow: AppShadows.soft(0.04),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStep(
            step: 0,
            currentStep: currentStep,
            icon: Icons.check_circle,
            label: 'Đến điểm lấy',
          ),
          _buildConnector(0 <= currentStep),
          _buildStep(
            step: 1,
            currentStep: currentStep,
            icon: Icons.inventory_2,
            label: 'Lấy hàng',
            isCompleted: currentStep >= 2, // Completed when at step 2 or more
          ),
          _buildConnector(1 <= currentStep),
          _buildStep(
            step: 2,
            currentStep: currentStep,
            icon: Icons.delivery_dining,
            label: 'Giao hàng',
            isCompleted: currentStep >= 3, // Completed when at step 3
          ),
          _buildConnector(2 <= currentStep),
          _buildStep(
            step: 3,
            currentStep: currentStep,
            icon: Icons.check_box,
            label: 'Hoàn tất',
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required int step,
    required int currentStep,
    required IconData icon,
    required String label,
    bool? isCompleted,
  }) {
    final completed = isCompleted ?? (step < currentStep);
    final isActive = step == currentStep;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: completed || isActive
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.borderSoft,
              shape: BoxShape.circle,
              border: Border.all(
                color: completed || isActive
                    ? AppColors.primary
                    : AppColors.borderSoft,
                width: isActive ? 2 : 1,
              ),
            ),
            child: Icon(
              icon,
              size: 16,
              color: completed || isActive
                  ? AppColors.primary
                  : AppColors.driverTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: completed || isActive
                  ? AppColors.primary
                  : AppColors.driverTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnector(bool isCompleted) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isCompleted
              ? AppColors.primary.withValues(alpha: 0.3)
              : const Color(0xFFDDE4E0),
        ),
      ),
    );
  }
}
