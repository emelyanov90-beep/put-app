import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/core/api/pocketbase_provider.dart';
import 'package:vput/core/config/app_config.dart';
import 'package:vput/features/trips/data/pocketbase_driver_trip_repository.dart';
import 'package:vput/features/trips/application/trip_draft_controller.dart';
import 'package:vput/features/trips/domain/driver_trip.dart';
import 'package:vput/features/trips/domain/driver_trip_repository.dart';
import 'package:vput/features/trips/domain/trip_draft.dart';
import 'package:vput/features/trips/domain/trip_publication_limits.dart';

/// Trips the driver saved or published.
///
/// Uses PocketBase in configured builds and keeps an in-memory repository for
/// the offline demo and widget tests. Publication changes the existing record's
/// state and never creates a second copy.
class DriverTripsController extends Notifier<List<DriverTrip>> {
  var _nextId = 1;

  @override
  List<DriverTrip> build() {
    if (AppConfig.hasPocketBaseUrl) {
      unawaited(Future<void>.microtask(_load));
    }
    return const [];
  }

  DriverTripRepository? get _repository => AppConfig.hasPocketBaseUrl
      ? PocketBaseDriverTripRepository(ref.read(pocketBaseProvider))
      : null;

  Future<void> _load() async {
    final trips = await _repository!.list();
    if (ref.mounted) state = trips;
  }

  Future<void> reload() => _repository == null ? Future.value() : _load();

  DriverTrip? findById(String id) {
    for (final trip in state) {
      if (trip.id == id) return trip;
    }
    return null;
  }

  /// Stores [draft] as a draft trip and returns its id. Passing the id of an
  /// existing trip updates that trip instead of creating a second one.
  String saveDraft(TripDraft draft, {String? id, String? pairedTripId}) {
    return _upsert(
      draft,
      id: id,
      status: DriverTripStatus.draft,
      pairedTripId: pairedTripId,
    );
  }

  Future<String> saveDraftPersisted(
    TripDraft draft, {
    String? id,
    String? pairedTripId,
  }) async {
    final repository = _repository;
    if (repository == null) {
      return saveDraft(draft, id: id, pairedTripId: pairedTripId);
    }
    final saved = await repository.save(
      draft.copyWith(pairedTripId: pairedTripId ?? draft.pairedTripId),
      id: id,
    );
    _replaceOrAdd(saved);
    return saved.id;
  }

  /// Publishes [draft] and returns the id of the published trip.
  String publish(
    TripDraft draft, {
    String? id,
    String? pairedTripId,
    DateTime? now,
  }) {
    return _upsert(
      draft,
      id: id,
      status: DriverTripStatus.published,
      pairedTripId: pairedTripId,
      publishedAt: now ?? DateTime.now(),
    );
  }

  Future<String> publishPersisted(
    TripDraft draft, {
    String? id,
    String? pairedTripId,
  }) async {
    final repository = _repository;
    if (repository == null) {
      return publish(draft, id: id, pairedTripId: pairedTripId);
    }
    final saved = await repository.save(
      draft.copyWith(pairedTripId: pairedTripId ?? draft.pairedTripId),
      id: id,
    );
    final published = await repository.publish(saved.id);
    _replaceOrAdd(published);
    return published.id;
  }

  Future<String> publishReturnPersisted(TripDraft draft) async {
    final sourceId = draft.pairedTripId;
    final repository = _repository;
    if (repository == null || sourceId == null) {
      return publishPersisted(draft, pairedTripId: sourceId);
    }
    final published = await repository.createReturn(sourceId, draft);
    _replaceOrAdd(published);
    return published.id;
  }

  /// Saves edits to a stored trip, keeping its state: a published trip stays
  /// published, a draft stays a draft.
  void updateTrip(String id, TripDraft draft) {
    final existing = findById(id);
    if (existing == null) return;
    final updated = existing.copyWith(draft: draft);
    state = [
      for (final trip in state)
        if (trip.id == id) updated else trip,
    ];
  }

  Future<void> updateTripPersisted(String id, TripDraft draft) async {
    final repository = _repository;
    if (repository == null) {
      updateTrip(id, draft);
      return;
    }
    _replaceOrAdd(await repository.save(draft, id: id));
  }

  void remove(String id) {
    state = [
      for (final trip in state)
        if (trip.id != id) trip,
    ];
  }

  void addPassengerBooking(String tripId, DriverTripPassengerBooking booking) {
    final trip = findById(tripId);
    if (trip == null || !trip.isPublished) return;
    if (trip.passengerBookings.any((item) => item.id == booking.id) ||
        booking.seatCount < 0 ||
        (booking.confirmed && booking.seatCount > trip.freeSeatCount)) {
      return;
    }
    final updated = trip.copyWith(
      passengerBookings: [...trip.passengerBookings, booking],
    );
    _replace(updated);
  }

  bool setPassengerBookingConfirmed({
    required String tripId,
    required String bookingId,
    required bool confirmed,
  }) {
    final trip = findById(tripId);
    if (trip == null || !trip.isPublished) return false;
    final requested = trip.passengerBookings
        .where((booking) => booking.id == bookingId)
        .firstOrNull;
    if (requested == null || (requested.paid && !confirmed)) return false;
    if (requested.confirmed == confirmed) return true;
    if (confirmed && requested.seatCount > trip.freeSeatCount) return false;
    final updatedBookings = [
      for (final booking in trip.passengerBookings)
        if (booking.id == bookingId)
          booking.copyWith(confirmed: confirmed)
        else
          booking,
    ];
    _replace(trip.copyWith(passengerBookings: updatedBookings));
    return true;
  }

  Future<bool> approvePassengerBookingPersisted({
    required String tripId,
    required String bookingId,
  }) async {
    final repository = _repository;
    if (repository == null) {
      return setPassengerBookingConfirmed(
        tripId: tripId,
        bookingId: bookingId,
        confirmed: true,
      );
    }
    await repository.approveBooking(bookingId);
    await _load();
    return true;
  }

  /// Marks a confirmed booking as paid — what the payment action reports back
  /// from the passenger side.
  void setPassengerBookingPaid({
    required String tripId,
    required String bookingId,
  }) {
    final trip = findById(tripId);
    if (trip == null) return;
    _replace(
      trip.copyWith(
        passengerBookings: [
          for (final booking in trip.passengerBookings)
            if (booking.id == bookingId && booking.confirmed)
              booking.copyWith(paid: true)
            else
              booking,
        ],
      ),
    );
  }

  /// Turns down a request: it disappears from the trip and frees nothing,
  /// because a pending request never held a seat.
  void rejectPassengerBooking({
    required String tripId,
    required String bookingId,
  }) {
    final trip = findById(tripId);
    if (trip == null) return;
    _replace(
      trip.copyWith(
        passengerBookings: [
          for (final booking in trip.passengerBookings)
            if (booking.id != bookingId) booking,
        ],
      ),
    );
  }

  Future<void> rejectPassengerBookingPersisted({
    required String tripId,
    required String bookingId,
  }) async {
    final repository = _repository;
    if (repository == null) {
      rejectPassengerBooking(tripId: tripId, bookingId: bookingId);
      return;
    }
    await repository.rejectBooking(bookingId);
    await _load();
  }

  /// Changes the seat capacity the driver keeps available for this trip.
  /// Already confirmed passenger seats cannot be cut away.
  void setSeatCapacity(String id, int value, {int maxValue = 999}) {
    final trip = findById(id);
    if (trip == null) return;
    final minimum = trip.bookedSeatCount;
    final maximum = minimum > maxValue ? minimum : maxValue;
    _replace(
      trip.copyWith(
        draft: trip.draft.copyWith(seatCount: value.clamp(minimum, maximum)),
      ),
    );
  }

  Future<void> setSeatCapacityPersisted(
    String id,
    int value, {
    int maxValue = 999,
  }) async {
    final trip = findById(id);
    if (trip == null) return;
    final minimum = trip.bookedSeatCount;
    final maximum = minimum > maxValue ? minimum : maxValue;
    final draft = trip.draft.copyWith(seatCount: value.clamp(minimum, maximum));
    final repository = _repository;
    if (repository == null) {
      setSeatCapacity(id, value, maxValue: maxValue);
      return;
    }
    _replaceOrAdd(await repository.save(draft, id: id));
  }

  void closePassengerRegistration(String id) {
    final trip = findById(id);
    if (trip == null) return;
    setSeatCapacity(id, trip.bookedSeatCount, maxValue: trip.draft.seatCount);
  }

  Future<void> closePassengerRegistrationPersisted(String id) async {
    final trip = findById(id);
    if (trip == null) return;
    final repository = _repository;
    if (repository == null) {
      closePassengerRegistration(id);
      return;
    }
    _replaceOrAdd(
      await repository.save(trip.draft, id: id, acceptingBookings: false),
    );
  }

  void setRecentCancellations30d(String id, int value) {
    final trip = findById(id);
    if (trip == null) return;
    _replace(trip.copyWith(recentCancellations30d: value.clamp(0, 2)));
  }

  /// Cancels/removes a trip. A trip without joined passengers can disappear
  /// silently. Once passengers joined, cancellation is counted against the
  /// 30-day moderation window; the second such cancellation blocks the driver.
  DriverTripCancellationOutcome cancel(String id) {
    final trip = findById(id);
    if (trip == null) return DriverTripCancellationOutcome.removed;
    remove(id);
    if (!trip.hasJoinedPassengers) return DriverTripCancellationOutcome.removed;
    return trip.recentCancellations30d >= 1
        ? DriverTripCancellationOutcome.blocked
        : DriverTripCancellationOutcome.warningIssued;
  }

  Future<DriverTripCancellationOutcome> cancelPersisted(String id) async {
    final trip = findById(id);
    final repository = _repository;
    if (repository == null) return cancel(id);
    await repository.cancel(id);
    if (ref.mounted) remove(id);
    if (trip == null || !trip.hasJoinedPassengers) {
      return DriverTripCancellationOutcome.removed;
    }
    return trip.recentCancellations30d >= 1
        ? DriverTripCancellationOutcome.blocked
        : DriverTripCancellationOutcome.warningIssued;
  }

  String _upsert(
    TripDraft draft, {
    required DriverTripStatus status,
    String? id,
    String? pairedTripId,
    DateTime? publishedAt,
  }) {
    final existing = id == null ? null : findById(id);
    if (existing == null) {
      final trip = DriverTrip(
        id: id ?? 'driver_trip_${_nextId++}',
        draft: draft,
        status: status,
        publishedAt: publishedAt,
        pairedTripId: pairedTripId ?? draft.pairedTripId,
      );
      state = [...state, trip];
      return trip.id;
    }

    final updated = existing.copyWith(
      draft: draft,
      status: status,
      publishedAt: publishedAt,
      pairedTripId: pairedTripId,
    );
    state = [
      for (final trip in state)
        if (trip.id == updated.id) updated else trip,
    ];
    return updated.id;
  }

  void _replace(DriverTrip updated) {
    state = [
      for (final trip in state)
        if (trip.id == updated.id) updated else trip,
    ];
  }

  void _replaceOrAdd(DriverTrip updated) {
    if (state.any((trip) => trip.id == updated.id)) {
      _replace(updated);
    } else {
      state = [...state, updated];
    }
  }
}

final driverTripsProvider =
    NotifierProvider<DriverTripsController, List<DriverTrip>>(
      DriverTripsController.new,
    );

/// Id of the saved trip the wizard is currently editing; `null` while a new
/// trip is being composed.
class EditedDriverTripController extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? id) => state = id;

  void clear() => state = null;
}

final editedDriverTripProvider =
    NotifierProvider<EditedDriverTripController, String?>(
      EditedDriverTripController.new,
    );

/// Drafts first, then published trips, newest publication on top.
final driverTripsByStatusProvider =
    Provider<({List<DriverTrip> drafts, List<DriverTrip> published})>((ref) {
      final trips = ref.watch(driverTripsProvider);
      return (
        drafts: [
          for (final trip in trips)
            if (!trip.isPublished) trip,
        ],
        published: [
          for (final trip in trips.reversed)
            if (trip.isPublished) trip,
        ],
      );
    });

/// How many trips the driver published today and over the last seven days.
///
/// The backend owns these counters in the end; the week is a rolling
/// seven-day window until the server defines its own.
TripPublicationUsage driverPublicationUsage(
  List<DriverTrip> trips, {
  required DateTime now,
}) {
  final dayStart = DateTime(now.year, now.month, now.day);
  final weekStart = now.subtract(const Duration(days: 7));
  var today = 0;
  var week = 0;
  var outbound = 0;
  var back = 0;
  for (final trip in trips) {
    final publishedAt = trip.publishedAt;
    if (publishedAt == null) continue;
    if (!publishedAt.isBefore(dayStart)) {
      today++;
      // A trip created from another one is the return leg of that pair.
      if (trip.pairedTripId == null) {
        outbound++;
      } else {
        back++;
      }
    }
    if (publishedAt.isAfter(weekStart)) week++;
  }
  return TripPublicationUsage(
    publishedToday: today,
    publishedThisWeek: week,
    publishedOutboundToday: outbound,
    publishedReturnToday: back,
  );
}

/// Whether the trip being edited differs from what is stored — the «Сохранить»
/// action only appears once something has actually changed.
final tripDraftHasChangesProvider = Provider<bool>((ref) {
  final editedId = ref.watch(editedDriverTripProvider);
  if (editedId == null) return false;
  final saved = ref
      .watch(driverTripsProvider)
      .where((trip) => trip.id == editedId)
      .firstOrNull;
  if (saved == null) return false;
  return saved.draft != ref.watch(tripDraftProvider);
});

/// One request waiting for the driver's decision, with the trip behind it.
@immutable
class PendingBookingRequest {
  const PendingBookingRequest({required this.trip, required this.booking});

  final DriverTrip trip;
  final DriverTripPassengerBooking booking;
}

/// The oldest request the driver has not decided on yet, across every
/// published trip; `null` while there is nothing to decide.
final pendingBookingRequestProvider = Provider<PendingBookingRequest?>((ref) {
  for (final trip in ref.watch(driverTripsProvider)) {
    if (!trip.isPublished) continue;
    for (final booking in trip.pendingPassengerRequests) {
      return PendingBookingRequest(trip: trip, booking: booking);
    }
  }
  return null;
});

/// Requests the driver has already been shown the «Новый отклик» notice for,
/// so it does not pop up again on every visit.
class SeenBookingRequestsController extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void markSeen(String bookingId) => state = {...state, bookingId};
}

final seenBookingRequestsProvider =
    NotifierProvider<SeenBookingRequestsController, Set<String>>(
      SeenBookingRequestsController.new,
    );

/// The first paid booking the driver has not been told about yet.
final paidBookingNoticeProvider = Provider<PendingBookingRequest?>((ref) {
  for (final trip in ref.watch(driverTripsProvider)) {
    if (!trip.isPublished) continue;
    for (final booking in trip.passengerBookings) {
      if (booking.state == DriverBookingState.paid) {
        return PendingBookingRequest(trip: trip, booking: booking);
      }
    }
  }
  return null;
});
