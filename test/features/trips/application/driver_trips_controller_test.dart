import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/trips/application/driver_trips_controller.dart';
import 'package:vput/features/trips/data/preview_trip_publication_settings.dart';
import 'package:vput/features/trips/domain/driver_trip.dart';
import 'package:vput/features/trips/domain/trip_draft.dart';
import 'package:vput/features/trips/domain/trip_route_point.dart';

TripDraft _draft({String origin = 'Москва', String destination = 'Тверь'}) {
  return TripDraft(
    points: [
      TripRoutePoint(address: origin),
      TripRoutePoint(address: destination),
    ],
    departureAt: DateTime(2026, 5, 16, 9, 30),
    arrivalAt: DateTime(2026, 5, 16, 18),
    seatCount: 3,
    fullRoutePrice: 1800,
    vehicleId: 'preview_vehicle_largus',
  );
}

ProviderContainer _container() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('DriverTripsController', () {
    test(
      'preview approval rechecks the last seat and ignores duplicate requests',
      () {
        final container = _container();
        final controller = container.read(driverTripsProvider.notifier);
        final id = controller.publish(_draft().copyWith(seatCount: 1));
        const first = DriverTripPassengerBooking(
          id: 'one',
          passengerId: 'p1',
          passengerName: 'Первый',
          passengerRating: null,
          confirmed: false,
        );
        const second = DriverTripPassengerBooking(
          id: 'two',
          passengerId: 'p2',
          passengerName: 'Второй',
          passengerRating: null,
          confirmed: false,
        );
        controller.addPassengerBooking(id, first);
        controller.addPassengerBooking(id, first);
        controller.addPassengerBooking(id, second);
        expect(controller.findById(id)!.passengerBookings, hasLength(2));
        expect(
          controller.setPassengerBookingConfirmed(
            tripId: id,
            bookingId: 'one',
            confirmed: true,
          ),
          isTrue,
        );
        expect(
          controller.setPassengerBookingConfirmed(
            tripId: id,
            bookingId: 'two',
            confirmed: true,
          ),
          isFalse,
        );
        expect(controller.findById(id)!.bookedSeatCount, 1);
      },
    );

    test('saves a draft and keeps it out of the published list', () {
      final container = _container();

      final id = container
          .read(driverTripsProvider.notifier)
          .saveDraft(_draft());

      final trips = container.read(driverTripsByStatusProvider);
      expect(trips.drafts.single.id, id);
      expect(trips.drafts.single.status, DriverTripStatus.draft);
      expect(trips.published, isEmpty);
    });

    test(
      'saving with an existing id updates that trip instead of adding one',
      () {
        final container = _container();
        final controller = container.read(driverTripsProvider.notifier);

        final id = controller.saveDraft(_draft());
        controller.saveDraft(_draft(destination: 'Могилев'), id: id);

        final trips = container.read(driverTripsProvider);
        expect(trips, hasLength(1));
        expect(trips.single.draft.destination.address, 'Могилев');
      },
    );

    test('publishing a draft keeps the same record and stamps the time', () {
      final container = _container();
      final controller = container.read(driverTripsProvider.notifier);

      final id = controller.saveDraft(_draft());
      controller.publish(_draft(), id: id, now: DateTime(2026, 5, 15, 10));

      final trips = container.read(driverTripsByStatusProvider);
      expect(trips.drafts, isEmpty);
      expect(trips.published.single.id, id);
      expect(trips.published.single.publishedAt, DateTime(2026, 5, 15, 10));
    });

    test('a return trip points at the trip it was created from', () {
      final container = _container();
      final controller = container.read(driverTripsProvider.notifier);

      final sourceId = controller.publish(_draft());
      controller.publish(
        _draft(origin: 'Тверь', destination: 'Москва'),
        pairedTripId: sourceId,
      );

      final published = container.read(driverTripsByStatusProvider).published;
      expect(published, hasLength(2));
      expect(published.first.pairedTripId, sourceId);
    });

    test('removing a trip drops it from the list', () {
      final container = _container();
      final controller = container.read(driverTripsProvider.notifier);

      final id = controller.saveDraft(_draft());
      controller.remove(id);

      expect(container.read(driverTripsProvider), isEmpty);
    });

    test(
      'confirmed passenger bookings occupy seats and block silent edits',
      () {
        final container = _container();
        final controller = container.read(driverTripsProvider.notifier);

        final id = controller.publish(_draft());
        controller.addPassengerBooking(
          id,
          const DriverTripPassengerBooking(
            id: 'booking_1',
            passengerId: 'passenger_1',
            passengerName: 'Анна Смирнова',
            passengerRating: 4.8,
            seatCount: 2,
          ),
        );

        final trip = controller.findById(id)!;
        expect(trip.hasJoinedPassengers, isTrue);
        expect(trip.bookedSeatCount, 2);
        expect(trip.freeSeatCount, 1);

        controller.setSeatCapacity(id, 1);
        expect(controller.findById(id)!.draft.seatCount, 2);
      },
    );

    test('closing passenger reception leaves no free seats', () {
      final container = _container();
      final controller = container.read(driverTripsProvider.notifier);

      final id = controller.publish(_draft().copyWith(seatCount: 4));
      controller.addPassengerBooking(
        id,
        const DriverTripPassengerBooking(
          id: 'booking_1',
          passengerId: 'passenger_1',
          passengerName: 'Анна Смирнова',
          passengerRating: 4.8,
          seatCount: 2,
        ),
      );

      controller.closePassengerRegistration(id);

      final trip = controller.findById(id)!;
      expect(trip.bookedSeatCount, 2);
      expect(trip.draft.seatCount, 2);
      expect(trip.freeSeatCount, 0);
    });

    test(
      'cancellation outcome depends on joined passengers and recent limit',
      () {
        final container = _container();
        final controller = container.read(driverTripsProvider.notifier);

        final emptyId = controller.publish(_draft());
        expect(
          controller.cancel(emptyId),
          DriverTripCancellationOutcome.removed,
        );

        final warnedId = controller.publish(_draft());
        controller.addPassengerBooking(
          warnedId,
          const DriverTripPassengerBooking(
            id: 'booking_1',
            passengerId: 'passenger_1',
            passengerName: 'Анна Смирнова',
            passengerRating: 4.8,
          ),
        );
        expect(
          controller.cancel(warnedId),
          DriverTripCancellationOutcome.warningIssued,
        );

        final blockedId = controller.publish(_draft());
        controller
          ..setRecentCancellations30d(blockedId, 1)
          ..addPassengerBooking(
            blockedId,
            const DriverTripPassengerBooking(
              id: 'booking_2',
              passengerId: 'passenger_2',
              passengerName: 'Иван Петров',
              passengerRating: 4.6,
            ),
          );
        expect(
          controller.cancel(blockedId),
          DriverTripCancellationOutcome.blocked,
        );
      },
    );
  });

  group('driverPublicationUsage', () {
    final now = DateTime(2026, 5, 15, 12);

    test('counts only published trips, by day and by rolling week', () {
      final container = _container();
      final controller = container.read(driverTripsProvider.notifier);
      controller
        ..saveDraft(_draft())
        ..publish(_draft(), now: DateTime(2026, 5, 15, 8))
        ..publish(_draft(), now: DateTime(2026, 5, 13, 8))
        ..publish(_draft(), now: DateTime(2026, 5, 1, 8));

      final usage = driverPublicationUsage(
        container.read(driverTripsProvider),
        now: now,
      );

      expect(usage.publishedToday, 1);
      expect(usage.publishedThisWeek, 2);
    });

    test('counts the two directions of today apart', () {
      final container = _container();
      final controller = container.read(driverTripsProvider.notifier);
      final sourceId = controller.publish(_draft(), now: now);
      controller.publish(
        _draft(origin: 'Тверь', destination: 'Москва'),
        pairedTripId: sourceId,
        now: now,
      );

      final usage = driverPublicationUsage(
        container.read(driverTripsProvider),
        now: now,
      );

      expect(usage.publishedToday, 2);
      expect(usage.publishedOutboundToday, 1);
      expect(usage.publishedReturnToday, 1);
    });

    test('the provider blocks a third publication on the same day', () {
      final container = _container();
      final controller = container.read(driverTripsProvider.notifier);
      final limits = container.read(tripPublicationLimitsProvider);

      expect(
        container.read(tripPublicationUsageProvider).blockFor(limits),
        isNull,
      );

      controller
        ..publish(_draft())
        ..publish(_draft());

      expect(
        container.read(tripPublicationUsageProvider).blockFor(limits),
        isNotNull,
      );
    });
  });

  group('Booking requests', () {
    const request = DriverTripPassengerBooking(
      id: 'booking_1',
      passengerId: 'passenger_1',
      passengerName: 'Анастасия К.',
      passengerRating: 4.8,
      confirmed: false,
    );

    test('a pending request waits for the driver and holds no seat', () {
      final container = _container();
      final controller = container.read(driverTripsProvider.notifier);
      final tripId = controller.publish(_draft());

      controller.addPassengerBooking(tripId, request);

      final trip = container.read(driverTripsProvider).single;
      expect(trip.pendingPassengerRequests, hasLength(1));
      expect(trip.bookedSeatCount, 0);
      expect(
        container.read(pendingBookingRequestProvider)?.booking.id,
        'booking_1',
      );
    });

    test('confirming a request seats the passenger', () {
      final container = _container();
      final controller = container.read(driverTripsProvider.notifier);
      final tripId = controller.publish(_draft());
      controller.addPassengerBooking(tripId, request);

      controller.setPassengerBookingConfirmed(
        tripId: tripId,
        bookingId: 'booking_1',
        confirmed: true,
      );

      final trip = container.read(driverTripsProvider).single;
      expect(trip.bookedSeatCount, 1);
      expect(container.read(pendingBookingRequestProvider), isNull);
    });

    test('turning a request down drops it', () {
      final container = _container();
      final controller = container.read(driverTripsProvider.notifier);
      final tripId = controller.publish(_draft());
      controller.addPassengerBooking(tripId, request);

      controller.rejectPassengerBooking(tripId: tripId, bookingId: 'booking_1');

      expect(
        container.read(driverTripsProvider).single.passengerBookings,
        isEmpty,
      );
      expect(container.read(pendingBookingRequestProvider), isNull);
    });

    test('a draft trip takes no requests at all', () {
      final container = _container();
      final controller = container.read(driverTripsProvider.notifier);
      final tripId = controller.saveDraft(_draft());

      controller.addPassengerBooking(tripId, request);

      expect(
        container.read(driverTripsProvider).single.passengerBookings,
        isEmpty,
      );
    });
  });
}
