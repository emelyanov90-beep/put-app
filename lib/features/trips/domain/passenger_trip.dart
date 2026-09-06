import 'package:flutter/foundation.dart';
import 'package:vput/features/profile/domain/rating_calculator.dart';
import 'package:vput/features/trips/domain/trip_fare_table.dart';

enum PassengerTransportType { car, bus }

enum TripPriorityBadge { top, nearest }

enum TripExtraService { pets, luggage, childSeat, parcel }

enum TripPassengerRegistrationStatus { waiting, inProgress }

enum PassengerTripBookingMode { standard, instant }

@immutable
class TripStopPreview {
  const TripStopPreview(this.address);

  final String address;
}

@immutable
class TripVehiclePreview {
  const TripVehiclePreview({
    required this.brand,
    required this.model,
    required this.plateNumber,
    required this.photoAsset,
  });

  final String brand;
  final String model;
  final String plateNumber;
  final String photoAsset;
}

@immutable
class PassengerTrip {
  const PassengerTrip({
    required this.id,
    required this.transportType,
    required this.driverName,
    required this.driverRating,
    required this.driverTripsCount,
    required this.distanceKm,
    required this.priorityBadge,
    required this.stops,
    required this.departureLabel,
    required this.detailsDepartureLabel,
    required this.arrivalLabel,
    required this.priceRubles,
    required this.detailsPriceRubles,
    required this.availableSeats,
    required this.totalSeats,
    required this.services,
    required this.vehicle,
    this.passengerRegistrationStatus = TripPassengerRegistrationStatus.waiting,
    this.bookingMode = PassengerTripBookingMode.standard,
    this.driverReviewsCount = 0,
    this.fares = const TripFareTable(),
    this.minimumBoardingPriceRubles,
    this.extraServicePrices = const {},
  });

  final String id;
  final PassengerTransportType transportType;
  final String driverName;
  final double? driverRating;
  final int driverReviewsCount;
  String get driverRatingLabel =>
      RatingCalculator.label(average: driverRating, count: driverReviewsCount);
  final int driverTripsCount;
  final double distanceKm;
  final TripPriorityBadge priorityBadge;
  final List<TripStopPreview> stops;
  final String departureLabel;
  final String detailsDepartureLabel;
  final String arrivalLabel;
  final int priceRubles;
  final int detailsPriceRubles;
  final int availableSeats;
  final int totalSeats;
  final List<TripExtraService> services;
  final TripVehiclePreview vehicle;
  final TripPassengerRegistrationStatus passengerRegistrationStatus;
  final PassengerTripBookingMode bookingMode;

  /// Fares the driver set, one per pair of stops. A pair without a fare is not
  /// sold, so the passenger cannot pick it.
  final TripFareTable fares;

  /// Lowest fare charged for boarding, whatever the chosen pair costs.
  final int? minimumBoardingPriceRubles;

  /// Prices of the extra services this trip offers, from the platform.
  final Map<TripExtraService, int> extraServicePrices;

  /// Fare of the pair, already raised to the boarding price when needed.
  /// Returns `null` when the driver did not price this pair.
  int? fareBetween(int fromIndex, int toIndex) {
    final price = fares.priceFor(fromIndex, toIndex);
    if (price == null) return null;
    final minimum = minimumBoardingPriceRubles;
    return minimum != null && minimum > price ? minimum : price;
  }

  /// Pairs a passenger may actually book: the driver priced them.
  bool isLegSold(int fromIndex, int toIndex) =>
      fares.priceFor(fromIndex, toIndex) != null;

  TripStopPreview get origin => stops.first;
  TripStopPreview get destination => stops.last;
  int get intermediateStopCount => stops.length > 2 ? stops.length - 2 : 0;
  bool get hasAvailableSeats => availableSeats > 0;
  bool get acceptsParcels => services.contains(TripExtraService.parcel);
  bool get isPassengerRegistrationInProgress =>
      passengerRegistrationStatus == TripPassengerRegistrationStatus.inProgress;
}
