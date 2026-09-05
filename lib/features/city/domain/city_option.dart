import 'package:flutter/foundation.dart';

@immutable
class CityOption {
  const CityOption({
    required this.id,
    required this.name,
    required this.region,
    required this.countryCode,
    required this.latitude,
    required this.longitude,
  });

  factory CityOption.fromJson(Map<String, dynamic> json) {
    return CityOption(
      id: json['id'] as String,
      name: json['name'] as String,
      region: json['region'] as String,
      countryCode: json['countryCode'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  final String id;
  final String name;
  final String region;
  final String countryCode;
  final double latitude;
  final double longitude;
}
