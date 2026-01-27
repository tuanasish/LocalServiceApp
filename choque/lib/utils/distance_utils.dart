import 'package:geolocator/geolocator.dart';

/// Utility functions để tính khoảng cách giữa các tọa độ
class DistanceUtils {
  /// Tính khoảng cách giữa 2 điểm (đơn vị: mét)
  static double calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }

  /// Format khoảng cách thành text (VD: "2.5km", "350m")
  static String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()}m';
    } else {
      final km = distanceInMeters / 1000;
      if (km < 10) {
        return '${km.toStringAsFixed(1)}km';
      } else {
        return '${km.round()}km';
      }
    }
  }

  /// Tính khoảng cách và format
  static String getDistanceText(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final distance = calculateDistance(lat1, lng1, lat2, lng2);
    return formatDistance(distance);
  }
}
