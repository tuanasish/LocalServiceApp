import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../ui/design_system.dart';

/// Profile Setup Screen
/// New users complete their profile after OTP verification
class ProfileSetupScreen extends ConsumerStatefulWidget {
  final String? fullName;
  const ProfileSetupScreen({super.key, this.fullName});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  DateTime? _selectedBirthDate;
  String? _selectedGender;
  XFile? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.fullName != null) {
      _fullNameController.text = widget.fullName!;
    }
  }

  final List<String> _genderOptions = ['Nam', 'Nữ', 'Khác'];

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 500,
    );

    if (image != null) {
      setState(() => _imageFile = image);
    }
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedBirthDate = picked);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _completeRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // FIX session error: get user directly from supabase client
      final supabase = ref.read(supabaseProvider);
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception('Phiên đăng nhập không tồn tại. Vui lòng thử lại.');
      }

      final authNotifier = ref.read(authNotifierProvider.notifier);
      String? avatarUrl;

      // 1. Upload image if selected
      if (_imageFile != null) {
        avatarUrl = await authNotifier.uploadAvatar(_imageFile!);
      }

      // 2. Create profile
      await authNotifier.createProfile(
        userId: user.id,
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        avatarUrl: avatarUrl,
        birthDate: _selectedBirthDate,
        gender: _selectedGender,
      );

      // 3. Add address if provided
      if (_addressController.text.trim().isNotEmpty) {
        await authNotifier.addAddress(
          userId: user.id,
          details: _addressController.text.trim(),
        );
      }

      // Refresh profile
      ref.invalidate(userProfileProvider);

      if (mounted) {
        // Show success and navigate to home
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng ký thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/');
      }
    } catch (e) {
      String message = 'Không thể lưu hồ sơ. Vui lòng thử lại.';
      if (e.toString().contains('network')) {
        message = 'Lỗi kết nối. Vui lòng kiểm tra internet.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập họ và tên';
    }
    if (value.trim().length < 2) {
      return 'Họ tên quá ngắn';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Hoàn tất đăng ký',
          style: TextStyle(color: Colors.black87),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                // Avatar placeholder
                Center(
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(26),
                            shape: BoxShape.circle,
                            image: _imageFile != null
                                ? DecorationImage(
                                    image: FileImage(File(_imageFile!.path)),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _imageFile == null
                              ? const Icon(
                                  Icons.camera_alt_outlined,
                                  size: 40,
                                  color: AppColors.primary,
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.edit,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Success message
                Text(
                  'Email đã được xác thực',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                const SizedBox(height: 16),
                // Full name field
                _buildSectionTitle('Thông tin cá nhân'),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _fullNameController,
                  label: 'Họ và tên *',
                  icon: Icons.person_outline,
                  autofillHints: const [AutofillHints.name],
                  validator: _validateFullName,
                ),
                const SizedBox(height: 16),
                // Birth Date
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: GestureDetector(
                        onTap: _selectBirthDate,
                        child: AbsorbPointer(
                          child: _buildTextField(
                            controller: TextEditingController(
                              text: _selectedBirthDate == null
                                  ? ''
                                  : '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}',
                            ),
                            label: 'Ngày sinh',
                            icon: Icons.calendar_today_outlined,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Giới tính',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedGender,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                            ),
                            hint: const Text('Chọn'),
                            items: _genderOptions.map((gender) {
                              return DropdownMenuItem(
                                value: gender,
                                child: Text(gender),
                              );
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => _selectedGender = val),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Thông tin liên lạc'),
                const SizedBox(height: 12),
                // Phone field
                _buildTextField(
                  controller: _phoneController,
                  label: 'Số điện thoại',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumber],
                ),
                const SizedBox(height: 16),
                // Address field
                _buildTextField(
                  controller: _addressController,
                  label: 'Địa chỉ',
                  icon: Icons.location_on_outlined,
                  autofillHints: const [AutofillHints.fullStreetAddress],
                  maxLines: 2,
                ),
                const SizedBox(height: 40),
                // Complete button
                ElevatedButton(
                  onPressed: _isLoading ? null : _completeRegistration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E7F43),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'HOÀN TẤT ĐĂNG KÝ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                // Terms text
                Text(
                  'Bằng việc đăng ký, bạn đồng ý với\nĐiều khoản sử dụng và Chính sách bảo mật',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    Iterable<String>? autofillHints,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          autofillHints: autofillHints,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey[600], size: 20),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
