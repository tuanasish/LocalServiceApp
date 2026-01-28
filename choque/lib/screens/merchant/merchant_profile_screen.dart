import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../ui/design_system.dart';
import '../../providers/app_providers.dart';
import '../../data/models/merchant_model.dart';

/// Merchant Profile Screen
/// Cho phép chủ cửa hàng xem và chỉnh sửa thông tin shop
class MerchantProfileScreen extends ConsumerStatefulWidget {
  const MerchantProfileScreen({super.key});

  @override
  ConsumerState<MerchantProfileScreen> createState() =>
      _MerchantProfileScreenState();
}

class _MerchantProfileScreenState extends ConsumerState<MerchantProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _hoursController;

  bool _isLoading = false;
  bool _isInit = false;
  String? _shopImageUrl;
  bool _isUploadingImage = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  void _initFields(MerchantModel shop) {
    if (_isInit) return;
    _nameController = TextEditingController(text: shop.name);
    _phoneController = TextEditingController(text: shop.phone ?? '');
    _addressController = TextEditingController(text: shop.address ?? '');
    _hoursController = TextEditingController(text: shop.openingHours ?? '');
    _isInit = true;
  }

  Future<void> _handleUpdate(String shopId) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(merchantRepositoryProvider)
          .updateShopProfile(
            shopId: shopId,
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            address: _addressController.text.trim(),
            openingHours: _hoursController.text.trim(),
          );

      if (mounted) {
        ref.invalidate(myShopProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thông tin thành công')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopAsync = ref.watch(myShopProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Thông tin cửa hàng',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: shopAsync.when(
        data: (shop) {
          if (shop == null) {
            return const Center(child: Text('Không tìm thấy cửa hàng'));
          }
          _initFields(shop);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(shop),
                  const SizedBox(height: 30),
                  _buildTextField(
                    label: 'Tên cửa hàng',
                    controller: _nameController,
                    icon: Icons.store,
                    validator: (v) => v!.isEmpty ? 'Vui lòng nhập tên' : null,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    label: 'Số điện thoại',
                    controller: _phoneController,
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (v) => v!.isEmpty ? 'Vui lòng nhập SĐT' : null,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    label: 'Địa chỉ',
                    controller: _addressController,
                    icon: Icons.location_on,
                    maxLines: 2,
                    validator: (v) =>
                        v!.isEmpty ? 'Vui lòng nhập địa chỉ' : null,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    label: 'Giờ mở cửa',
                    controller: _hoursController,
                    icon: Icons.access_time,
                    hint: 'VD: 07:00 - 21:00',
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () => _handleUpdate(shop.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.medium),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'LƯU THAY ĐỔI',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Lỗi: $e')),
      ),
    );
  }

  Widget _buildProfileHeader(MerchantModel shop) {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _isUploadingImage ? null : () => _pickAndUploadImage(shop.id),
            child: Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(26),
                    shape: BoxShape.circle,
                    image: _shopImageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(_shopImageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _isUploadingImage
                      ? const Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        )
                      : _shopImageUrl == null
                          ? const Icon(
                              Icons.store_rounded,
                              size: 50,
                              color: AppColors.primary,
                            )
                          : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            shop.name,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Mã cửa hàng: ${shop.id.substring(0, 8)}...',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadImage(String shopId) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (pickedFile == null) return;

    setState(() => _isUploadingImage = true);

    try {
      final file = File(pickedFile.path);
      final fileName = 'shop_$shopId.jpg';
      final supabase = Supabase.instance.client;

      // Upload to Supabase Storage (shop-images bucket)
      await supabase.storage.from('shop-images').upload(
            fileName,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      // Get public URL
      final imageUrl = supabase.storage.from('shop-images').getPublicUrl(fileName);

      setState(() {
        _shopImageUrl = imageUrl;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật ảnh cửa hàng'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi upload: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.small),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.small),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
          ),
        ),
      ],
    );
  }
}
