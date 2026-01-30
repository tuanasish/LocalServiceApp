import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../providers/admin_product_provider.dart';
import '../../services/image_upload_service.dart';
import '../../ui/design_system.dart';

/// Admin Item Editor & Preview Screen
/// Màn chỉnh sửa và preview sản phẩm cho admin (create/edit mode).
class AdminItemEditorScreen extends ConsumerStatefulWidget {
  final String? productId; // null = create mode, non-null = edit mode

  const AdminItemEditorScreen({super.key, this.productId});

  @override
  ConsumerState<AdminItemEditorScreen> createState() =>
      _AdminItemEditorScreenState();
}

class _AdminItemEditorScreenState extends ConsumerState<AdminItemEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  String _selectedCategory = '';
  bool _isActive = true;
  String? _existingImagePath;
  File? _selectedImage;
  bool _isLoading = false;
  bool _isLoadingProduct = true;

  bool get isEditMode => widget.productId != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _loadProduct();
    } else {
      _isLoadingProduct = false;
    }
  }

  Future<void> _loadProduct() async {
    try {
      final products =
          await ref.read(allAdminProductsProvider.future);
      final product = products.firstWhere(
        (p) => p.id == widget.productId,
        orElse: () => throw Exception('Không tìm thấy sản phẩm'),
      );

      setState(() {
        _nameController.text = product.name;
        _descriptionController.text = product.description ?? '';
        _priceController.text = product.basePrice.toString();
        _selectedCategory = product.category ?? '';
        _isActive = product.status == 'active';
        _existingImagePath = product.imagePath;
        _isLoadingProduct = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
        context.pop();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(adminCategoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            AppSimpleHeader(
              title: isEditMode ? 'Chỉnh sửa sản phẩm' : 'Thêm sản phẩm mới',
            ),
            Expanded(
              child: _isLoadingProduct
                  ? const Center(child: CircularProgressIndicator())
                  : Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              _buildPreviewCard(),
                              const SizedBox(height: 24),
                              _buildImagePicker(),
                              const SizedBox(height: 24),
                              _buildFormSection(categoriesAsync),
                              const SizedBox(height: 24),
                              _buildActionButtons(),
                              const SizedBox(height: 100),
                            ],
                          ),
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
    final priceFormatter = NumberFormat('#,###', 'vi_VN');
    final price = int.tryParse(_priceController.text) ?? 0;

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
                child: _buildPreviewImage(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nameController.text.isEmpty
                          ? 'Tên sản phẩm'
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
                          ? 'Mô tả sản phẩm'
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
                          price > 0 ? '${priceFormatter.format(price)}đ' : '0đ',
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
                                : const Color(0xFFF59E0B).withValues(alpha: 0.1),
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

  Widget _buildPreviewImage() {
    if (_selectedImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: Image.file(_selectedImage!, fit: BoxFit.cover),
      );
    } else if (_existingImagePath != null) {
      final imageUrl =
          'https://ipdwpzgbznphkmdewjdl.supabase.co/storage/v1/object/public/products/$_existingImagePath';
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.restaurant_menu,
            color: AppColors.primary,
            size: 48,
          ),
        ),
      );
    }
    return const Icon(
      Icons.restaurant_menu,
      color: AppColors.primary,
      size: 48,
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hình ảnh', style: AppTextStyles.label14),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Thư viện'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Chụp ảnh'),
              ),
            ),
          ],
        ),
        if (_selectedImage != null || _existingImagePath != null) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _selectedImage = null;
                _existingImagePath = null;
              });
            },
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            label: const Text('Xóa ảnh', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ],
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể chọn ảnh: $e')),
        );
      }
    }
  }

  Widget _buildFormSection(AsyncValue<List<String>> categoriesAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Thông tin sản phẩm', style: AppTextStyles.heading18),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _nameController,
          label: 'Tên sản phẩm *',
          hint: 'Nhập tên sản phẩm',
          icon: Icons.restaurant_menu_outlined,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Vui lòng nhập tên sản phẩm';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _descriptionController,
          label: 'Mô tả',
          hint: 'Nhập mô tả sản phẩm',
          icon: Icons.description_outlined,
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        _buildCategoryDropdown(categoriesAsync),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _priceController,
          label: 'Giá (VNĐ) *',
          hint: 'Nhập giá',
          icon: Icons.attach_money_outlined,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Vui lòng nhập giá';
            }
            final price = int.tryParse(value);
            if (price == null || price < 0) {
              return 'Giá không hợp lệ';
            }
            return null;
          },
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
    String? Function(String?)? validator,
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
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            validator: validator,
            onChanged: (_) => setState(() {}),
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

  Widget _buildCategoryDropdown(AsyncValue<List<String>> categoriesAsync) {
    final categories = categoriesAsync.asData?.value ?? [];
    final allCategories = [...categories, 'Khác'];

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
                  value: allCategories.contains(_selectedCategory)
                      ? _selectedCategory
                      : (allCategories.isNotEmpty ? allCategories.first : null),
                  hint: const Text('Chọn danh mục'),
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: allCategories.map((category) {
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
            onPressed: _isLoading ? null : _saveProduct,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_outlined, color: Colors.white),
            label: Text(
              _isLoading
                  ? 'Đang lưu...'
                  : (isEditMode ? 'Lưu thay đổi' : 'Tạo sản phẩm'),
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
                onPressed: () => context.pop(),
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
            if (isEditMode) ...[
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
                  onPressed: _isLoading ? null : _deleteProduct,
                  icon:
                      const Icon(Icons.delete_outline, color: AppColors.danger),
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
          ],
        ),
      ],
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(adminProductRepositoryProvider);
      String? imagePath = _existingImagePath;

      // Upload new image if selected
      if (_selectedImage != null) {
        final uploadService = ImageUploadService.instance();
        imagePath = await uploadService.uploadProductImage(_selectedImage!);
      }

      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      final basePrice = int.parse(_priceController.text);
      final category =
          _selectedCategory.isNotEmpty ? _selectedCategory : null;
      final status = _isActive ? 'active' : 'inactive';

      if (isEditMode) {
        await repo.adminUpdateProduct(
          productId: widget.productId!,
          name: name,
          description: description.isNotEmpty ? description : null,
          basePrice: basePrice,
          category: category,
          imagePath: imagePath,
          status: status,
        );
      } else {
        await repo.adminCreateProduct(
          name: name,
          description: description.isNotEmpty ? description : null,
          basePrice: basePrice,
          category: category,
          imagePath: imagePath,
        );
      }

      invalidateAdminProductProviders(ref);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditMode
                  ? 'Cập nhật sản phẩm thành công'
                  : 'Tạo sản phẩm thành công',
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteProduct() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content:
            Text('Bạn có chắc muốn xóa "${_nameController.text}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(adminProductRepositoryProvider);
      await repo.adminDeleteProduct(widget.productId!);
      invalidateAdminProductProviders(ref);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa sản phẩm')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
