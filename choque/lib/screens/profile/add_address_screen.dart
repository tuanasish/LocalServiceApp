import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../providers/address_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_address.dart';
import '../../ui/design_system.dart';
import '../../data/models/location_model.dart';

/// ShopeeFood-style Add Address Screen
/// Redesigned based on ShopeeFood UI reference
class AddAddressScreen extends ConsumerStatefulWidget {
  final UserAddress? addressToEdit;
  const AddAddressScreen({super.key, this.addressToEdit});

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'AddAddressScreen(addressToEdit: ${addressToEdit?.id})';
  }

  @override
  ConsumerState<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends ConsumerState<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Contact info (from profile or custom)
  late final TextEditingController _recipientNameController;
  late final TextEditingController _recipientPhoneController;
  
  // Address fields
  late final TextEditingController _detailsController;
  late final TextEditingController _buildingController;
  late final TextEditingController _gateController;
  late final TextEditingController _driverNoteController;
  
  // Address type tag
  late AddressType _selectedAddressType;
  late bool _isDefault;
  
  // Location data
  double? _selectedLat;
  double? _selectedLng;

  @override
  void initState() {
    super.initState();
    final editing = widget.addressToEdit;
    
    _recipientNameController = TextEditingController(text: editing?.recipientName);
    _recipientPhoneController = TextEditingController(text: editing?.recipientPhone);
    _detailsController = TextEditingController(text: editing?.details);
    _buildingController = TextEditingController(text: editing?.building);
    _gateController = TextEditingController(text: editing?.gate);
    _driverNoteController = TextEditingController(text: editing?.driverNote);
    
    _selectedAddressType = editing?.addressType ?? AddressType.home;
    _isDefault = editing?.isDefault ?? false;
    _selectedLat = editing?.lat;
    _selectedLng = editing?.lng;
    
    // Pre-fill contact info from user profile if adding new address
    if (editing == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _prefillFromProfile();
      });
    }
  }

  void _prefillFromProfile() {
    final profileAsync = ref.read(userProfileProvider);
    profileAsync.whenData((profile) {
      if (profile != null) {
        if (_recipientNameController.text.isEmpty && profile.fullName != null) {
          _recipientNameController.text = profile.fullName!;
        }
        if (_recipientPhoneController.text.isEmpty && profile.phone != null) {
          _recipientPhoneController.text = profile.phone!;
        }
      }
    });
  }

  @override
  void dispose() {
    _recipientNameController.dispose();
    _recipientPhoneController.dispose();
    _detailsController.dispose();
    _buildingController.dispose();
    _gateController.dispose();
    _driverNoteController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;
    if (_detailsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn địa chỉ'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final notifier = ref.read(addressNotifierProvider.notifier);
    
    try {
      if (widget.addressToEdit != null) {
        // Update existing
        debugPrint('[AddAddress] Updating address: ${widget.addressToEdit!.id}');
        await notifier.updateAddress(widget.addressToEdit!.copyWith(
          label: _selectedAddressType.displayName,
          details: _detailsController.text.trim(),
          lat: _selectedLat,
          lng: _selectedLng,
          isDefault: _isDefault,
          addressType: _selectedAddressType,
          building: _buildingController.text.trim().isEmpty ? null : _buildingController.text.trim(),
          gate: _gateController.text.trim().isEmpty ? null : _gateController.text.trim(),
          driverNote: _driverNoteController.text.trim().isEmpty ? null : _driverNoteController.text.trim(),
          recipientName: _recipientNameController.text.trim(),
          recipientPhone: _recipientPhoneController.text.trim(),
        ));
        debugPrint('[AddAddress] Update completed');
      } else {
        // Add new
        debugPrint('[AddAddress] Adding new address');
        debugPrint('[AddAddress] Details: ${_detailsController.text.trim()}');
        debugPrint('[AddAddress] Lat: $_selectedLat, Lng: $_selectedLng');
        debugPrint('[AddAddress] AddressType: ${_selectedAddressType.name}');
        await notifier.addAddress(
          label: _selectedAddressType.displayName,
          details: _detailsController.text.trim(),
          lat: _selectedLat,
          lng: _selectedLng,
          isDefault: _isDefault,
          addressType: _selectedAddressType,
          building: _buildingController.text.trim().isEmpty ? null : _buildingController.text.trim(),
          gate: _gateController.text.trim().isEmpty ? null : _gateController.text.trim(),
          driverNote: _driverNoteController.text.trim().isEmpty ? null : _driverNoteController.text.trim(),
          recipientName: _recipientNameController.text.trim(),
          recipientPhone: _recipientPhoneController.text.trim(),
        );
        debugPrint('[AddAddress] Add completed');
      }

      // Check for errors
      final state = ref.read(addressNotifierProvider);
      state.when(
        data: (_) {
          debugPrint('[AddAddress] Success - Address saved');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(widget.addressToEdit != null 
                    ? 'Đã cập nhật địa chỉ thành công' 
                    : 'Đã thêm địa chỉ thành công'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
            context.pop();
          }
        },
        loading: () {
          debugPrint('[AddAddress] Still loading...');
        },
        error: (error, stack) {
          debugPrint('[AddAddress] ERROR: $error');
          debugPrint('[AddAddress] Stack: $stack');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lỗi: ${error.toString()}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
      );
    } catch (e, stack) {
      debugPrint('[AddAddress] EXCEPTION: $e');
      debugPrint('[AddAddress] Stack: $stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi lưu địa chỉ: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _openMapPicker() async {
    LocationModel? initialLocation;
    if (_selectedLat != null && _selectedLng != null) {
      initialLocation = LocationModel(
        label: _selectedAddressType.displayName,
        address: _detailsController.text,
        lat: _selectedLat!,
        lng: _selectedLng!,
      );
    }

    final result = await context.push<LocationModel?>(
      '/address/map-picker',
      extra: initialLocation,
    );

    if (result != null) {
      setState(() {
        _selectedLat = result.lat;
        _selectedLng = result.lng;
        _detailsController.text = result.address ?? result.label;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.addressToEdit != null ? 'Sửa địa chỉ' : 'Thêm địa chỉ mới';
    final isLoading = ref.watch(addressNotifierProvider).isLoading;
    final hasAddress = _detailsController.text.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 17)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Contact Info (ShopeeFood style)
                    _buildSection([
                      _buildContactField(
                        controller: _recipientNameController,
                        hint: 'Tên người nhận',
                        icon: Icons.person_outline,
                        validator: (v) => v!.isEmpty ? 'Vui lòng nhập tên' : null,
                      ),
                      const Divider(height: 1),
                      _buildContactField(
                        controller: _recipientPhoneController,
                        hint: 'Số điện thoại',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (v) => v!.isEmpty ? 'Vui lòng nhập SĐT' : null,
                      ),
                    ]),
                    
                    const SizedBox(height: 8),
                    
                    // Section 2: Address Selection (ShopeeFood style)
                    _buildSection([
                      _buildAddressSelector(),
                    ]),
                    
                    const SizedBox(height: 8),
                    
                    // Section 3: Building & Gate (optional)
                    _buildSection([
                      _buildOptionalField(
                        controller: _buildingController,
                        hint: 'Tòa nhà, Số tầng (Không bắt buộc)',
                      ),
                      const Divider(height: 1),
                      _buildOptionalField(
                        controller: _gateController,
                        hint: 'Cổng (không bắt buộc)',
                      ),
                    ]),
                    
                    const SizedBox(height: 8),
                    
                    // Section 4: Address Type Tags (ShopeeFood style)
                    _buildSection([
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: AddressType.values.map((type) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: _buildAddressTypeTag(type),
                            );
                          }).toList(),
                        ),
                      ),
                    ]),
                    
                    const SizedBox(height: 8),
                    
                    // Section 5: Driver Note (optional)
                    _buildSection([
                      _buildOptionalField(
                        controller: _driverNoteController,
                        hint: 'Ghi chú cho Tài xế (không bắt buộc)',
                        maxLines: 2,
                      ),
                    ]),
                    
                    const SizedBox(height: 8),
                    
                    // Section 6: Default toggle
                    _buildSection([
                      SwitchListTile(
                        title: Text(
                          'Đặt làm địa chỉ mặc định',
                          style: GoogleFonts.inter(fontSize: 15),
                        ),
                        value: _isDefault,
                        onChanged: (v) => setState(() => _isDefault = v),
                        activeThumbColor: AppColors.primary,
                      ),
                    ]),
                    
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            
            // Bottom Save Button
            _buildBottomButton(isLoading, hasAddress),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(List<Widget> children) {
    return Container(
      color: Colors.white,
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildContactField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              validator: validator,
              style: GoogleFonts.inter(fontSize: 15),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          Icon(icon, color: Colors.grey[400], size: 22),
        ],
      ),
    );
  }

  Widget _buildAddressSelector() {
    final hasAddress = _detailsController.text.isNotEmpty;
    
    return InkWell(
      onTap: _openMapPicker,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasAddress) ...[
                    Text(
                      _detailsController.text,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ] else ...[
                    Text(
                      'Chọn địa chỉ',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionalField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.inter(fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildAddressTypeTag(AddressType type) {
    final isSelected = _selectedAddressType == type;
    final label = switch (type) {
      AddressType.home => 'Home',
      AddressType.work => 'Work',
      AddressType.other => 'Other',
    };
    
    return GestureDetector(
      onTap: () => setState(() => _selectedAddressType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? AppColors.primary : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton(bool isLoading, bool hasAddress) {
    final canSave = hasAddress && 
        _recipientNameController.text.isNotEmpty && 
        _recipientPhoneController.text.isNotEmpty;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading || !canSave ? null : _saveAddress,
            style: ElevatedButton.styleFrom(
              backgroundColor: canSave ? AppColors.primary : Colors.grey[300],
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              disabledForegroundColor: Colors.grey[500],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2, 
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Lưu',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
