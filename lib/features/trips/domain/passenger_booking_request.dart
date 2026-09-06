import 'package:flutter/foundation.dart';
import 'package:vput/features/trips/domain/passenger_trip.dart';

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
