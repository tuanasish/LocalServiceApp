import 'package:url_launcher/url_launcher.dart';

/// Navigation Service
///
/// Service để mở navigation app bên ngoài (Google Maps, VietMap, etc.)
class NavigationService {
  /// Mở navigation app với tọa độ đích
  ///
  /// [lat] - Vĩ độ đích
  /// [lng] - Kinh độ đích
  /// [label] - Tên địa điểm (optional)
  ///
  /// Thử mở theo thứ tự:
  /// 1. Google Maps app
  /// 2. VietMap app (nếu có)
  /// 3. Google Maps web (fallback)
  static Future<bool> openNavigationApp({
    required double lat,
    required double lng,
    String? label,
  }) async {
    // Thử mở Google Maps app trước
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng${label != null ? '&query_place_id=$label' : ''}',
    );

    if (await canLaunchUrl(googleMapsUrl)) {
      try {
        final launched = await launchUrl(
          googleMapsUrl,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return true;
      } catch (e) {
        // Fallback nếu launchUrl fail
      }
    }

    // Fallback: Mở Google Maps web
    final googleMapsWebUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );

    try {
      return await launchUrl(
        googleMapsWebUrl,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      return false;
    }
  }

  /// Mở navigation với điểm xuất phát và đích
  ///
  /// [originLat], [originLng] - Tọa độ điểm xuất phát
  /// [destLat], [destLng] - Tọa độ điểm đích
  /// [originLabel] - Tên điểm xuất phát (optional)
  /// [destLabel] - Tên điểm đích (optional)
  static Future<bool> openNavigationWithRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    String? originLabel,
    String? destLabel,
  }) async {
    // Google Maps với route
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=$originLat,$originLng&destination=$destLat,$destLng&travelmode=driving',
    );

    if (await canLaunchUrl(googleMapsUrl)) {
      try {
        final launched = await launchUrl(
          googleMapsUrl,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return true;
      } catch (e) {
        // Fallback
      }
    }

    // Fallback: Mở web
    final googleMapsWebUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=$originLat,$originLng&destination=$destLat,$destLng',
    );

    try {
      return await launchUrl(
        googleMapsWebUrl,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      return false;
    }
  }
}
