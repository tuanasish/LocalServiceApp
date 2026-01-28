import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/profile_model.dart';
import '../data/models/driver_location_model.dart';
import 'app_providers.dart';

/// Driver Admin Providers
///
/// Providers for admin driver management features.

// ============================================
// DRIVER LISTS
// ============================================

/// All drivers (admin only)
final allDriversProvider = FutureProvider.autoDispose<List<ProfileModel>>((
  ref,
) async {
  final repo = ref.read(driverRepositoryProvider);
  return await repo.getAllDrivers();
});

/// Pending drivers (need approval)
final pendingDriversProvider = FutureProvider.autoDispose<List<ProfileModel>>((
  ref,
) async {
  final repo = ref.read(driverRepositoryProvider);
  return await repo.getAllDrivers(approvalStatus: 'pending');
});

/// Approved drivers
final approvedDriversProvider = FutureProvider.autoDispose<List<ProfileModel>>((
  ref,
) async {
  final repo = ref.read(driverRepositoryProvider);
  return await repo.getAllDrivers(approvalStatus: 'approved');
});

/// Rejected drivers
final rejectedDriversProvider = FutureProvider.autoDispose<List<ProfileModel>>((
  ref,
) async {
  final repo = ref.read(driverRepositoryProvider);
  return await repo.getAllDrivers(approvalStatus: 'rejected');
});

/// Online drivers (approved + online)
final onlineDriversProvider = FutureProvider.autoDispose<List<ProfileModel>>((
  ref,
) async {
  final repo = ref.read(driverRepositoryProvider);
  return await repo.getAllDrivers(
    approvalStatus: 'approved',
    driverStatus: 'online',
  );
});

/// Busy drivers (approved + busy)
final busyDriversProvider = FutureProvider.autoDispose<List<ProfileModel>>((
  ref,
) async {
  final repo = ref.read(driverRepositoryProvider);
  return await repo.getAllDrivers(
    approvalStatus: 'approved',
    driverStatus: 'busy',
  );
});

// ============================================
// DRIVER DETAIL
// ============================================

/// Driver detail by ID
final driverDetailProvider = FutureProvider.autoDispose
    .family<ProfileModel, String>((ref, driverId) async {
      final repo = ref.read(driverRepositoryProvider);
      return await repo.getDriverById(driverId);
    });

/// Driver statistics
final driverStatsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, driverId) async {
      final repo = ref.read(driverRepositoryProvider);
      return await repo.getDriverStatistics(driverId);
    });

/// Driver order history
final driverOrderHistoryProvider = FutureProvider.autoDispose
    .family<List<dynamic>, String>((ref, driverId) async {
      final repo = ref.read(driverRepositoryProvider);
      return await repo.getDriverOrderHistory(driverId);
    });

// ============================================
// REAL-TIME DRIVER LOCATIONS
// ============================================

/// Stream of all driver locations (real-time)
final driverLocationsStreamProvider =
    StreamProvider.autoDispose<List<DriverLocationModel>>((ref) {
      final client = ref.read(supabaseClientProvider);

      return client
          .from('driver_locations')
          .stream(primaryKey: ['driver_id'])
          .map(
            (data) =>
                data.map((json) => DriverLocationModel.fromJson(json)).toList(),
          );
    });

/// Get current location for a specific driver
final driverCurrentLocationProvider = StreamProvider.autoDispose
    .family<DriverLocationModel?, String>((ref, driverId) {
      final client = ref.read(supabaseClientProvider);

      return client
          .from('driver_locations')
          .stream(primaryKey: ['driver_id'])
          .eq('driver_id', driverId)
          .map((data) {
            if (data.isEmpty) return null;
            return DriverLocationModel.fromJson(data.first);
          });
    });

// ============================================
// DRIVER COUNTS (for dashboard badges)
// ============================================

/// Count of pending drivers
final pendingDriversCountProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  final drivers = await ref.watch(pendingDriversProvider.future);
  return drivers.length;
});

/// Count of online drivers
final onlineDriversCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final drivers = await ref.watch(onlineDriversProvider.future);
  return drivers.length;
});

/// Count of busy drivers
final busyDriversCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final drivers = await ref.watch(busyDriversProvider.future);
  return drivers.length;
});
