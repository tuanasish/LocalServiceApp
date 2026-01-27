import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../ui/design_system.dart';
import '../../data/models/location_model.dart';

/// Manual Address Selection Screen
/// Thiết lập / chọn địa chỉ giao hàng thủ công.
class ManualAddressSelectionScreen extends StatelessWidget {
  const ManualAddressSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            const AppSimpleHeader(title: 'Chọn địa chỉ giao hàng'),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildCurrentAddressCard(),
                      const SizedBox(height: 20),
                      _buildManualFormCard(context),
                      const SizedBox(height: 24),
                      _buildConfirmHint(),
                      const SizedBox(height: 100),
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

  Widget _buildCurrentAddressCard() {
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
                'Địa chỉ hiện tại',
                style: AppTextStyles.heading18,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  'Mặc định',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '123 Đường Lê Lợi, Phường Bến Thành, Quận 1, TP. Hồ Chí Minh',
                  style: AppTextStyles.body13Secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManualFormCard(BuildContext context) {
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
          Text(
            'Nhập địa chỉ mới',
            style: AppTextStyles.heading18,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            label: 'Họ và tên',
            hint: 'Nguyễn Văn A',
            keyboardType: TextInputType.name,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            label: 'Số điện thoại',
            hint: '0901234567',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
            ),
            onPressed: () async {
              final result = await context.push<LocationModel>(
                '/address/map-picker',
              );
              if (result != null) {
                // TODO: Cập nhật form với result
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã chọn: ${result.address ?? result.label}'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            icon: const Icon(
              Icons.map_outlined,
              size: 18,
              color: AppColors.primary,
            ),
            label: Text(
              'Chọn trên bản đồ',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildTextField(
            label: 'Địa chỉ chi tiết',
            hint: 'Số nhà, tên đường...',
            keyboardType: TextInputType.streetAddress,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: 'Phường / Xã',
                  hint: 'Phường Bến Thành',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  label: 'Quận / Huyện',
                  hint: 'Quận 1',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(
            label: 'Tỉnh / Thành phố',
            hint: 'TP. Hồ Chí Minh',
          ),
          const SizedBox(height: 12),
          _buildTextField(
            label: 'Ghi chú cho tài xế (tuỳ chọn)',
            hint: 'Ví dụ: Gọi trước khi đến, gửi ở quầy lễ tân...',
            maxLines: 3,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Switch(
                value: true,
                onChanged: (_) {},
                activeThumbColor: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Đặt làm địa chỉ mặc định',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(color: AppColors.borderSoft),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            keyboardType: keyboardType,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
              border: InputBorder.none,
            ),
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmHint() {
    return Row(
      children: [
        const Icon(
          Icons.info_outline,
          size: 18,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Hãy kiểm tra kỹ địa chỉ trước khi xác nhận để tránh giao nhầm nơi.',
            style: AppTextStyles.body13Secondary,
          ),
        ),
      ],
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
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          onPressed: () {},
          child: Text(
            'Xác nhận địa chỉ',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

