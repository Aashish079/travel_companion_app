class LocationModel {
  final double latitude;
  final double longitude;
  final double? heading;
  final DateTime timestamp;

  LocationModel({
    required this.latitude,
    required this.longitude,
    this.heading,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'heading': heading,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'LocationModel(lat: $latitude, lng: $longitude, heading: $heading, time: $timestamp)';
  }
}
