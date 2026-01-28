import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../data/repositories/driver_repository.dart';

/// Location Tracking Service
///
/// Service để tracking vị trí driver và upload lên server.
/// Có retry logic, error handling, và tracking statistics.
class LocationTrackingService {
  final DriverRepository _driverRepository;
  StreamSubscription<Position>? _positionStream;
  String? _currentOrderId;
  bool _isTracking = false;

  // Retry logic
  int _uploadRetryCount = 0;
  static const int _maxRetries = 3;

  // Tracking statistics
  int _uploadSuccessCount = 0;
  int _uploadFailureCount = 0;
  DateTime? _lastUploadTime;
  DateTime? _trackingStartTime;

  LocationTrackingService(this._driverRepository);

  /// Kiểm tra permission
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request permission
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Lấy vị trí hiện tại
  Future<Position?> getCurrentLocation() async {
    try {
      final permission = await checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = await requestPermission();
        if (requested == LocationPermission.denied ||
            requested == LocationPermission.deniedForever) {
          return null;
        }
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      debugPrint('[GPS] Error getting current location: $e');
      return null;
    }
  }

  /// Bắt đầu tracking location cho đơn hàng
  Future<void> startTracking(String orderId) async {
    if (_isTracking && _currentOrderId == orderId) {
      debugPrint('[GPS] Already tracking order: $orderId');
      return; // Đã đang track đơn này
    }

    // Dừng tracking cũ nếu có
    await stopTracking();

    // Kiểm tra permission
    final permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      final requested = await requestPermission();
      if (requested == LocationPermission.denied ||
          requested == LocationPermission.deniedForever) {
        throw Exception('Location permission denied');
      }
    }

    _currentOrderId = orderId;
    _isTracking = true;
    _trackingStartTime = DateTime.now();

    // Reset statistics
    _uploadSuccessCount = 0;
    _uploadFailureCount = 0;
    _lastUploadTime = null;

    debugPrint('[GPS] Started tracking for order: $orderId');

    // Start position stream
    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: _getLocationSettings(),
        ).listen(
          (Position position) {
            _uploadLocation(orderId, position);
          },
          onError: (error) {
            debugPrint('[GPS] Position stream error: $error');
            // Log error nhưng không dừng tracking
          },
        );
  }

  /// Dừng tracking
  Future<void> stopTracking() async {
    if (!_isTracking) return;

    await _positionStream?.cancel();
    _positionStream = null;

    final orderId = _currentOrderId;
    _currentOrderId = null;
    _isTracking = false;
    _uploadRetryCount = 0;

    if (orderId != null) {
      debugPrint('[GPS] Stopped tracking for order: $orderId');
      debugPrint(
        '[GPS] Stats - Success: $_uploadSuccessCount, Failure: $_uploadFailureCount',
      );
    }
  }

  /// Get location settings (can be adjusted for battery optimization)
  LocationSettings _getLocationSettings() {
    // TODO: Adjust based on battery level
    // For now, use standard settings
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 50, // 50 meters
      timeLimit: Duration(seconds: 30),
    );
  }

  /// Upload location lên server với retry logic
  Future<void> _uploadLocation(String orderId, Position position) async {
    try {
      await _driverRepository.updateLocation(
        orderId: orderId,
        lat: position.latitude,
        lng: position.longitude,
        heading: position.heading,
        speed: position.speed,
        accuracy: position.accuracy,
      );

      // Success
      _uploadSuccessCount++;
      _uploadRetryCount = 0; // Reset retry count
      _lastUploadTime = DateTime.now();

      debugPrint(
        '[GPS] Location uploaded: (${position.latitude}, ${position.longitude}) for order: $orderId',
      );
    } catch (e) {
      _uploadFailureCount++;
      debugPrint(
        '[GPS] Failed to upload location (attempt ${_uploadRetryCount + 1}/$_maxRetries): $e',
      );

      // Retry logic
      if (_uploadRetryCount < _maxRetries) {
        _uploadRetryCount++;
        final delaySeconds = 2 * _uploadRetryCount; // Exponential backoff

        debugPrint('[GPS] Retrying in $delaySeconds seconds...');
        await Future.delayed(Duration(seconds: delaySeconds));

        // Retry upload
        await _uploadLocation(orderId, position);
      } else {
        debugPrint(
          '[GPS] Max retries reached, giving up on this location update',
        );
        _uploadRetryCount = 0; // Reset for next update
      }
    }
  }

  /// Kiểm tra xem có đang tracking không
  bool get isTracking => _isTracking;

  /// Order ID đang được track
  String? get currentOrderId => _currentOrderId;

  /// Get tracking statistics (for debugging)
  Map<String, dynamic> getTrackingStats() {
    return {
      'isTracking': _isTracking,
      'orderId': _currentOrderId,
      'uploadSuccess': _uploadSuccessCount,
      'uploadFailure': _uploadFailureCount,
      'lastUpload': _lastUploadTime?.toIso8601String(),
      'trackingStartTime': _trackingStartTime?.toIso8601String(),
      'trackingDuration': _trackingStartTime != null
          ? DateTime.now().difference(_trackingStartTime!).inMinutes
          : 0,
    };
  }

  /// Dispose service
  void dispose() {
    stopTracking();
  }
}
