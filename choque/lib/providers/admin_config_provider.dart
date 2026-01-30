import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Model for app config
class AppConfig {
  final String id;
  final String marketId;
  final int configVersion;
  final bool killSwitch;
  final String? maintenanceMessage;
  final Map<String, dynamic> flags;
  final Map<String, dynamic> rules;
  final Map<String, dynamic> limits;
  final DateTime updatedAt;

  AppConfig({
    required this.id,
    required this.marketId,
    required this.configVersion,
    required this.killSwitch,
    this.maintenanceMessage,
    required this.flags,
    required this.rules,
    required this.limits,
    required this.updatedAt,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      id: json['id'] as String,
      marketId: json['market_id'] as String,
      configVersion: json['config_version'] as int? ?? 1,
      killSwitch: json['kill_switch'] as bool? ?? false,
      maintenanceMessage: json['maintenance_message'] as String?,
      flags: json['flags'] as Map<String, dynamic>? ?? {},
      rules: json['rules'] as Map<String, dynamic>? ?? {},
      limits: json['limits'] as Map<String, dynamic>? ?? {},
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // Getters for flags
  String get authMode => flags['auth_mode'] as String? ?? 'guest';
  String get addressMode => flags['address_mode'] as String? ?? 'preset';
  String get pricingMode => flags['pricing_mode'] as String? ?? 'fixed';
  String get trackingMode => flags['tracking_mode'] as String? ?? 'status';
  String get dispatchMode => flags['dispatch_mode'] as String? ?? 'admin';

  // Getters for rules
  int get guestMaxOrders => rules['guest_max_orders'] as int? ?? 10;
  int get guestSessionDays => rules['guest_session_days'] as int? ?? 30;
  bool get requirePhoneForOrder => rules['require_phone_for_order'] as bool? ?? true;

  // Getters for limits
  int get locationIntervalSec => limits['location_interval_sec'] as int? ?? 30;
  int get locationDistanceFilterM => limits['location_distance_filter_m'] as int? ?? 50;
  int get orderTimeoutMinutes => limits['order_timeout_minutes'] as int? ?? 30;
}

final _supabase = Supabase.instance.client;

/// Provider to get current config for admin editing
final adminConfigProvider = FutureProvider.autoDispose.family<AppConfig, String>((ref, marketId) async {
  final response = await _supabase.rpc('admin_get_config', params: {
    'p_market_id': marketId,
  });
  
  return AppConfig.fromJson(response as Map<String, dynamic>);
});

/// Update config - returns updated AppConfig
Future<AppConfig> adminUpdateConfig({
  required String marketId,
  Map<String, dynamic>? flags,
  Map<String, dynamic>? rules,
  Map<String, dynamic>? limits,
}) async {
  final response = await _supabase.rpc('admin_update_config', params: {
    'p_market_id': marketId,
    'p_flags': flags,
    'p_rules': rules,
    'p_limits': limits,
  });
  
  return AppConfig.fromJson(response as Map<String, dynamic>);
}

/// Invalidate admin config provider
void invalidateAdminConfigProviders(WidgetRef ref) {
  ref.invalidate(adminConfigProvider);
}
