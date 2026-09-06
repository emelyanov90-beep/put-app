import 'package:flutter/foundation.dart';
import 'package:vput/features/trips/domain/trip_departure_slots.dart';
import 'package:vput/features/trips/domain/trip_route_point.dart';

const _initialOrderRoute = <TripRoutePoint>[
  TripRoutePoint(address: 'Победителей 1, Минск'),
  TripRoutePoint(address: 'Комсомонавтов 13, Минск'),
  TripRoutePoint(address: 'Рынок местный, Могилев'),
];

@immutable
class PassengerOrderDraft {
  const PassengerOrderDraft({
    this.points = _initialOrderRoute,
    this.departureAt,
    this.arrivalAt,
    this.passengerCount = 1,
  });

  final List<TripRoutePoint> points;
  final DateTime? departureAt;
  final DateTime? arrivalAt;
  final int passengerCount;

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
    List<TripRoutePoint>? points,
    DateTime? departureAt,
    bool clearDepartureAt = false,
    DateTime? arrivalAt,
    bool clearArrivalAt = false,
    int? passengerCount,
  }) {
    return PassengerOrderDraft(
      points: points ?? this.points,
      departureAt: clearDepartureAt ? null : departureAt ?? this.departureAt,
      arrivalAt: clearArrivalAt ? null : arrivalAt ?? this.arrivalAt,
      passengerCount: passengerCount ?? this.passengerCount,
    );
  }
}
