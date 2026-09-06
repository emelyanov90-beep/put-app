import 'package:flutter/foundation.dart';
import 'package:vput/features/trips/domain/passenger_trip.dart';
import 'package:vput/features/trips/domain/trip_departure_slots.dart';
import 'package:vput/features/trips/domain/trip_extras.dart';
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
    this.fullRoutePrice,
    this.segmentPrices = const <int?>[null],
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

  /// Fare for the whole route, from the first point to the last one.
  final int? fullRoutePrice;

  /// Fare of every leg between two neighbouring points. Length always equals
  /// `points.length - 1`.
  final List<int?> segmentPrices;

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

  TripStopKind kindAt(int index) {
    if (index == 0) return TripStopKind.origin;
    if (index == points.length - 1) return TripStopKind.destination;
    return TripStopKind.intermediate;
  }

  TripExtraOffer extraFor(TripExtraService service) =>
      extras.firstWhere((extra) => extra.service == service);

  /// Fare from point [fromIndex] to point [toIndex].
  ///
  /// Legs on the way are summed up and the result never drops below the
  /// minimum boarding price. Returns `null` while a leg on the way is unpriced.
  int? fareBetween(int fromIndex, int toIndex) {
    if (fromIndex < 0 || toIndex > segmentCount || fromIndex >= toIndex) {
      return null;
    }
    if (fromIndex == 0 && toIndex == segmentCount && fullRoutePrice != null) {
      return _atLeastBoardingPrice(fullRoutePrice!);
    }

    var total = 0;
    for (var index = fromIndex; index < toIndex; index++) {
      final price = segmentPrices[index];
      if (price == null) return null;
      total += price;
    }
    return _atLeastBoardingPrice(total);
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

  /// The fare of the whole route is required; leg fares and the boarding
  /// price are optional, and a leg left empty simply is not sold separately.
  bool get isPricingValid {
    final full = fullRoutePrice;
    if (full == null || full <= 0) return false;
    if (segmentPrices.length != segmentCount) return false;
    if (segmentPrices.any((price) => price != null && price <= 0)) return false;
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
  TripDraft reversed({DateTime? departureAt, String? pairedTripId}) {
    return copyWith(
      points: points.reversed.toList(growable: false),
      segmentPrices: segmentPrices.reversed.toList(growable: false),
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
        other.fullRoutePrice == fullRoutePrice &&
        listEquals(other.segmentPrices, segmentPrices) &&
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
    fullRoutePrice,
    Object.hashAll(segmentPrices),
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
    int? fullRoutePrice,
    bool clearFullRoutePrice = false,
    List<int?>? segmentPrices,
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
      fullRoutePrice: clearFullRoutePrice
          ? null
          : fullRoutePrice ?? this.fullRoutePrice,
      segmentPrices: segmentPrices ?? this.segmentPrices,
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
