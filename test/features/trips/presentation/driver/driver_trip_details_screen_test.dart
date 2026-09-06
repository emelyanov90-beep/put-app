import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/trips/domain/driver_trip.dart';
import 'package:vput/features/trips/domain/passenger_trip.dart';
import 'package:vput/features/trips/domain/trip_draft.dart';
import 'package:vput/features/trips/domain/trip_extras.dart';
import 'package:vput/features/trips/domain/trip_route_point.dart';
import 'package:vput/features/trips/presentation/driver/driver_trip_details_screen.dart';
import 'package:vput/features/trips/presentation/driver/passenger_profile_screen.dart';
import 'package:vput/features/trips/presentation/widgets/create_trip_controls.dart';

TripDraft _draft() {
  return TripDraft(
    points: const [
      TripRoutePoint(address: 'Улица Солнечная, дом 1'),
      TripRoutePoint(address: 'Улица Ленина, дом 5'),
      TripRoutePoint(address: 'Улица Пушкина, дом 10'),
      TripRoutePoint(address: 'Улица Лунная, дом 2'),
    ],
    departureAt: DateTime(2026, 5, 15, 8),
    arrivalAt: DateTime(2026, 5, 15, 18),
    seatCount: 24,
    fullRoutePrice: 600,
    extras: const [
      TripExtraOffer(service: TripExtraService.childSeat),
      TripExtraOffer(service: TripExtraService.pets, enabled: true, price: 150),
      TripExtraOffer(
        service: TripExtraService.luggage,
        enabled: true,
        price: 150,
      ),
    ],
    parcel: const TripParcelOffer(
      enabled: true,
      priceBySize: {ParcelSize.small: 400, ParcelSize.medium: 500},
    ),
    vehicleId: 'preview_vehicle_largus',
  );
}

DriverTrip _trip({List<DriverTripPassengerBooking> passengers = const []}) {
  return DriverTrip(
    id: 'driver_trip_1231',
    draft: _draft(),
    status: DriverTripStatus.published,
    passengerBookings: passengers,
  );
}

Widget _details({
  required DriverTrip trip,
  VoidCallback? onEdit,
  VoidCallback? onCancelTrip,
  VoidCallback? onRepeatTrip,
  ValueChanged<int>? onSeatCapacityChanged,
  VoidCallback? onClosePassengerRegistration,
  ValueChanged<DriverTripPassengerBooking>? onPassenger,
  DateTime? now,
}) {
  return ProviderScope(
    child: MaterialApp(
      home: DriverTripDetailsScreen(
        trip: trip,
        onBack: () {},
        onEdit: onEdit ?? () {},
        onCancelTrip: onCancelTrip ?? () {},
        onRepeatTrip: onRepeatTrip ?? () {},
        onSeatCapacityChanged: onSeatCapacityChanged ?? (_) {},
        onClosePassengerRegistration: onClosePassengerRegistration ?? () {},
        onPassenger: onPassenger ?? (_) {},
        now: now ?? DateTime(2026, 5, 14),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'shows driver trip details without passengers and opens edit menu',
    (tester) async {
      var edits = 0;
      var cancellations = 0;
      await tester.pumpWidget(
        _details(
          trip: _trip(),
          onEdit: () => edits++,
          onCancelTrip: () => cancellations++,
        ),
      );

      expect(find.text('Поездка'), findsOneWidget);
      expect(find.byKey(DriverTripDetailsScreen.routeCardKey), findsOneWidget);
      expect(find.text('Улица Солнечная, дом 1'), findsOneWidget);
      expect(find.text('Улица Ленина, дом 5'), findsOneWidget);
      expect(find.text('Улица Пушкина, дом 10'), findsOneWidget);
      expect(find.text('Улица Лунная, дом 2'), findsOneWidget);
      expect(find.text('600 ₽'), findsOneWidget);
      expect(find.text('50 ₽'), findsOneWidget);
      expect(find.text('550 ₽'), findsOneWidget);
      expect(find.text('24 из 24'), findsOneWidget);
      expect(find.text('Водитель'), findsOneWidget);
      expect(
        find.byKey(DriverTripDetailsScreen.vehicleCardKey),
        findsOneWidget,
      );

      await tester.tap(find.byKey(DriverTripDetailsScreen.menuButtonKey));
      await tester.pumpAndSettle();
      expect(find.text('Редактировать'), findsOneWidget);

      await tester.tap(find.text('Редактировать'));
      await tester.pumpAndSettle();
      expect(edits, 1);

      await tester.ensureVisible(
        find.byKey(DriverTripDetailsScreen.cancelButtonKey),
      );
      await tester.tap(find.byKey(DriverTripDetailsScreen.cancelButtonKey));
      await tester.pumpAndSettle();
      expect(find.text('Отменить поездку?'), findsOneWidget);

      await tester.tap(find.text('Да, отменить'));
      await tester.pumpAndSettle();
      expect(cancellations, 1);
    },
  );

  testWidgets('shows passengers and opens selected passenger profile', (
    tester,
  ) async {
    DriverTripPassengerBooking? selected;
    const passenger = DriverTripPassengerBooking(
      id: 'booking_1',
      passengerId: 'passenger_1',
      passengerName: 'Виктор О.',
      passengerRating: 4.5,
      passengerAvatarAsset: 'docs/imgs/passagire.png',
      seatCount: 14,
    );

    await tester.pumpWidget(
      _details(
        trip: _trip(passengers: const [passenger]),
        onPassenger: (value) => selected = value,
      ),
    );

    expect(find.text('Пассажиры'), findsOneWidget);
    expect(
      find.byKey(DriverTripDetailsScreen.passengersBlockKey),
      findsOneWidget,
    );
    expect(find.text('10 из 24'), findsOneWidget);
    expect(find.text('Виктор О.'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(DriverTripDetailsScreen.passengerKey('booking_1')),
    );
    await tester.tap(
      find.byKey(DriverTripDetailsScreen.passengerKey('booking_1')),
    );
    await tester.pump();

    expect(selected?.passengerId, 'passenger_1');
  });

  testWidgets('joined passengers limit editing to seat and reception actions', (
    tester,
  ) async {
    var edits = 0;
    var closed = 0;
    final seatChanges = <int>[];
    const passenger = DriverTripPassengerBooking(
      id: 'booking_1',
      passengerId: 'passenger_1',
      passengerName: 'Виктор О.',
      passengerRating: 4.5,
      seatCount: 14,
    );

    await tester.pumpWidget(
      _details(
        trip: _trip(passengers: const [passenger]),
        onEdit: () => edits++,
        onSeatCapacityChanged: seatChanges.add,
        onClosePassengerRegistration: () => closed++,
      ),
    );

    await tester.tap(find.byKey(DriverTripDetailsScreen.menuButtonKey));
    await tester.pumpAndSettle();

    expect(find.text('Изменить количество мест'), findsOneWidget);
    expect(find.text('Редактировать'), findsOneWidget);
    expect(find.text('Передать пассажиров'), findsOneWidget);
    expect(find.text('Завершить приём пассажиров'), findsOneWidget);
    expect(
      tester
          .widget<PopupMenuItem<dynamic>>(
            find.byKey(DriverTripDetailsScreen.editMenuItemKey),
          )
          .enabled,
      isTrue,
    );

    await tester.tap(find.byKey(DriverTripDetailsScreen.editMenuItemKey));
    await tester.pumpAndSettle();

    expect(
      find.byKey(DriverTripDetailsScreen.editUnavailableSheetKey),
      findsOneWidget,
    );
    expect(find.text('Редактирование недоступно'), findsOneWidget);

    await tester.tap(
      find.byKey(DriverTripDetailsScreen.editUnavailableOkButtonKey),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(DriverTripDetailsScreen.menuButtonKey));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(DriverTripDetailsScreen.transferPassengersMenuItemKey),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(DriverTripDetailsScreen.transferUnavailableSheetKey),
      findsOneWidget,
    );
    expect(find.text('Передача пассажиров'), findsOneWidget);

    await tester.tap(
      find.byKey(DriverTripDetailsScreen.transferUnavailableOkButtonKey),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(DriverTripDetailsScreen.menuButtonKey));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(DriverTripDetailsScreen.changeSeatsMenuItemKey),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(DriverTripDetailsScreen.seatCapacitySheetKey),
      findsOneWidget,
    );
    expect(find.text('Количество мест'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(DriverTripDetailsScreen.seatCapacitySaveButtonKey),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.byKey(CreateTripSeatCounter.decreaseKey));
    await tester.pump();
    await tester.tap(
      find.byKey(DriverTripDetailsScreen.seatCapacitySaveButtonKey),
    );
    await tester.pumpAndSettle();

    expect(seatChanges, [23]);
    expect(edits, 0);

    await tester.tap(find.byKey(DriverTripDetailsScreen.menuButtonKey));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(DriverTripDetailsScreen.closeRegistrationMenuItemKey),
    );
    await tester.pump();

    expect(closed, 1);
  });

  testWidgets('completed trip shows repeat action instead of cancellation', (
    tester,
  ) async {
    var repeats = 0;
    var cancellations = 0;

    await tester.pumpWidget(
      _details(
        trip: _trip(),
        now: DateTime(2026, 5, 16),
        onRepeatTrip: () => repeats++,
        onCancelTrip: () => cancellations++,
      ),
    );

    expect(find.text('Повторить поездку'), findsOneWidget);
    expect(find.byKey(DriverTripDetailsScreen.repeatButtonKey), findsOneWidget);
    expect(find.byKey(DriverTripDetailsScreen.cancelButtonKey), findsNothing);

    await tester.tap(find.byKey(DriverTripDetailsScreen.repeatButtonKey));
    await tester.pump();

    expect(repeats, 1);
    expect(cancellations, 0);
  });

  testWidgets('passenger profile keeps phone private and opens chat', (
    tester,
  ) async {
    var chats = 0;
    const passenger = DriverTripPassengerBooking(
      id: 'booking_1',
      passengerId: 'passenger_1',
      passengerName: 'Виктор О.',
      passengerRating: 4.8,
      passengerAvatarAsset: 'docs/imgs/passagire.png',
      passengerPhone: '+7 000 000 00 00',
      passengerTripsCount: 120,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PassengerProfileScreen(
          passenger: passenger,
          onBack: () {},
          onChat: () => chats++,
        ),
      ),
    );

    expect(find.byKey(PassengerProfileScreen.titleKey), findsOneWidget);
    expect(find.text('Виктор О.'), findsOneWidget);
    expect(find.text('+7 000 000 00 00'), findsNothing);
    expect(find.text('5 звезд, нет отзывов'), findsOneWidget);

    await tester.tap(find.byKey(PassengerProfileScreen.chatButtonKey));
    await tester.pump();

    expect(chats, 1);
  });
}
