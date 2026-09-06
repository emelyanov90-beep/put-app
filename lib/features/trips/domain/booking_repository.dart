import 'package:vput/features/trips/domain/passenger_booking_request.dart';

class BookingActionResult {
  const BookingActionResult({
    required this.id,
    required this.tripId,
    required this.status,
    required this.paymentStatus,
  });
  final String id;
  final String tripId;
  final PassengerBookingStatus status;
  final PassengerPaymentStatus paymentStatus;
  bool get isPaid =>
      status == PassengerBookingStatus.confirmed &&
      paymentStatus == PassengerPaymentStatus.paid;
}

abstract interface class BookingRepository {
  Future<BookingActionResult> create(PassengerBookingRequest request);
  Future<BookingActionResult> createParcel(PassengerParcelRequest request);
  Future<BookingActionResult> pay(String bookingId);
  Future<BookingCancellationResult> cancel(String bookingId);
}

class BookingFailure implements Exception {
  const BookingFailure(this.message);
  final String message;
}

class BookingCancellationResult {
  const BookingCancellationResult({
    required this.bookingBlocked,
    required this.refundRequested,
    required this.refundAmountRubles,
  });
  final bool bookingBlocked;
  final bool refundRequested;
  final int refundAmountRubles;
}
