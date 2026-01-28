import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';

/// Vietmap API Service
///
/// Service để gọi Vietmap API: search address, reverse geocode, directions
class VietmapApiService {
  static const String _baseUrl = 'https://maps.vietmap.vn';
  final String _apiKey;

  VietmapApiService() : _apiKey = AppConstants.vietmapServicesKey;

  /// Tìm kiếm địa chỉ
  ///
  /// [query] - Từ khóa tìm kiếm
  /// [focusLat] - Vĩ độ để focus search (optional, nếu có sẽ ưu tiên kết quả gần vị trí này)
  /// [focusLng] - Kinh độ để focus search (optional)
  /// Returns: List of search results với lat, lng, address
  Future<List<Map<String, dynamic>>> searchAddress(
    String query, {
    double? focusLat,
    double? focusLng,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception('Vietmap Services Key chưa được cấu hình');
    }

    try {
      // Trim và validate query
      final trimmedQuery = query.trim();
      if (trimmedQuery.isEmpty) {
        return [];
      }

      // Build URL - không giới hạn boundary, tìm kiếm toàn Việt Nam
      var urlString =
          '$_baseUrl/api/search'
          '?api-version=1.1'
          '&apikey=$_apiKey'
          '&text=${Uri.encodeComponent(trimmedQuery)}';

      // Thêm focus point nếu có (format: focus.point.lat và focus.point.lon)
      // Nếu gây lỗi 500, sẽ retry không có focus point
      if (focusLat != null && focusLng != null) {
        urlString += '&focus.point.lat=$focusLat&focus.point.lon=$focusLng';
      }

      final url = Uri.parse(urlString);

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Vietmap API có thể trả về 2 format:
        // 1. Direct format: {"features": [...]}
        // 2. Wrapped format: {"code":"OK","data":{"features":[...]}}
        List<dynamic>? featuresList;

        if (responseData['features'] != null) {
          // Direct format
          featuresList = responseData['features'] as List<dynamic>?;
        } else if (responseData['data'] != null &&
            responseData['data'] is Map) {
          // Wrapped format
          final dataWrapper = responseData['data'] as Map<String, dynamic>;
          if (dataWrapper['features'] != null) {
            featuresList = dataWrapper['features'] as List<dynamic>?;
          }
        }

        if (featuresList != null && featuresList.isNotEmpty) {
          final features = List<Map<String, dynamic>>.from(
            featuresList.map((f) => f as Map<String, dynamic>),
          );
          return features;
        }

        return [];
      } else {
        // Nếu lỗi 500, có thể thử lại không có focus point
        if (response.statusCode == 500 &&
            focusLat != null &&
            focusLng != null) {
          return await searchAddress(trimmedQuery); // Retry without focus
        }

        throw Exception('API error: ${response.statusCode}');
      }
    } catch (e) {
      // Nếu là lỗi retry, throw lại exception gốc
      if (e.toString().contains('API error')) {
        rethrow;
      }
      throw Exception('Lỗi tìm kiếm địa chỉ: $e');
    }
  }

  /// Reverse geocode - Lấy địa chỉ từ tọa độ
  ///
  /// [lat] - Vĩ độ
  /// [lng] - Kinh độ
  /// Returns: Địa chỉ text
  Future<String?> reverseGeocode(double lat, double lng) async {
    if (_apiKey.isEmpty) {
      throw Exception('Vietmap Services Key chưa được cấu hình');
    }

    try {
      final url = Uri.parse(
        '$_baseUrl/api/reverse?api-version=1.1&apikey=$_apiKey&point.lat=$lat&point.lon=$lng',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        List<dynamic>? featuresList;

        // Parse response - có thể có cấu trúc lồng nhau như search API
        if (responseData['features'] != null) {
          featuresList = responseData['features'] as List<dynamic>?;
        } else if (responseData['data'] != null &&
            responseData['data'] is Map) {
          final dataWrapper = responseData['data'] as Map<String, dynamic>;
          if (dataWrapper['features'] != null) {
            featuresList = dataWrapper['features'] as List<dynamic>?;
          }
        }

        if (featuresList != null && featuresList.isNotEmpty) {
          final feature = featuresList[0] as Map<String, dynamic>;
          final properties = feature['properties'] as Map<String, dynamic>?;

          // Lấy formatted address hoặc name
          final address =
              properties?['label'] as String? ??
              properties?['name'] as String? ??
              feature['place_name'] as String? ??
              properties?['address'] as String? ??
              properties?['full_address'] as String?;

          return address;
        }

        return null;
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi reverse geocode: $e');
    }
  }

  /// Lấy route từ điểm xuất phát đến đích
  ///
  /// [originLat], [originLng] - Tọa độ điểm xuất phát
  /// [destLat], [destLng] - Tọa độ điểm đích
  /// Returns: Route data với geometry (polyline) và distance, duration
  Future<Map<String, dynamic>?> getRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception('Vietmap Services Key chưa được cấu hình');
    }

    try {
      final url = Uri.parse(
        '$_baseUrl/api/route?api-version=1.1&apikey=$_apiKey'
        '&point=$originLat,$originLng'
        '&point=$destLat,$destLng'
        '&vehicle=car',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          return data['routes'][0] as Map<String, dynamic>;
        }
        return null;
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi lấy route: $e');
    }
  }
}
