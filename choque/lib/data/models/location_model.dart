/// Location Model
/// 
/// Ánh xạ cấu trúc JSONB pickup/dropoff trong bảng orders.
class LocationModel {
  final String label;
  final String? address;
  final double lat;
  final double lng;

  const LocationModel({
    required this.label,
    this.address,
    required this.lat,
    required this.lng,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      label: json['label'] as String,
      address: json['address'] as String?,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'address': address,
      'lat': lat,
      'lng': lng,
    };
  }
}
