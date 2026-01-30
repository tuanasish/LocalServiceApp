import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/admin_config_provider.dart';
import '../../ui/design_system.dart';

class AdminConfigScreen extends ConsumerStatefulWidget {
  const AdminConfigScreen({super.key});

  @override
  ConsumerState<AdminConfigScreen> createState() => _AdminConfigScreenState();
}

class _AdminConfigScreenState extends ConsumerState<AdminConfigScreen> {
  static const String _marketId = 'default';
  bool _isLoading = false;

  // Flags
  String _authMode = 'guest';
  String _addressMode = 'preset';
  String _pricingMode = 'fixed';
  String _trackingMode = 'status';
  String _dispatchMode = 'admin';

  // Rules
  int _guestMaxOrders = 10;
  int _guestSessionDays = 30;
  bool _requirePhoneForOrder = true;

  // Limits
  int _locationIntervalSec = 30;
  int _locationDistanceFilterM = 50;
  int _orderTimeoutMinutes = 30;

  bool _hasChanges = false;

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(adminConfigProvider(_marketId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cài đặt hệ thống'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isLoading ? null : _saveConfig,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Lưu'),
            ),
        ],
      ),
      body: configAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Lỗi: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(adminConfigProvider(_marketId)),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (config) {
          // Initialize state from config on first load
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_hasChanges) {
              setState(() {
                _authMode = config.authMode;
                _addressMode = config.addressMode;
                _pricingMode = config.pricingMode;
                _trackingMode = config.trackingMode;
                _dispatchMode = config.dispatchMode;
                _guestMaxOrders = config.guestMaxOrders;
                _guestSessionDays = config.guestSessionDays;
                _requirePhoneForOrder = config.requirePhoneForOrder;
                _locationIntervalSec = config.locationIntervalSec;
                _locationDistanceFilterM = config.locationDistanceFilterM;
                _orderTimeoutMinutes = config.orderTimeoutMinutes;
              });
            }
          });

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(adminConfigProvider(_marketId));
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Config version info
                _buildInfoCard(config),
                const SizedBox(height: 24),

                // Feature Flags
                _buildSectionHeader('Chế độ hoạt động'),
                const SizedBox(height: 12),
                _buildFlagsSection(),
                const SizedBox(height: 24),

                // Rules
                _buildSectionHeader('Quy tắc'),
                const SizedBox(height: 12),
                _buildRulesSection(),
                const SizedBox(height: 24),

                // Limits
                _buildSectionHeader('Giới hạn'),
                const SizedBox(height: 12),
                _buildLimitsSection(),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
      floatingActionButton: _hasChanges
          ? FloatingActionButton.extended(
              onPressed: _isLoading ? null : _saveConfig,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: const Text('Lưu thay đổi'),
            )
          : null,
    );
  }

  Widget _buildInfoCard(AppConfig config) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Phiên bản cấu hình: ${config.configVersion}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Cập nhật lần cuối: ${_formatDate(config.updatedAt)}',
                  style: TextStyle(
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildFlagsSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildDropdownTile(
            title: 'Chế độ xác thực',
            subtitle: 'Cách người dùng đăng nhập',
            value: _authMode,
            options: const {'guest': 'Khách (Guest)', 'otp': 'OTP'},
            onChanged: (v) => _updateValue(() => _authMode = v!),
            icon: Icons.login,
          ),
          const Divider(height: 1),
          _buildDropdownTile(
            title: 'Chế độ địa chỉ',
            subtitle: 'Cách chọn địa chỉ giao hàng',
            value: _addressMode,
            options: const {'preset': 'Địa chỉ cố định', 'vietmap': 'VietMap GPS'},
            onChanged: (v) => _updateValue(() => _addressMode = v!),
            icon: Icons.location_on,
          ),
          const Divider(height: 1),
          _buildDropdownTile(
            title: 'Chế độ giá',
            subtitle: 'Cách tính phí giao hàng',
            value: _pricingMode,
            options: const {'fixed': 'Cố định', 'gps': 'Theo GPS'},
            onChanged: (v) => _updateValue(() => _pricingMode = v!),
            icon: Icons.attach_money,
          ),
          const Divider(height: 1),
          _buildDropdownTile(
            title: 'Chế độ theo dõi',
            subtitle: 'Cách theo dõi đơn hàng',
            value: _trackingMode,
            options: const {'status': 'Trạng thái', 'realtime': 'Realtime GPS'},
            onChanged: (v) => _updateValue(() => _trackingMode = v!),
            icon: Icons.my_location,
          ),
          const Divider(height: 1),
          _buildDropdownTile(
            title: 'Chế độ gán tài xế',
            subtitle: 'Cách gán đơn cho tài xế',
            value: _dispatchMode,
            options: const {'admin': 'Admin gán tay', 'auto': 'Tự động'},
            onChanged: (v) => _updateValue(() => _dispatchMode = v!),
            icon: Icons.delivery_dining,
          ),
        ],
      ),
    );
  }

  Widget _buildRulesSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildNumberTile(
            title: 'Số đơn tối đa (Guest)',
            subtitle: 'Giới hạn đơn cho tài khoản khách',
            value: _guestMaxOrders,
            onChanged: (v) => _updateValue(() => _guestMaxOrders = v),
            icon: Icons.shopping_cart,
            min: 1,
            max: 100,
          ),
          const Divider(height: 1),
          _buildNumberTile(
            title: 'Thời hạn session (ngày)',
            subtitle: 'Số ngày lưu session khách',
            value: _guestSessionDays,
            onChanged: (v) => _updateValue(() => _guestSessionDays = v),
            icon: Icons.schedule,
            min: 1,
            max: 365,
          ),
          const Divider(height: 1),
          _buildSwitchTile(
            title: 'Yêu cầu SĐT đặt hàng',
            subtitle: 'Bắt buộc nhập SĐT khi đặt đơn',
            value: _requirePhoneForOrder,
            onChanged: (v) => _updateValue(() => _requirePhoneForOrder = v),
            icon: Icons.phone,
          ),
        ],
      ),
    );
  }

  Widget _buildLimitsSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildNumberTile(
            title: 'Interval vị trí (giây)',
            subtitle: 'Tần suất cập nhật GPS tài xế',
            value: _locationIntervalSec,
            onChanged: (v) => _updateValue(() => _locationIntervalSec = v),
            icon: Icons.timer,
            min: 5,
            max: 120,
          ),
          const Divider(height: 1),
          _buildNumberTile(
            title: 'Khoảng cách filter (m)',
            subtitle: 'Khoảng cách tối thiểu để cập nhật',
            value: _locationDistanceFilterM,
            onChanged: (v) => _updateValue(() => _locationDistanceFilterM = v),
            icon: Icons.straighten,
            min: 10,
            max: 500,
          ),
          const Divider(height: 1),
          _buildNumberTile(
            title: 'Timeout đơn hàng (phút)',
            subtitle: 'Thời gian chờ xác nhận tối đa',
            value: _orderTimeoutMinutes,
            onChanged: (v) => _updateValue(() => _orderTimeoutMinutes = v),
            icon: Icons.hourglass_empty,
            min: 5,
            max: 120,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String subtitle,
    required String value,
    required Map<String, String> options,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: Text(subtitle, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      trailing: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        items: options.entries
            .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildNumberTile({
    required String title,
    required String subtitle,
    required int value,
    required ValueChanged<int> onChanged,
    required IconData icon,
    required int min,
    required int max,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: Text(subtitle, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 40,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: Text(subtitle, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      value: value,
      onChanged: onChanged,
    );
  }

  void _updateValue(VoidCallback update) {
    setState(() {
      update();
      _hasChanges = true;
    });
  }

  Future<void> _saveConfig() async {
    setState(() => _isLoading = true);

    try {
      await adminUpdateConfig(
        marketId: _marketId,
        flags: {
          'auth_mode': _authMode,
          'address_mode': _addressMode,
          'pricing_mode': _pricingMode,
          'tracking_mode': _trackingMode,
          'dispatch_mode': _dispatchMode,
        },
        rules: {
          'guest_max_orders': _guestMaxOrders,
          'guest_session_days': _guestSessionDays,
          'require_phone_for_order': _requirePhoneForOrder,
        },
        limits: {
          'location_interval_sec': _locationIntervalSec,
          'location_distance_filter_m': _locationDistanceFilterM,
          'order_timeout_minutes': _orderTimeoutMinutes,
        },
      );

      if (mounted) {
        setState(() {
          _hasChanges = false;
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã lưu cài đặt thành công'),
            backgroundColor: AppColors.success,
          ),
        );

        // Refresh the provider
        ref.invalidate(adminConfigProvider(_marketId));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
