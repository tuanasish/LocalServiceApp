import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../data/repositories/driver_repository.dart';

/// Location Tracking Service
/// 
/// Service để tracking vị trí driver và upload lên server.
class LocationTrackingService {
  final DriverRepository _driverRepository;
  StreamSubscription<Position>? _positionStream;
  String? _currentOrderId;
  bool _isTracking = false;

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
      return null;
    }
  }

  /// Bắt đầu tracking location cho đơn hàng
  Future<void> startTracking(String orderId) async {
    if (_isTracking && _currentOrderId == orderId) {
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

    // Start position stream
    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50, // 50 meters
        timeLimit: const Duration(seconds: 30),
      ),
    ).listen(
      (Position position) {
        _uploadLocation(orderId, position);
      },
      onError: (error) {
        // Log error nhưng không dừng tracking
        print('Location tracking error: $error');
      },
    );
  }

  /// Dừng tracking
  Future<void> stopTracking() async {
    await _positionStream?.cancel();
    _positionStream = null;
    _currentOrderId = null;
    _isTracking = false;
  }

  /// Upload location lên server
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
    } catch (e) {
      // Log error nhưng không throw để không làm gián đoạn tracking
      print('Failed to upload location: $e');
    }
  }

  /// Kiểm tra xem có đang tracking không
  bool get isTracking => _isTracking;

  /// Order ID đang được track
  String? get currentOrderId => _currentOrderId;

  /// Dispose service
  void dispose() {
    stopTracking();
  }
}
