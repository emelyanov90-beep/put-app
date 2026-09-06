import 'package:vput/features/auth/application/preview_session_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/app/router.dart';
import 'package:vput/features/trips/application/driver_trips_controller.dart';
import 'package:vput/features/trips/application/trip_draft_controller.dart';
import 'package:vput/features/trips/domain/driver_trip.dart';
import 'package:vput/features/trips/domain/trip_draft.dart';
import 'package:vput/features/trips/domain/trip_route_point.dart';
import 'package:vput/features/trips/presentation/driver/driver_booking_request_screen.dart';
import 'package:vput/features/trips/presentation/driver/create_trip_route_screen.dart';
import 'package:vput/features/trips/presentation/driver/driver_trip_details_screen.dart';
import 'package:vput/features/trips/presentation/widgets/create_trip_controls.dart';
import 'package:vput/features/trips/presentation/widgets/new_booking_request_dialog.dart';
import 'package:vput/features/trips/presentation/widgets/passenger_paid_dialog.dart';

const _request = DriverTripPassengerBooking(
  id: 'booking_1',
  passengerId: 'passenger_1',
  passengerName: 'Анастасия К.',
  passengerRating: 4.8,
  confirmed: false,
  pickupAddress: 'Улица Ленина, дом 5',
  dropoffAddress: 'Улица Лунная, дом 2',
);

TripDraft _draft() {
  return TripDraft(
    points: const [
      TripRoutePoint(address: 'Улица Солнечная, дом 1'),
      TripRoutePoint(address: 'Улица Ленина, дом 5'),
      TripRoutePoint(address: 'Улица Лунная, дом 2'),
    ],
    departureAt: DateTime.now().add(const Duration(days: 1)),
    arrivalAt: DateTime.now().add(const Duration(days: 1, hours: 6)),
    seatCount: 4,
    fullRoutePrice: 600,
    vehicleId: 'preview_vehicle_largus',
  );
}

Future<ProviderContainer> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer();
  container.read(previewSessionProvider.notifier).signIn();
  addTearDown(container.dispose);
  final controller = container.read(driverTripsProvider.notifier);
  final tripId = controller.publish(_draft());
  controller.addPassengerBooking(tripId, _request);
  final router = container.read(routerProvider);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  router.go(AppRoutes.driverTrips);
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('a new request is announced and can be confirmed', (
    tester,
  ) async {
    final container = await _pump(tester);

    // The driver is told about the request as soon as the list opens.
    expect(find.byKey(NewBookingRequestDialog.dialogKey), findsOneWidget);
    expect(find.text('Новый отклик'), findsOneWidget);
    expect(
      find.text(
        'Пассажир хочет присоединиться к вашей поездке. Ожидается ваше '
        'решение.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(NewBookingRequestDialog.openButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(DriverBookingRequestScreen), findsOneWidget);
    expect(find.text('Маршрут пассажира'), findsOneWidget);
    expect(find.text('Улица Ленина, дом 5'), findsWidgets);

    await tester.tap(find.byKey(DriverBookingRequestScreen.approveButtonKey));
    await tester.pumpAndSettle();

    // The driver lands on the trip, where the row now waits for the payment.
    expect(find.byType(DriverTripDetailsScreen), findsOneWidget);
    expect(find.text('Бронь подтверждена'), findsOneWidget);
    expect(find.text('Ожидает оплаты'), findsOneWidget);
    final trip = container.read(driverTripsProvider).single;
    expect(trip.passengerBookings.single.confirmed, isTrue);
    expect(trip.pendingPassengerRequests, isEmpty);
    expect(trip.bookedSeatCount, 1);
  });

  testWidgets('turning a request down removes it from the trip', (
    tester,
  ) async {
    final container = await _pump(tester);

    await tester.tap(find.byKey(NewBookingRequestDialog.openButtonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DriverBookingRequestScreen.rejectButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(DriverTripDetailsScreen), findsOneWidget);
    expect(find.text('Бронь отклонена'), findsOneWidget);
    final trip = container.read(driverTripsProvider).single;
    expect(trip.passengerBookings, isEmpty);
    expect(trip.bookedSeatCount, 0);
  });

  testWidgets('the notice is shown once per request', (tester) async {
    final container = await _pump(tester);

    await tester.tap(find.byKey(NewBookingRequestDialog.openButtonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DriverBookingRequestScreen.rejectButtonKey));
    await tester.pumpAndSettle();

    expect(container.read(seenBookingRequestsProvider), contains('booking_1'));
    expect(find.byKey(NewBookingRequestDialog.dialogKey), findsNothing);
  });

  testWidgets('the trip lists what each booking is waiting for', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer();
    container.read(previewSessionProvider.notifier).signIn();
    addTearDown(container.dispose);
    final controller = container.read(driverTripsProvider.notifier);
    final tripId = controller.publish(_draft());
    controller
      ..addPassengerBooking(tripId, _request)
      ..addPassengerBooking(
        tripId,
        const DriverTripPassengerBooking(
          id: 'booking_2',
          passengerId: 'passenger_2',
          passengerName: 'Виктор О.',
          passengerRating: 4.5,
        ),
      )
      ..addPassengerBooking(
        tripId,
        const DriverTripPassengerBooking(
          id: 'booking_3',
          passengerId: 'passenger_3',
          passengerName: 'Мария П.',
          passengerRating: 5,
          paid: true,
        ),
      );
    final router = container.read(routerProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    router.go('/driver-trips/$tripId');
    await tester.pumpAndSettle();

    expect(find.text('Подтвердите бронь'), findsOneWidget);
    expect(find.text('Ожидает оплаты'), findsOneWidget);
    expect(find.text('Оплачено'), findsOneWidget);
  });

  testWidgets('a completed trip can be repeated as a new draft', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer();
    container.read(previewSessionProvider.notifier).signIn();
    addTearDown(container.dispose);
    final pastDeparture = DateTime.now().subtract(const Duration(days: 2));
    final completedDraft = _draft().copyWith(
      departureAt: pastDeparture,
      arrivalAt: pastDeparture.add(const Duration(hours: 6)),
      pairedTripId: 'old_pair',
    );
    final tripId = container
        .read(driverTripsProvider.notifier)
        .publish(completedDraft);
    final router = container.read(routerProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    router.go('/driver-trips/$tripId');
    await tester.pumpAndSettle();

    expect(find.byKey(DriverTripDetailsScreen.repeatButtonKey), findsOneWidget);
    expect(find.byKey(DriverTripDetailsScreen.cancelButtonKey), findsNothing);

    await tester.tap(find.byKey(DriverTripDetailsScreen.repeatButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(CreateTripRouteScreen), findsOneWidget);
    final repeatedDraft = container.read(tripDraftProvider);
    expect(repeatedDraft.origin.address, 'Улица Солнечная, дом 1');
    expect(repeatedDraft.destination.address, 'Улица Лунная, дом 2');
    expect(repeatedDraft.fullRoutePrice, 600);
    expect(repeatedDraft.departureAt, isNull);
    expect(repeatedDraft.arrivalAt, isNull);
    expect(repeatedDraft.pairedTripId, isNull);
    expect(container.read(editedDriverTripProvider), isNull);
  });

  testWidgets(
    'driver changes seats and closes passenger reception from details',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = ProviderContainer();
      container.read(previewSessionProvider.notifier).signIn();
      addTearDown(container.dispose);
      final controller = container.read(driverTripsProvider.notifier);
      final tripId = controller.publish(_draft());
      controller.addPassengerBooking(
        tripId,
        const DriverTripPassengerBooking(
          id: 'booking_1',
          passengerId: 'passenger_1',
          passengerName: 'Анастасия К.',
          passengerRating: 4.8,
          seatCount: 1,
          paid: true,
        ),
      );
      final router = container.read(routerProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      router.go('/driver-trips/$tripId');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(DriverTripDetailsScreen.menuButtonKey));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(DriverTripDetailsScreen.changeSeatsMenuItemKey),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(CreateTripSeatCounter.decreaseKey));
      await tester.pump();
      await tester.tap(
        find.byKey(DriverTripDetailsScreen.seatCapacitySaveButtonKey),
      );
      await tester.pumpAndSettle();

      expect(controller.findById(tripId)!.draft.seatCount, 3);
      expect(find.text('Изменения сохранены'), findsOneWidget);

      await tester.tap(find.byKey(DriverTripDetailsScreen.menuButtonKey));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(DriverTripDetailsScreen.closeRegistrationMenuItemKey),
      );
      await tester.pumpAndSettle();

      final trip = controller.findById(tripId)!;
      expect(trip.draft.seatCount, 1);
      expect(trip.freeSeatCount, 0);
      expect(find.text('Приём пассажиров завершён'), findsOneWidget);
    },
  );

  testWidgets('a paid booking is announced and opens the trip', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer();
    container.read(previewSessionProvider.notifier).signIn();
    addTearDown(container.dispose);
    final controller = container.read(driverTripsProvider.notifier);
    final tripId = controller.publish(_draft());
    controller
      ..addPassengerBooking(tripId, _request.copyWith(confirmed: true))
      ..setPassengerBookingPaid(tripId: tripId, bookingId: 'booking_1');
    final router = container.read(routerProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    router.go(AppRoutes.driverTrips);
    await tester.pumpAndSettle();

    expect(find.byKey(PassengerPaidDialog.dialogKey), findsOneWidget);
    expect(find.text('Пассажир оплатил поездку'), findsOneWidget);
    expect(
      find.text(
        'Пассажир успешно оплатил поездку. Место в вашей поездке '
        'забронировано.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(PassengerPaidDialog.openButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(DriverTripDetailsScreen), findsOneWidget);
    expect(find.text('Оплачено'), findsOneWidget);
  });
}
