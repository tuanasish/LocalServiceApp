import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../ui/design_system.dart';

/// Admin Item Editor & Preview Screen
/// Màn chỉnh sửa và preview menu item cho admin.
class AdminItemEditorScreen extends StatefulWidget {
  const AdminItemEditorScreen({super.key});

  @override
  State<AdminItemEditorScreen> createState() => _AdminItemEditorScreenState();
}

class _AdminItemEditorScreenState extends State<AdminItemEditorScreen> {
  final TextEditingController _nameController = TextEditingController(
    text: 'Phở Bò Tái',
  );
  final TextEditingController _descriptionController = TextEditingController(
    text: 'Phở bò tái thơm ngon, nước dùng đậm đà',
  );
  final TextEditingController _priceController = TextEditingController(
    text: '85000',
  );
  String _selectedCategory = 'Phở';
  bool _isActive = true;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            const AppSimpleHeader(title: 'Chỉnh sửa món ăn'),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildPreviewCard(),
                      const SizedBox(height: 24),
                      _buildFormSection(),
                      const SizedBox(height: 24),
                      _buildActionButtons(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        boxShadow: AppShadows.soft(0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.preview_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text('Preview', style: AppTextStyles.label14),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                child: const Icon(
                  Icons.restaurant_menu,
                  color: AppColors.primary,
                  size: 48,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nameController.text.isEmpty
                          ? 'Tên món ăn'
                          : _nameController.text,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _descriptionController.text.isEmpty
                          ? 'Mô tả món ăn'
                          : _descriptionController.text,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_formatPrice(_priceController.text)} đ',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _isActive
                                ? AppColors.success.withValues(alpha: 0.1)
                                : const Color(
                                    0xFFF59E0B,
                                  ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            _isActive ? 'Đang bán' : 'Tạm ngưng',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _isActive
                                  ? AppColors.success
                                  : const Color(0xFFF59E0B),
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
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Thông tin món ăn', style: AppTextStyles.heading18),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _nameController,
          label: 'Tên món ăn',
          hint: 'Nhập tên món ăn',
          icon: Icons.restaurant_menu_outlined,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _descriptionController,
          label: 'Mô tả',
          hint: 'Nhập mô tả món ăn',
          icon: Icons.description_outlined,
          maxLines: 3,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        _buildCategoryDropdown(),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _priceController,
          label: 'Giá (VNĐ)',
          hint: 'Nhập giá',
          icon: Icons.attach_money_outlined,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        _buildStatusSwitch(),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label14),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            boxShadow: AppShadows.soft(0.03),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
              prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    final categories = ['Phở', 'Bún', 'Cơm', 'Đồ uống', 'Khác'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Danh mục', style: AppTextStyles.label14),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            boxShadow: AppShadows.soft(0.03),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.category_outlined,
                size: 20,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(
                        category,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSwitch() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        boxShadow: AppShadows.soft(0.03),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.toggle_on_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trạng thái',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isActive ? 'Đang bán' : 'Tạm ngưng',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Switch(
            value: _isActive,
            onChanged: (value) {
              setState(() {
                _isActive = value;
              });
            },
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            onPressed: () {},
            icon: const Icon(Icons.save_outlined, color: Colors.white),
            label: Text(
              'Lưu thay đổi',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppColors.textSecondary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                onPressed: () {},
                icon: const Icon(
                  Icons.cancel_outlined,
                  color: AppColors.textSecondary,
                ),
                label: Text(
                  'Hủy',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppColors.danger),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                onPressed: () {},
                icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                label: Text(
                  'Xóa',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.danger,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatPrice(String price) {
    final priceInt = int.tryParse(price) ?? 0;
    if (priceInt >= 1000000) {
      return '${(priceInt / 1000000).toStringAsFixed(1)}M';
    } else if (priceInt >= 1000) {
      return '${(priceInt / 1000).toStringAsFixed(0)}K';
    }
    return priceInt.toString();
  }
}
