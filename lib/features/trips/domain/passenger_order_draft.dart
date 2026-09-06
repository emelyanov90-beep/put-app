import 'package:flutter/foundation.dart';
import 'package:vput/features/trips/domain/passenger_trip.dart';
import 'package:vput/features/trips/domain/trip_departure_slots.dart';
import 'package:vput/features/trips/domain/trip_extras.dart';
import 'package:vput/features/trips/domain/trip_route_point.dart';

/// A new order starts with an empty pickup and destination, like the driver
/// wizard does. The addresses shown in the Figma frame are mock content.
const _initialOrderRoute = <TripRoutePoint>[
  TripRoutePoint(address: ''),
  TripRoutePoint(address: ''),
];

@immutable
class PassengerOrderDraft {
  const PassengerOrderDraft({
    this.transportType = PassengerTransportType.car,
    this.points = _initialOrderRoute,
    this.departureAt,
    this.arrivalAt,
    this.passengerCount = 1,
    this.extras = const {},
    this.parcelSize,
  });

  /// Step 1 of the wizard: a seat for the passenger (car) or a parcel (bus).
  final PassengerTransportType transportType;
  final List<TripRoutePoint> points;
  final DateTime? departureAt;
  final DateTime? arrivalAt;
  final int passengerCount;

  /// Step 3 for a seat order: services the passenger needs on the way.
  final Set<TripExtraService> extras;

  /// Step 3 for a parcel order: the size to send.
  final ParcelSize? parcelSize;

  bool get isParcelOrder => transportType == PassengerTransportType.bus;

  /// Step 3 is complete once a parcel order knows its size. A seat order may
  /// legitimately need no extra service at all.
  bool get areExtrasValid => !isParcelOrder || parcelSize != null;

  bool get isRouteValid {
    if (points.length < 2) return false;
    if (points.any((point) => !point.isFilled)) return false;
    return points.first.address.trim().toLowerCase() !=
        points.last.address.trim().toLowerCase();
  }

  bool isScheduleValid({required DateTime now}) {
    final departure = departureAt;
    final arrival = arrivalAt;
    if (departure == null || arrival == null) return false;
    if (!TripDepartureSlots.isAligned(departure)) return false;
    if (!TripDepartureSlots.isAligned(arrival)) return false;
    return departure.isAfter(now) && arrival.isAfter(departure);
  }

  bool get isPassengerCountValid => passengerCount >= 1;

  bool canContinue({required DateTime now}) =>
      isRouteValid && isScheduleValid(now: now) && isPassengerCountValid;

  PassengerOrderDraft copyWith({
    PassengerTransportType? transportType,
    List<TripRoutePoint>? points,
    DateTime? departureAt,
    bool clearDepartureAt = false,
    DateTime? arrivalAt,
    bool clearArrivalAt = false,
    int? passengerCount,
    Set<TripExtraService>? extras,
    ParcelSize? parcelSize,
    bool clearParcelSize = false,
  }) {
    return PassengerOrderDraft(
      transportType: transportType ?? this.transportType,
      points: points ?? this.points,
      departureAt: clearDepartureAt ? null : departureAt ?? this.departureAt,
      arrivalAt: clearArrivalAt ? null : arrivalAt ?? this.arrivalAt,
      passengerCount: passengerCount ?? this.passengerCount,
      extras: extras ?? this.extras,
      parcelSize: clearParcelSize ? null : parcelSize ?? this.parcelSize,
    );
  }
}
