import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/trips/application/trip_draft_controller.dart';
import 'package:vput/features/trips/domain/passenger_trip.dart';
import 'package:vput/features/trips/domain/trip_draft.dart';
import 'package:vput/features/trips/domain/trip_extras.dart';
import 'package:vput/features/trips/domain/trip_route_point.dart';

ProviderContainer _container() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('TripDraftController route', () {
    test('adds a planned stop before the destination', () {
      final container = _container();
      final controller = container.read(tripDraftProvider.notifier);

      controller
        ..setOrigin(const TripRoutePoint(address: 'Москва'))
        ..setDestination(const TripRoutePoint(address: 'Тверь'))
        ..addStop(const TripRoutePoint(address: 'Клин'));

      final draft = container.read(tripDraftProvider);
      expect(draft.points.map((point) => point.address).toList(), [
        'Москва',
        'Клин',
        'Тверь',
      ]);
      // Three points make six sellable pairs, all of them priced by hand.
      expect(draft.fareLegs.length, 3);
    });

    test('a new stop keeps the fares already set and adds unpriced legs', () {
      final container = _container();
      final controller = container.read(tripDraftProvider.notifier);

      controller
        ..setOrigin(const TripRoutePoint(address: 'Москва'))
        ..setDestination(const TripRoutePoint(address: 'Тверь'))
        ..setFullRoutePrice(1800)
        ..addStop(const TripRoutePoint(address: 'Клин'));

      final draft = container.read(tripDraftProvider);
      // «Москва → Тверь» still costs what the driver named for it.
      expect(draft.fullRoutePrice, 1800);
      expect(draft.fares.priceFor(0, 2), 1800);
      // The legs the new stop introduces start out unpriced.
      expect(draft.fares.priceFor(0, 1), isNull);
      expect(draft.fares.priceFor(1, 2), isNull);
    });

    test('removing a stop drops only the fares that ended at it', () {
      final container = _container();
      final controller = container.read(tripDraftProvider.notifier);

      controller
        ..setOrigin(const TripRoutePoint(address: 'Москва'))
        ..setDestination(const TripRoutePoint(address: 'Тверь'))
        ..addStop(const TripRoutePoint(address: 'Клин'))
        ..addStop(const TripRoutePoint(address: 'Завидово'))
        ..setLegPrice(0, 1, 500)
        ..setLegPrice(1, 2, 600)
        ..setLegPrice(2, 3, 700)
        ..setLegPrice(0, 2, 900)
        ..removeStopAt(1);

      final draft = container.read(tripDraftProvider);
      expect(draft.points.map((point) => point.address).toList(), [
        'Москва',
        'Завидово',
        'Тверь',
      ]);
      // «Москва → Завидово» keeps its own fare, re-addressed to the shorter
      // route, and so does «Завидово → Тверь».
      expect(draft.fares.priceFor(0, 1), 900);
      expect(draft.fares.priceFor(1, 2), 700);
      // The fares that ended at «Клин» went with it: nothing was merged or
      // summed to replace them.
      expect(draft.fares.prices.length, 2);
    });

    test('the origin and the destination cannot be removed', () {
      final container = _container();
      final controller = container.read(tripDraftProvider.notifier);

      controller
        ..setOrigin(const TripRoutePoint(address: 'Москва'))
        ..setDestination(const TripRoutePoint(address: 'Тверь'))
        ..removeStopAt(0)
        ..removeStopAt(1);

      expect(container.read(tripDraftProvider).points.length, 2);
    });
  });

  group('TripDraftController vehicle and seats', () {
    test('selecting a vehicle caps the seat count at its seats', () {
      final container = _container();
      final controller = container.read(tripDraftProvider.notifier);

      controller
        ..setSeatCount(4)
        ..selectVehicle('preview_vehicle_rio');

      final draft = container.read(tripDraftProvider);
      expect(draft.vehicleId, 'preview_vehicle_rio');
      expect(draft.seatCount, 3);
    });

    test('a vehicle that has not passed verification cannot be selected', () {
      final container = _container();

      container
          .read(tripDraftProvider.notifier)
          .selectVehicle('preview_vehicle_solaris');

      expect(container.read(tripDraftProvider).vehicleId, isNull);
      expect(container.read(selectedDriverVehicleProvider), isNull);
    });

    test('the seat count starts at zero and never goes negative', () {
      final container = _container();

      expect(container.read(tripDraftProvider).seatCount, 0);

      container.read(tripDraftProvider.notifier).setSeatCount(-2);

      expect(container.read(tripDraftProvider).seatCount, 0);
    });
  });

  group('TripDraftController schedule', () {
    test('the estimated arrival takes the day from the departure', () {
      final container = _container();
      final controller = container.read(tripDraftProvider.notifier);

      controller
        ..setDepartureAt(DateTime(2026, 5, 15, 9, 30))
        ..setArrivalTimeOfDay(hour: 18, minute: 0);

      expect(
        container.read(tripDraftProvider).arrivalAt,
        DateTime(2026, 5, 15, 18),
      );
    });

    test(
      'an arrival time earlier than the departure rolls to the next day',
      () {
        final container = _container();
        final controller = container.read(tripDraftProvider.notifier);

        controller
          ..setDepartureAt(DateTime(2026, 5, 15, 22, 30))
          ..setArrivalTimeOfDay(hour: 6, minute: 30);

        expect(
          container.read(tripDraftProvider).arrivalAt,
          DateTime(2026, 5, 16, 6, 30),
        );
      },
    );

    test('a later departure pushes the arrival after it', () {
      final container = _container();
      final controller = container.read(tripDraftProvider.notifier);

      controller
        ..setDepartureAt(DateTime(2026, 5, 15, 9))
        ..setArrivalTimeOfDay(hour: 12, minute: 0)
        ..setDepartureAt(DateTime(2026, 5, 15, 14));

      expect(
        container.read(tripDraftProvider).arrivalAt,
        DateTime(2026, 5, 16, 12),
      );
    });

    test('the arrival is ignored until a departure is chosen', () {
      final container = _container();

      container
          .read(tripDraftProvider.notifier)
          .setArrivalTimeOfDay(hour: 12, minute: 0);

      expect(container.read(tripDraftProvider).arrivalAt, isNull);
    });
  });

  group('TripDraftController order type', () {
    test('switches between a car and a bus order', () {
      final container = _container();

      expect(
        container.read(tripDraftProvider).transportType,
        PassengerTransportType.car,
      );

      container
          .read(tripDraftProvider.notifier)
          .setTransportType(PassengerTransportType.bus);

      expect(
        container.read(tripDraftProvider).transportType,
        PassengerTransportType.bus,
      );
    });
  });

  group('TripDraftController extras', () {
    test('turning an extra off drops its price', () {
      final container = _container();
      final controller = container.read(tripDraftProvider.notifier);

      controller
        ..setExtraEnabled(TripExtraService.childSeat, true)
        ..setExtraPrice(TripExtraService.childSeat, 200)
        ..setExtraEnabled(TripExtraService.childSeat, false);

      final extra = container
          .read(tripDraftProvider)
          .extraFor(TripExtraService.childSeat);
      expect(extra.enabled, isFalse);
      expect(extra.price, isNull);
    });

    test('parcel sizes are accepted only once they are priced', () {
      final container = _container();
      final controller = container.read(tripDraftProvider.notifier);

      controller
        ..setParcelEnabled(true)
        ..setParcelSizePrice(ParcelSize.small, 250)
        ..setParcelSizePrice(ParcelSize.large, 700)
        ..setParcelSizePrice(ParcelSize.large, null)
        ..setParcelWithoutPassenger(true);

      final parcel = container.read(tripDraftProvider).parcel;
      expect(parcel.acceptsSize(ParcelSize.small), isTrue);
      expect(parcel.acceptsSize(ParcelSize.medium), isFalse);
      expect(parcel.acceptsSize(ParcelSize.large), isFalse);
      expect(parcel.allowedWithoutPassenger, isTrue);
    });

    test('turning the parcel service off clears its settings', () {
      final container = _container();
      final controller = container.read(tripDraftProvider.notifier);

      controller
        ..setParcelEnabled(true)
        ..setParcelSizePrice(ParcelSize.medium, 400)
        ..setParcelWithoutPassenger(true)
        ..setParcelEnabled(false);

      expect(container.read(tripDraftProvider).parcel, const TripParcelOffer());
    });
  });

  group('TripDraftController booking mode and return trip', () {
    test('booking mode switches to instant booking', () {
      final container = _container();

      container
          .read(tripDraftProvider.notifier)
          .setBookingMode(TripBookingMode.instant);

      expect(
        container.read(tripDraftProvider).bookingMode,
        TripBookingMode.instant,
      );
    });

    test('the return trip reuses the data and asks for a new departure', () {
      final container = _container();
      final controller = container.read(tripDraftProvider.notifier);

      controller
        ..setOrigin(const TripRoutePoint(address: 'Москва'))
        ..setDestination(const TripRoutePoint(address: 'Тверь'))
        ..setFullRoutePrice(1800)
        ..setDepartureAt(DateTime(2026, 5, 15, 9, 30))
        ..selectVehicle('preview_vehicle_largus')
        ..startReturnTrip(sourceTripId: 'trip_1');

      final draft = container.read(tripDraftProvider);
      expect(draft.origin.address, 'Тверь');
      expect(draft.destination.address, 'Москва');
      expect(draft.departureAt, isNull);
      expect(draft.fullRoutePrice, 1800);
      expect(draft.vehicleId, 'preview_vehicle_largus');
      expect(draft.pairedTripId, 'trip_1');
    });

    test('reset returns an empty draft', () {
      final container = _container();
      final controller = container.read(tripDraftProvider.notifier);

      controller
        ..setOrigin(const TripRoutePoint(address: 'Москва'))
        ..setFullRoutePrice(1800)
        ..reset();

      final draft = container.read(tripDraftProvider);
      expect(draft.origin.address, isEmpty);
      expect(draft.fullRoutePrice, isNull);
    });
  });
}
