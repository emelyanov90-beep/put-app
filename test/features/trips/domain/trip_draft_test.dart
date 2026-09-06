import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/trips/domain/passenger_trip.dart';
import 'package:vput/features/trips/domain/trip_draft.dart';
import 'package:vput/features/trips/domain/trip_extras.dart';
import 'package:vput/features/trips/domain/trip_route_point.dart';

import '../../../support/trip_fares.dart';

TripDraft _filledDraft({DateTime? departureAt}) {
  return TripDraft(
    points: const [
      TripRoutePoint(address: 'Улица Солнечная, дом 1', cityName: 'Москва'),
      TripRoutePoint(address: 'Улица Ленина, дом 5', cityName: 'Тверь'),
      TripRoutePoint(address: 'Улица Лунная, дом 2', cityName: 'Тверь'),
    ],
    departureAt: departureAt ?? DateTime(2026, 5, 15, 9, 30),
    arrivalAt: DateTime(2026, 5, 15, 18),
    seatCount: 3,
    fares: fares({
      [0, 2]: 1800,
      [0, 1]: 700,
      [1, 2]: 800,
    }),
    minimumBoardingPrice: 300,
    vehicleId: 'preview_vehicle_largus',
  );
}

void main() {
  group('TripDraft fares', () {
    test('the full route uses the price the driver set for it', () {
      expect(_filledDraft().fareBetween(0, 2), 1800);
    });

    test('a leg costs what the driver set for that exact pair', () {
      // A short leg is dearer per kilometre, so «A → C» is deliberately less
      // than «A → B» plus «B → C» and must never be their sum.
      final draft = _filledDraft().copyWith(
        points: const [
          TripRoutePoint(address: 'A'),
          TripRoutePoint(address: 'B'),
          TripRoutePoint(address: 'C'),
          TripRoutePoint(address: 'D'),
        ],
        fares: fares({
          [0, 1]: 400,
          [1, 2]: 500,
          [0, 2]: 700,
          [1, 3]: 900,
          [0, 3]: 1200,
        }),
      );

      expect(draft.fareBetween(0, 2), 700);
      expect(draft.fareBetween(1, 3), 900);
    });

    test('a fare never drops below the minimum boarding price', () {
      final draft = _filledDraft().copyWith(
        fares: fares({
          [0, 2]: 1800,
          [0, 1]: 100,
          [1, 2]: 800,
        }),
        minimumBoardingPrice: 300,
      );

      expect(draft.fareBetween(0, 1), 300);
    });

    test('a pair the driver did not price has no fare and is not sold', () {
      final draft = _filledDraft().copyWith(
        fares: fares({
          [0, 2]: 1800,
          [0, 1]: 700,
        }),
      );

      expect(draft.fareBetween(1, 2), isNull);
    });

    test('a reversed range or an out-of-range point has no fare', () {
      final draft = _filledDraft();

      expect(draft.fareBetween(2, 1), isNull);
      expect(draft.fareBetween(0, 5), isNull);
    });
  });

  group('TripDraft validation', () {
    final now = DateTime(2026, 5, 15, 8);

    test('a fully filled draft can be published', () {
      expect(_filledDraft().canPublish(now: now), isTrue);
    });

    test('an empty draft reports every unfinished part', () {
      expect(const TripDraft().issues(now: now), {
        TripDraftIssue.route,
        TripDraftIssue.schedule,
        TripDraftIssue.seats,
        TripDraftIssue.pricing,
        TripDraftIssue.vehicle,
      });
    });

    test('the same address twice is not a route', () {
      final draft = _filledDraft().copyWith(
        points: const [
          TripRoutePoint(address: 'Улица Солнечная, дом 1'),
          TripRoutePoint(address: 'улица солнечная, дом 1 '),
        ],
        fares: fares({
          [0, 1]: 1800,
        }),
      );

      expect(draft.isRouteValid, isFalse);
    });

    test('an unset arrival keeps the schedule invalid', () {
      final draft = _filledDraft().copyWith(clearArrivalAt: true);

      expect(draft.isScheduleValid(now: now), isFalse);
    });

    test('an arrival before the departure is rejected', () {
      final draft = _filledDraft().copyWith(
        arrivalAt: DateTime(2026, 5, 15, 9),
      );

      expect(draft.isScheduleValid(now: now), isFalse);
    });

    test('departure time off the 30 minute grid is rejected', () {
      final draft = _filledDraft(departureAt: DateTime(2026, 5, 15, 9, 15));

      expect(draft.isScheduleValid(now: now), isFalse);
    });

    test('departure in the past is rejected', () {
      final draft = _filledDraft(departureAt: DateTime(2026, 5, 15, 7, 30));

      expect(draft.isScheduleValid(now: now), isFalse);
    });

    test('a boarding minimum above the full route price is rejected', () {
      expect(
        _filledDraft().copyWith(minimumBoardingPrice: 2000).isPricingValid,
        isFalse,
      );
    });

    test('a leg left unpriced is simply not sold separately', () {
      final draft = _filledDraft().copyWith(
        fares: fares({
          [0, 2]: 1800,
          [0, 1]: 700,
        }),
      );

      expect(draft.isPricingValid, isTrue);
      expect(draft.fareBetween(1, 2), isNull);
    });

    test('a leg priced at zero is rejected', () {
      final draft = _filledDraft().copyWith(
        fares: fares({
          [0, 2]: 1800,
          [0, 1]: 700,
          [1, 2]: 0,
        }),
      );

      expect(draft.issues(now: now), contains(TripDraftIssue.pricing));
    });

    test('an enabled extra without a price blocks publication', () {
      final draft = _filledDraft().copyWith(
        extras: const [
          TripExtraOffer(service: TripExtraService.childSeat, enabled: true),
          TripExtraOffer(service: TripExtraService.pets),
          TripExtraOffer(service: TripExtraService.luggage),
        ],
      );

      expect(draft.issues(now: now), contains(TripDraftIssue.extras));
    });

    test(
      'an enabled parcel service without a priced size blocks publication',
      () {
        final draft = _filledDraft().copyWith(
          parcel: const TripParcelOffer(enabled: true),
        );

        expect(draft.issues(now: now), contains(TripDraftIssue.extras));
      },
    );

    test('a route alone is enough to save the draft', () {
      final draft = const TripDraft().copyWith(
        points: const [
          TripRoutePoint(address: 'Москва'),
          TripRoutePoint(address: 'Тверь'),
        ],
      );

      expect(draft.canSave, isTrue);
      expect(draft.canPublish(now: now), isFalse);
    });
  });

  group('TripDraft return trip', () {
    test('reverses the route and its leg prices, and clears the schedule', () {
      final source = _filledDraft();

      final back = source.reversed(pairedTripId: 'trip_1');

      expect(back.points.map((point) => point.address).toList(), [
        'Улица Лунная, дом 2',
        'Улица Ленина, дом 5',
        'Улица Солнечная, дом 1',
      ]);
      // «Улица Ленина → Улица Лунная» at 800 becomes the mirrored first leg.
      expect(back.fares.priceFor(0, 1), 800);
      expect(back.fares.priceFor(1, 2), 700);
      expect(back.fullRoutePrice, 1800);
      expect(back.departureAt, isNull);
      expect(back.arrivalAt, isNull);
      expect(back.pairedTripId, 'trip_1');
    });

    test('keeps prices, seats, extras, booking mode and vehicle', () {
      final source = _filledDraft().copyWith(
        bookingMode: TripBookingMode.instant,
        parcel: const TripParcelOffer(
          enabled: true,
          priceBySize: {ParcelSize.small: 250},
          allowedWithoutPassenger: true,
        ),
      );

      final back = source.reversed();

      expect(back.fullRoutePrice, 1800);
      expect(back.minimumBoardingPrice, 300);
      expect(back.seatCount, 3);
      expect(back.bookingMode, TripBookingMode.instant);
      expect(back.vehicleId, 'preview_vehicle_largus');
      expect(back.parcel.allowedWithoutPassenger, isTrue);
    });

    test('a new departure and arrival make the return trip publishable', () {
      final back = _filledDraft()
          .reversed(departureAt: DateTime(2026, 5, 16, 10))
          .copyWith(arrivalAt: DateTime(2026, 5, 16, 18, 30));

      expect(back.canPublish(now: DateTime(2026, 5, 15, 8)), isTrue);
    });
  });

  group('TripDraft route roles', () {
    test('marks origin, intermediate stops and destination', () {
      final draft = _filledDraft();

      expect(draft.kindAt(0), TripStopKind.origin);
      expect(draft.kindAt(1), TripStopKind.intermediate);
      expect(draft.kindAt(2), TripStopKind.destination);
      expect(draft.intermediateStops.single.address, 'Улица Ленина, дом 5');
    });
  });
}
