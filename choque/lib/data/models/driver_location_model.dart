/// Driver Location Model
class DriverLocationModel {
  final String driverId;
  final String? orderId;
  final double lat;
  final double lng;
  final double? heading;
  final double? speed;
  final double? accuracy;
  final DateTime updatedAt;

  const DriverLocationModel({
    required this.driverId,
    this.orderId,
    required this.lat,
    required this.lng,
    this.heading,
    this.speed,
    this.accuracy,
    required this.updatedAt,
  });

  factory DriverLocationModel.fromJson(Map<String, dynamic> json) {
    return DriverLocationModel(
      driverId: json['driver_id'] as String,
      orderId: json['order_id'] as String?,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driver_id': driverId,
      'order_id': orderId,
      'lat': lat,
      'lng': lng,
      'heading': heading,
      'speed': speed,
      'accuracy': accuracy,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
