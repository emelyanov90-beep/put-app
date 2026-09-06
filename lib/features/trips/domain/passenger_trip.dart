import 'package:flutter/foundation.dart';
import 'package:vput/features/profile/domain/rating_calculator.dart';

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

  TripStopPreview get origin => stops.first;
  TripStopPreview get destination => stops.last;
  int get intermediateStopCount => stops.length > 2 ? stops.length - 2 : 0;
  bool get hasAvailableSeats => availableSeats > 0;
  bool get acceptsParcels => services.contains(TripExtraService.parcel);
  bool get isPassengerRegistrationInProgress =>
      passengerRegistrationStatus == TripPassengerRegistrationStatus.inProgress;
}
