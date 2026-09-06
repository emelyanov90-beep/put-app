import 'package:flutter/foundation.dart';

/// Position of a point inside the driver route.
///
/// The order itself is the index in [TripDraft.points]; this only describes the
/// role of a point, matching `trip_stops.stop_type` in the data model.
enum TripStopKind { origin, intermediate, destination }

/// One point of a driver route: pick-up, planned stop, or destination.
///
/// Coordinates stay optional while no geocoding service is connected — the TZ
/// allows picking points from a test catalog or entering an address manually.
@immutable
class TripRoutePoint {
  const TripRoutePoint({
    required this.address,
    this.cityId,
    this.cityName,
    this.latitude,
    this.longitude,
  });

  final String address;
  final String? cityId;
  final String? cityName;
  final double? latitude;
  final double? longitude;

  bool get isFilled => address.trim().isNotEmpty;

  TripRoutePoint copyWith({
    String? address,
    String? cityId,
    String? cityName,
    double? latitude,
    double? longitude,
  }) {
    return TripRoutePoint(
      address: address ?? this.address,
      cityId: cityId ?? this.cityId,
      cityName: cityName ?? this.cityName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TripRoutePoint &&
        other.address == address &&
        other.cityId == cityId &&
        other.cityName == cityName &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode =>
      Object.hash(address, cityId, cityName, latitude, longitude);
}
