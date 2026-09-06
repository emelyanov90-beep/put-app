import 'package:flutter/foundation.dart';
import 'package:vput/features/trips/domain/passenger_trip.dart';

enum PassengerOrderStatus { created, seatBooked, parcelBooked, completed }

enum PassengerOrderFilter { all, created, active, completed }

enum PassengerCancellationOutcome { refundRequested, bookingBlocked }

@immutable
class PassengerOrder {
  const PassengerOrder({
    required this.id,
    required this.trip,
    required this.status,
    required this.departureWindowLabel,
    required this.priceRubles,
    this.passengerSeatCount = 0,
    this.passengerSeatsAvailable = 0,
    this.passengerSeatsTotal = 0,
    this.parcelSizes = const [],
    this.parcelSlotsAvailable = 0,
    this.parcelSlotsTotal = 0,
    this.parcelPriceRubles,
    this.segmentPriceRubles,
    this.driverFound = false,
    this.recentCancellations30d = 0,
    this.refundAmountRubles,
  });

  final String id;
  final PassengerTrip trip;
  final PassengerOrderStatus status;
  final String departureWindowLabel;
  final int priceRubles;
  final int passengerSeatCount;
  final int passengerSeatsAvailable;
  final int passengerSeatsTotal;
  final List<String> parcelSizes;
  final int parcelSlotsAvailable;
  final int parcelSlotsTotal;
  final int? parcelPriceRubles;
  final int? segmentPriceRubles;
  final bool driverFound;
  final int recentCancellations30d;
  final int? refundAmountRubles;

  bool get isCompleted => status == PassengerOrderStatus.completed;
  bool get isActive => !isCompleted;
  bool get hasPassengerSeat => passengerSeatCount > 0;
  bool get hasParcel => parcelSizes.isNotEmpty;
  bool get willReachCancellationLimit => recentCancellations30d >= 1;
  int get displayRefundAmountRubles => refundAmountRubles ?? priceRubles;

  String get statusLabel => switch (status) {
    PassengerOrderStatus.created => 'Создан',
    PassengerOrderStatus.seatBooked => 'Место забронировано',
    PassengerOrderStatus.parcelBooked => 'Посылка забронирована',
    PassengerOrderStatus.completed => 'Завершен',
  };
}
