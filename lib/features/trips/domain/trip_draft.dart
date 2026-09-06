import 'package:flutter/foundation.dart';
import 'package:vput/features/trips/domain/passenger_trip.dart';
import 'package:vput/features/trips/domain/trip_departure_slots.dart';
import 'package:vput/features/trips/domain/trip_extras.dart';
import 'package:vput/features/trips/domain/trip_fare_table.dart';
import 'package:vput/features/trips/domain/trip_route_point.dart';

/// How a passenger joins the trip (`trips.booking_mode`).
enum TripBookingMode { standard, instant }

/// A part of the wizard that is not filled in correctly yet.
enum TripDraftIssue { route, schedule, seats, pricing, extras, vehicle }

/// Extra services a driver prices per seat, parcels excluded — the parcel
/// service is priced per size and lives in [TripDraft.parcel].
const tripSeatExtraServices = <TripExtraService>[
  TripExtraService.childSeat,
  TripExtraService.pets,
  TripExtraService.luggage,
];

const _emptyExtras = <TripExtraOffer>[
  TripExtraOffer(service: TripExtraService.childSeat),
  TripExtraOffer(service: TripExtraService.pets),
  TripExtraOffer(service: TripExtraService.luggage),
];

const _emptyRoute = <TripRoutePoint>[
  TripRoutePoint(address: ''),
  TripRoutePoint(address: ''),
];

/// Everything the driver fills in while creating a car trip, kept locally until
/// the trip is saved or published.
@immutable
class TripDraft {
  const TripDraft({
    this.transportType = PassengerTransportType.car,
    this.points = _emptyRoute,
    this.departureAt,
    this.arrivalAt,
    this.seatCount = 0,
    this.fares = const TripFareTable(),
    this.minimumBoardingPrice,
    this.extras = _emptyExtras,
    this.parcel = const TripParcelOffer(),
    this.bookingMode = TripBookingMode.standard,
    this.vehicleId,
    this.pairedTripId,
  });

  /// Car or bus trip (`trips.transport_type`).
  final PassengerTransportType transportType;

  /// Route points in travel order: origin first, destination last, planned
  /// stops in between.
  final List<TripRoutePoint> points;
  final DateTime? departureAt;

  /// Estimated arrival, always later than the departure.
  final DateTime? arrivalAt;

  /// Seats offered to passengers. Starts at zero, as in the design.
  final int seatCount;

  /// Fare of every leg the driver priced, including the whole route.
  final TripFareTable fares;

  /// Lowest fare charged for boarding, whatever the legs add up to.
  final int? minimumBoardingPrice;

  final List<TripExtraOffer> extras;
  final TripParcelOffer parcel;
  final TripBookingMode bookingMode;
  final String? vehicleId;

  /// Set on a return trip and points at the trip it was created from.
  final String? pairedTripId;

  TripRoutePoint get origin => points.first;
  TripRoutePoint get destination => points.last;
  List<TripRoutePoint> get intermediateStops =>
      points.sublist(1, points.length - 1);
  int get segmentCount => points.length - 1;

  /// Every pair of points the driver can price on this route.
  List<TripFareLeg> get fareLegs => TripFareTable.legsFor(points.length);

  /// Fare of the whole route — the leg from the first point to the last one.
  /// It is the only fare a trip cannot be published without.
  int? get fullRoutePrice => fares.priceFor(0, points.length - 1);

  TripStopKind kindAt(int index) {
    if (index == 0) return TripStopKind.origin;
    if (index == points.length - 1) return TripStopKind.destination;
    return TripStopKind.intermediate;
  }

  TripExtraOffer extraFor(TripExtraService service) =>
      extras.firstWhere((extra) => extra.service == service);

  /// Fare from point [fromIndex] to point [toIndex].
  ///
  /// The fare is the one the driver entered for exactly this pair, never a sum
  /// of shorter legs: a short leg is priced higher per kilometre on purpose.
  /// The result never drops below the minimum boarding price. Returns `null`
  /// when the driver did not price this pair, and the leg is then not sold.
  int? fareBetween(int fromIndex, int toIndex) {
    if (fromIndex < 0 || toIndex > segmentCount || fromIndex >= toIndex) {
      return null;
    }
    final price = fares.priceFor(fromIndex, toIndex);
    return price == null ? null : _atLeastBoardingPrice(price);
  }

  int _atLeastBoardingPrice(int fare) {
    final minimum = minimumBoardingPrice;
    return minimum != null && minimum > fare ? minimum : fare;
  }

  bool get isRouteValid {
    if (points.length < 2) return false;
    if (points.any((point) => !point.isFilled)) return false;
    return origin.address.trim().toLowerCase() !=
        destination.address.trim().toLowerCase();
  }

  bool isScheduleValid({required DateTime now}) {
    final departure = departureAt;
    final arrival = arrivalAt;
    if (departure == null || arrival == null) return false;
    if (!TripDepartureSlots.isAligned(departure)) return false;
    if (!TripDepartureSlots.isAligned(arrival)) return false;
    if (!arrival.isAfter(departure)) return false;
    return departure.isAfter(now);
  }

  bool get isSeatCountValid => seatCount >= 1;

  /// The fare of the whole route is required; the other legs and the boarding
  /// price are optional, and a leg left empty simply is not sold.
  bool get isPricingValid {
    final full = fullRoutePrice;
    if (full == null || full <= 0) return false;
    if (fares.prices.values.any((price) => price <= 0)) return false;
    if (fares.prices.keys.any((leg) => leg.toIndex >= points.length)) {
      return false;
    }
    final minimum = minimumBoardingPrice;
    return minimum == null || (minimum >= 0 && minimum <= full);
  }

  bool get areExtrasValid =>
      extras.every((extra) => extra.isValid) && parcel.isValid;

  bool get isVehicleSelected => vehicleId != null;

  Set<TripDraftIssue> issues({required DateTime now}) {
    return <TripDraftIssue>{
      if (!isRouteValid) TripDraftIssue.route,
      if (!isScheduleValid(now: now)) TripDraftIssue.schedule,
      if (!isSeatCountValid) TripDraftIssue.seats,
      if (!isPricingValid) TripDraftIssue.pricing,
      if (!areExtrasValid) TripDraftIssue.extras,
      if (!isVehicleSelected) TripDraftIssue.vehicle,
    };
  }

  /// A draft can be stored as `trips.status = draft` as soon as it has a route,
  /// even when the rest is still missing.
  bool get canSave => isRouteValid;

  bool canPublish({required DateTime now}) => issues(now: now).isEmpty;

  /// Copy of this trip running the other way round: the route is reversed, the
  /// leg prices follow it, and the driver supplies a new departure time.
  ///
  /// A leg keeps its fare when it is mirrored, so «A → C» of the outbound trip
  /// becomes «C → A» of the return one at the same price.
  TripDraft reversed({DateTime? departureAt, String? pairedTripId}) {
    final last = points.length - 1;
    return copyWith(
      points: points.reversed.toList(growable: false),
      fares: TripFareTable({
        for (final entry in fares.prices.entries)
          TripFareLeg(last - entry.key.toIndex, last - entry.key.fromIndex):
              entry.value,
      }),
      departureAt: departureAt,
      clearDepartureAt: departureAt == null,
      clearArrivalAt: true,
      pairedTripId: pairedTripId ?? this.pairedTripId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TripDraft &&
        other.transportType == transportType &&
        listEquals(other.points, points) &&
        other.departureAt == departureAt &&
        other.arrivalAt == arrivalAt &&
        other.seatCount == seatCount &&
        other.fares == fares &&
        other.minimumBoardingPrice == minimumBoardingPrice &&
        listEquals(other.extras, extras) &&
        other.parcel == parcel &&
        other.bookingMode == bookingMode &&
        other.vehicleId == vehicleId &&
        other.pairedTripId == pairedTripId;
  }

  @override
  int get hashCode => Object.hash(
    transportType,
    Object.hashAll(points),
    departureAt,
    arrivalAt,
    seatCount,
    fares,
    minimumBoardingPrice,
    Object.hashAll(extras),
    parcel,
    bookingMode,
    vehicleId,
    pairedTripId,
  );

  TripDraft copyWith({
    PassengerTransportType? transportType,
    List<TripRoutePoint>? points,
    DateTime? departureAt,
    bool clearDepartureAt = false,
    DateTime? arrivalAt,
    bool clearArrivalAt = false,
    int? seatCount,
    TripFareTable? fares,
    int? minimumBoardingPrice,
    bool clearMinimumBoardingPrice = false,
    List<TripExtraOffer>? extras,
    TripParcelOffer? parcel,
    TripBookingMode? bookingMode,
    String? vehicleId,
    bool clearVehicleId = false,
    String? pairedTripId,
    bool clearPairedTripId = false,
  }) {
    return TripDraft(
      transportType: transportType ?? this.transportType,
      points: points ?? this.points,
      departureAt: clearDepartureAt ? null : departureAt ?? this.departureAt,
      arrivalAt: clearArrivalAt ? null : arrivalAt ?? this.arrivalAt,
      seatCount: seatCount ?? this.seatCount,
      fares: fares ?? this.fares,
      minimumBoardingPrice: clearMinimumBoardingPrice
          ? null
          : minimumBoardingPrice ?? this.minimumBoardingPrice,
      extras: extras ?? this.extras,
      parcel: parcel ?? this.parcel,
      bookingMode: bookingMode ?? this.bookingMode,
      vehicleId: clearVehicleId ? null : vehicleId ?? this.vehicleId,
      pairedTripId: clearPairedTripId
          ? null
          : pairedTripId ?? this.pairedTripId,
    );
  }
}
