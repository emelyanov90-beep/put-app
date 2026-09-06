import 'package:flutter/foundation.dart';
import 'package:vput/features/trips/domain/passenger_trip.dart';
import 'package:vput/features/trips/domain/trip_extras.dart';

enum PassengerBookingStatus { pendingDriver, awaitingPayment, confirmed }

enum PassengerPaymentStatus { unpaid, paid }

@immutable
class PassengerBookingRequest {
  const PassengerBookingRequest({
    required this.tripId,
    required this.pickupIndex,
    required this.dropoffIndex,
    required this.seatCount,
    required this.selectedExtras,
    required this.amountRubles,
    required this.status,
    required this.paymentStatus,
  });

  final String tripId;
  final int pickupIndex;
  final int dropoffIndex;
  final int seatCount;
  final Set<TripExtraService> selectedExtras;
  final int amountRubles;
  final PassengerBookingStatus status;
  final PassengerPaymentStatus paymentStatus;

  bool get isPaid => paymentStatus == PassengerPaymentStatus.paid;
  bool get awaitsDriver =>
      status == PassengerBookingStatus.pendingDriver && !isPaid;
}

/// A parcel sent on someone else's trip. It reserves no seat, and its price is
/// the platform price of the chosen size rather than the trip fare.
@immutable
class PassengerParcelRequest {
  const PassengerParcelRequest({
    required this.tripId,
    required this.pickupIndex,
    required this.dropoffIndex,
    required this.size,
    required this.comment,
    required this.amountRubles,
    required this.status,
  });

  final String tripId;
  final int pickupIndex;
  final int dropoffIndex;
  final ParcelSize size;
  final String comment;
  final int amountRubles;
  final PassengerBookingStatus status;

  /// `S` / `M` / `L`, the codes the `parcels` collection stores.
  String get sizeCode => switch (size) {
    ParcelSize.small => 'S',
    ParcelSize.medium => 'M',
    ParcelSize.large => 'L',
  };
}
