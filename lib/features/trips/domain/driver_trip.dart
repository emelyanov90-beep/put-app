import 'package:flutter/foundation.dart';
import 'package:vput/features/profile/domain/rating_calculator.dart';
import 'package:vput/features/trips/domain/trip_draft.dart';

/// State of a trip in the driver garage (`trips.status`).
enum DriverTripStatus { draft, published, cancelled }

enum DriverTripCancellationOutcome { removed, warningIssued, blocked }

/// Where a booking stands between the request and the paid seat.
enum DriverBookingState { awaitingDriver, awaitingPayment, paid }

@immutable
class DriverTripPassengerBooking {
  const DriverTripPassengerBooking({
    required this.id,
    required this.passengerId,
    required this.passengerName,
    required this.passengerRating,
    this.passengerAvatarAsset,
    this.passengerPhone = '+7 000 000 00 00',
    this.passengerTripsCount = 120,
    this.passengerReviewsCount = 0,
    this.seatCount = 1,
    this.parcelSizes = const <String>[],
    this.confirmed = true,
    this.paid = false,
    this.pickupAddress,
    this.dropoffAddress,
  });

  final String id;
  final String passengerId;
  final String passengerName;
  final double? passengerRating;
  final int passengerReviewsCount;
  String get passengerRatingLabel => RatingCalculator.label(
    average: passengerRating,
    count: passengerReviewsCount,
  );
  final String? passengerAvatarAsset;
  final String passengerPhone;
  final int passengerTripsCount;
  final int seatCount;
  final List<String> parcelSizes;

  /// `false` is a fresh request waiting for driver's approval; `true` already
  /// occupies seats and blocks silent edit/delete of the trip.
  final bool confirmed;

  /// `true` once the passenger paid for the confirmed booking.
  final bool paid;

  /// Where the passenger joins and leaves the trip. `null` means the whole
  /// route, from its first point to its last one.
  final String? pickupAddress;
  final String? dropoffAddress;

  DriverBookingState get state {
    if (!confirmed) return DriverBookingState.awaitingDriver;
    return paid ? DriverBookingState.paid : DriverBookingState.awaitingPayment;
  }

  /// What the driver reads next to the passenger: what is expected of whom.
  String get stateLabel => switch (state) {
    DriverBookingState.awaitingDriver => 'Подтвердите бронь',
    DriverBookingState.awaitingPayment => 'Ожидает оплаты',
    DriverBookingState.paid => 'Оплачено',
  };

  bool get hasSeat => seatCount > 0;
  bool get hasParcel => parcelSizes.isNotEmpty;
  String get shortLabel {
    final parts = <String>[
      if (hasSeat) '$seatCount ${seatCount == 1 ? 'место' : 'места'}',
      if (hasParcel) 'посылка ${parcelSizes.join(', ')}',
    ];
    return parts.isEmpty ? 'Заявка на поездку' : parts.join(' · ');
  }

  DriverTripPassengerBooking copyWith({
    bool? confirmed,
    bool? paid,
    int? seatCount,
    List<String>? parcelSizes,
    String? passengerPhone,
    int? passengerTripsCount,
    String? pickupAddress,
    String? dropoffAddress,
  }) {
    return DriverTripPassengerBooking(
      id: id,
      passengerId: passengerId,
      passengerName: passengerName,
      passengerRating: passengerRating,
      passengerReviewsCount: passengerReviewsCount,
      passengerAvatarAsset: passengerAvatarAsset,
      passengerPhone: passengerPhone ?? this.passengerPhone,
      passengerTripsCount: passengerTripsCount ?? this.passengerTripsCount,
      seatCount: seatCount ?? this.seatCount,
      parcelSizes: parcelSizes ?? this.parcelSizes,
      confirmed: confirmed ?? this.confirmed,
      paid: paid ?? this.paid,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
    );
  }
}

/// A trip the driver saved or published, with the data of the wizard behind it.
@immutable
class DriverTrip {
  const DriverTrip({
    required this.id,
    required this.draft,
    required this.status,
    this.publishedAt,
    this.pairedTripId,
    this.passengerBookings = const <DriverTripPassengerBooking>[],
    this.recentCancellations30d = 0,
  });

  final String id;
  final TripDraft draft;
  final DriverTripStatus status;
  final DateTime? publishedAt;

  /// Set on a return trip and points at the trip it was created from.
  final String? pairedTripId;
  final List<DriverTripPassengerBooking> passengerBookings;

  /// Driver-side cancellations with joined passengers in the rolling 30-day
  /// moderation window. The backend will own this counter later.
  final int recentCancellations30d;

  bool get isPublished => status == DriverTripStatus.published;
  Iterable<DriverTripPassengerBooking> get joinedPassengers =>
      passengerBookings.where((booking) => booking.confirmed);
  Iterable<DriverTripPassengerBooking> get pendingPassengerRequests =>
      passengerBookings.where((booking) => !booking.confirmed);
  int get bookedSeatCount =>
      joinedPassengers.fold(0, (total, booking) => total + booking.seatCount);
  int get freeSeatCount => (draft.seatCount - bookedSeatCount).clamp(0, 999);
  bool get hasJoinedPassengers => bookedSeatCount > 0;
  bool isCompleted(DateTime now) {
    final arrival = draft.arrivalAt;
    return isPublished && arrival != null && !arrival.isAfter(now);
  }

  String statusLabel(DateTime now) {
    if (!isPublished) return 'Черновик';
    return isCompleted(now) ? 'Завершенная' : 'Активная';
  }

  String get routeLabel =>
      '${draft.origin.address} → ${draft.destination.address}';

  DriverTrip copyWith({
    TripDraft? draft,
    DriverTripStatus? status,
    DateTime? publishedAt,
    String? pairedTripId,
    List<DriverTripPassengerBooking>? passengerBookings,
    int? recentCancellations30d,
  }) {
    return DriverTrip(
      id: id,
      draft: draft ?? this.draft,
      status: status ?? this.status,
      publishedAt: publishedAt ?? this.publishedAt,
      pairedTripId: pairedTripId ?? this.pairedTripId,
      passengerBookings: passengerBookings ?? this.passengerBookings,
      recentCancellations30d:
          recentCancellations30d ?? this.recentCancellations30d,
    );
  }
}
