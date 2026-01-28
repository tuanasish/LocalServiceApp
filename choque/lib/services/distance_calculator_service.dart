import 'dart:math';
import '../data/models/location_model.dart';
import 'vietmap_api_service.dart';

/// Distance Calculator Service
///
/// Tính khoảng cách và thời gian ước tính giữa 2 điểm.
/// Sử dụng VietMap Routing API hoặc Haversine formula fallback.
class DistanceCalculatorService {
  final VietmapApiService _vietmapService = VietmapApiService();

  /// Tính khoảng cách và thời gian sử dụng VietMap Routing API
  ///
  /// Returns: Map với 'distance' (km) và 'duration' (phút)
  Future<Map<String, double>> getDistanceAndDuration({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    try {
      final route = await _vietmapService.getRoute(
        originLat: originLat,
        originLng: originLng,
        destLat: destLat,
        destLng: destLng,
      );

      if (route != null) {
        // VietMap trả về distance (meters) và duration (seconds)
        final distanceMeters = (route['distance'] as num?)?.toDouble() ?? 0;
        final durationSeconds = (route['duration'] as num?)?.toDouble() ?? 0;

        return {
          'distance': distanceMeters / 1000, // Convert to km
          'duration': durationSeconds / 60, // Convert to minutes
        };
      }
    } catch (_) {
      // Fallback to Haversine if API fails (silently)
    }

    // Fallback: Haversine formula
    final distance = _calculateHaversineDistance(
      originLat,
      originLng,
      destLat,
      destLng,
    );

    // Estimate duration: average speed 25 km/h in urban areas
    final duration = (distance / 25) * 60;

    return {'distance': distance, 'duration': duration};
  }

  /// Tính khoảng cách Haversine (đường chim bay)
  double _calculateHaversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371.0; // Radius of Earth in km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degree) => degree * pi / 180;

  /// Tính khoảng cách từ LocationModel
  Future<Map<String, double>> getDistanceBetweenLocations(
    LocationModel origin,
    LocationModel destination,
  ) {
    return getDistanceAndDuration(
      originLat: origin.lat,
      originLng: origin.lng,
      destLat: destination.lat,
      destLng: destination.lng,
    );
  }

  /// Format distance cho hiển thị
  static String formatDistance(double km) {
    if (km < 1) {
      return '${(km * 1000).round()} m';
    }
    return '${km.toStringAsFixed(1)} km';
  }

  /// Format duration cho hiển thị
  static String formatDuration(double minutes) {
    if (minutes < 1) {
      return '< 1 phút';
    }
    if (minutes < 60) {
      return '${minutes.round()} phút';
    }
    final hours = (minutes / 60).floor();
    final mins = (minutes % 60).round();
    return '$hours giờ ${mins > 0 ? '$mins phút' : ''}';
  }
}
