import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/supabase_client.dart';
import '../models/user_address.dart'; // Includes AddressType enum
import 'app_providers.dart' show currentUserProvider;

/// Provider for list of user addresses
final userAddressesProvider = FutureProvider<List<UserAddress>>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return [];

  final supabase = SupabaseService.client;
  final response = await supabase
      .from('addresses')
      .select()
      .eq('user_id', user.id)
      .order('is_default', ascending: false)
      .order('created_at', ascending: false);

  return (response as List).map((json) => UserAddress.fromJson(json)).toList();
});

/// Notifier for address actions (CRUD)
class AddressNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  /// Add new address with ShopeeFood-style fields
  Future<void> addAddress({
    required String label,
    required String details,
    double? lat,
    double? lng,
    bool isDefault = false,
    AddressType addressType = AddressType.other,
    String? building,
    String? gate,
    String? driverNote,
    String? recipientName,
    String? recipientPhone,
  }) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) {
      debugPrint('[AddressProvider] ERROR: User is null, cannot add address');
      return;
    }

    debugPrint('[AddressProvider] Adding address for user: ${user.id}');
    debugPrint(
      '[AddressProvider] Address data: label=$label, details=$details, lat=$lat, lng=$lng',
    );
    debugPrint(
      '[AddressProvider] AddressType: ${addressType.name}, isDefault: $isDefault',
    );

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final supabase = SupabaseService.client;

      if (isDefault) {
        debugPrint('[AddressProvider] Setting other addresses to non-default');
        await supabase
            .from('addresses')
            .update({'is_default': false})
            .eq('user_id', user.id);
      }

      final insertData = {
        'user_id': user.id,
        'label': label,
        'details': details,
        'lat': lat,
        'lng': lng,
        'is_default': isDefault,
        'address_type': addressType.name,
        'building': building,
        'gate': gate,
        'driver_note': driverNote,
        'recipient_name': recipientName,
        'recipient_phone': recipientPhone,
      };

      debugPrint('[AddressProvider] Inserting data: $insertData');

      final response = await supabase
          .from('addresses')
          .insert(insertData)
          .select();

      debugPrint('[AddressProvider] Insert response: $response');
      debugPrint('[AddressProvider] Address inserted successfully');

      ref.invalidate(userAddressesProvider);
    });

    // Log final state
    state.when(
      data: (_) => debugPrint('[AddressProvider] State: Success'),
      loading: () => debugPrint('[AddressProvider] State: Loading'),
      error: (error, stack) {
        debugPrint('[AddressProvider] State: ERROR - $error');
        debugPrint('[AddressProvider] Stack: $stack');
      },
    );
  }

  /// Update existing address with ShopeeFood-style fields
  Future<void> updateAddress(UserAddress address) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final supabase = SupabaseService.client;

      if (address.isDefault) {
        await supabase
            .from('addresses')
            .update({'is_default': false})
            .eq('user_id', address.userId);
      }

      await supabase
          .from('addresses')
          .update({
            'label': address.label,
            'details': address.details,
            'lat': address.lat,
            'lng': address.lng,
            'is_default': address.isDefault,
            'address_type': address.addressType.name,
            'building': address.building,
            'gate': address.gate,
            'driver_note': address.driverNote,
            'recipient_name': address.recipientName,
            'recipient_phone': address.recipientPhone,
          })
          .eq('id', address.id);

      ref.invalidate(userAddressesProvider);
    });
  }

  /// Delete address
  Future<void> deleteAddress(String addressId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final supabase = SupabaseService.client;
      await supabase.from('addresses').delete().eq('id', addressId);
      ref.invalidate(userAddressesProvider);
    });
  }

  /// Set as default
  Future<void> setAsDefault(String addressId) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final supabase = SupabaseService.client;

      await supabase
          .from('addresses')
          .update({'is_default': false})
          .eq('user_id', user.id);

      await supabase
          .from('addresses')
          .update({'is_default': true})
          .eq('id', addressId);

      ref.invalidate(userAddressesProvider);
    });
  }
}

final addressNotifierProvider =
    NotifierProvider<AddressNotifier, AsyncValue<void>>(() {
      return AddressNotifier();
    });
