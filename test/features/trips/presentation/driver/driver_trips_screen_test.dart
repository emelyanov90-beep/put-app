import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/trips/application/driver_trips_controller.dart';
import 'package:vput/features/trips/domain/driver_trip.dart';
import 'package:vput/features/trips/domain/trip_draft.dart';
import 'package:vput/features/trips/domain/trip_route_point.dart';
import 'package:vput/features/trips/presentation/driver/driver_trips_screen.dart';

TripDraft _draft({String destination = 'Тверь'}) {
  return TripDraft(
    points: [
      const TripRoutePoint(address: 'Москва'),
      TripRoutePoint(address: destination),
    ],
    departureAt: DateTime(2026, 5, 16, 9, 30),
    arrivalAt: DateTime(2026, 5, 16, 18),
    seatCount: 3,
    fullRoutePrice: 1800,
    vehicleId: 'preview_vehicle_largus',
  );
}

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  void Function(DriverTripsController controller)? seed,
  ValueChanged<DriverTrip>? onEdit,
  ValueChanged<DriverTrip>? onPublish,
  ValueChanged<DriverTrip>? onCreateReturnTrip,
  ValueChanged<DriverTripPassengerBooking>? onPassengerProfile,
  ValueChanged<DriverTripPassengerBooking>? onPassengerChat,
  VoidCallback? onCreateTrip,
  VoidCallback? onDriverBlocked,
  DateTime? now,
}) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer();
  addTearDown(container.dispose);
  seed?.call(container.read(driverTripsProvider.notifier));

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: DriverTripsScreen(
          onBack: () {},
          onCreateTrip: onCreateTrip ?? () {},
          onEdit: onEdit ?? (_) {},
          onPublish: onPublish ?? (_) {},
          onCreateReturnTrip: onCreateReturnTrip ?? (_) {},
          onPassengerProfile: onPassengerProfile,
          onPassengerChat: onPassengerChat,
          onDriverBlocked: onDriverBlocked,
          now: now ?? DateTime(2026, 5, 15),
        ),
      ),
    ),
  );
  return container;
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
}

void main() {
  testWidgets('offers to create the first trip when there are none', (
    tester,
  ) async {
    var creates = 0;
    await _pump(tester, onCreateTrip: () => creates++);

    expect(find.byKey(DriverTripsScreen.titleKey), findsOneWidget);
    expect(find.text('Мои заказы'), findsOneWidget);
    expect(find.text('Активные'), findsOneWidget);
    expect(find.text('Завершенные'), findsOneWidget);
    expect(find.byKey(DriverTripsScreen.emptyStateKey), findsOneWidget);
    expect(find.text('У вас пока нет поездок'), findsOneWidget);
    expect(
      find.text('Создайте поездку, чтобы пассажиры могли найти ваш маршрут'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(DriverTripsScreen.createButtonKey));
    await tester.pump();

    expect(creates, 1);
  });

  testWidgets('a draft can be edited and published from the list', (
    tester,
  ) async {
    DriverTrip? edited;
    DriverTrip? published;
    final container = await _pump(
      tester,
      seed: (controller) => controller.saveDraft(_draft()),
      onEdit: (trip) => edited = trip,
      onPublish: (trip) => published = trip,
    );
    final id = container.read(driverTripsProvider).single.id;

    expect(find.text('Заказ №1'), findsOneWidget);
    expect(find.text('Москва'), findsOneWidget);
    expect(find.text('Тверь'), findsOneWidget);
    expect(find.text('Черновик'), findsOneWidget);
    expect(find.text('16 мая, 09:30–18:00'), findsOneWidget);
    expect(find.text('1800 ₽'), findsOneWidget);

    await _tapVisible(tester, find.byKey(DriverTripsScreen.editKey(id)));
    await _tapVisible(tester, find.byKey(DriverTripsScreen.publishKey(id)));

    expect(edited?.id, id);
    expect(published?.id, id);
  });

  testWidgets('a published trip offers the return route instead', (
    tester,
  ) async {
    DriverTrip? returned;
    final container = await _pump(
      tester,
      seed: (controller) => controller.publish(_draft()),
      onCreateReturnTrip: (trip) => returned = trip,
    );
    final id = container.read(driverTripsProvider).single.id;

    expect(find.text('Активные'), findsOneWidget);
    expect(find.text('Активная'), findsOneWidget);
    expect(find.byKey(DriverTripsScreen.publishKey(id)), findsNothing);

    await _tapVisible(tester, find.byKey(DriverTripsScreen.returnTripKey(id)));

    expect(returned?.id, id);
  });

  testWidgets('a completed published trip shows the completed status', (
    tester,
  ) async {
    await _pump(
      tester,
      seed: (controller) => controller.publish(_draft()),
      now: DateTime(2026, 5, 17),
    );

    expect(find.text('Активных поездок нет'), findsOneWidget);
    await tester.tap(find.byKey(DriverTripsScreen.completedTabKey));
    await tester.pumpAndSettle();

    expect(find.text('Завершенная'), findsOneWidget);
  });

  testWidgets('joined passengers block editing and expose profile and chat', (
    tester,
  ) async {
    DriverTrip? edited;
    DriverTripPassengerBooking? openedProfile;
    DriverTripPassengerBooking? openedChat;
    final container = await _pump(
      tester,
      seed: (controller) {
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
      },
      onEdit: (trip) => edited = trip,
      onPassengerProfile: (booking) => openedProfile = booking,
      onPassengerChat: (booking) => openedChat = booking,
    );
    final id = container.read(driverTripsProvider).single.id;

    expect(find.text('1 отклик'), findsOneWidget);
    expect(find.text('Анна Смирнова'), findsOneWidget);
    expect(find.text('Свободно мест: 1 из 3'), findsOneWidget);
    await tester.ensureVisible(find.byKey(DriverTripsScreen.editKey(id)));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(DriverTripsScreen.editKey(id)))
          .onPressed,
      isNull,
    );

    await _tapVisible(
      tester,
      find.byKey(DriverTripsScreen.passengerProfileKey('booking_1')),
    );
    await _tapVisible(
      tester,
      find.byKey(DriverTripsScreen.passengerChatKey('booking_1')),
    );

    expect(edited, isNull);
    expect(openedProfile?.passengerId, 'passenger_1');
    expect(openedChat?.passengerId, 'passenger_1');
  });

  testWidgets('seat capacity cannot be reduced below joined passenger seats', (
    tester,
  ) async {
    final container = await _pump(
      tester,
      seed: (controller) {
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
      },
    );
    final id = container.read(driverTripsProvider).single.id;

    await _tapVisible(
      tester,
      find.byKey(DriverTripsScreen.seatDecreaseKey(id)),
    );

    expect(container.read(driverTripsProvider).single.draft.seatCount, 2);
    expect(find.text('Свободно мест: 0 из 2'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(find.byKey(DriverTripsScreen.seatDecreaseKey(id)))
          .onPressed,
      isNull,
    );
  });

  testWidgets('cancelling a trip with passengers warns the driver first', (
    tester,
  ) async {
    final container = await _pump(
      tester,
      seed: (controller) {
        final id = controller.publish(_draft());
        controller.addPassengerBooking(
          id,
          const DriverTripPassengerBooking(
            id: 'booking_1',
            passengerId: 'passenger_1',
            passengerName: 'Анна Смирнова',
            passengerRating: 4.8,
          ),
        );
      },
    );
    final id = container.read(driverTripsProvider).single.id;

    await _tapVisible(tester, find.byKey(DriverTripsScreen.cancelKey(id)));
    await tester.pumpAndSettle();

    expect(
      find.byKey(DriverTripsScreen.cancellationWarningDialogKey),
      findsOneWidget,
    );

    await tester.tap(find.byKey(DriverTripsScreen.cancelConfirmButtonKey));
    await tester.pumpAndSettle();

    expect(container.read(driverTripsProvider), isEmpty);
    expect(find.textContaining('засчитана за 30 дней'), findsOneWidget);
  });

  testWidgets('second passenger cancellation reports driver block', (
    tester,
  ) async {
    var blocked = 0;
    final container = await _pump(
      tester,
      seed: (controller) {
        final id = controller.publish(_draft());
        controller
          ..setRecentCancellations30d(id, 1)
          ..addPassengerBooking(
            id,
            const DriverTripPassengerBooking(
              id: 'booking_1',
              passengerId: 'passenger_1',
              passengerName: 'Анна Смирнова',
              passengerRating: 4.8,
            ),
          );
      },
      onDriverBlocked: () => blocked++,
    );
    final id = container.read(driverTripsProvider).single.id;

    await tester.pump();
    await _tapVisible(tester, find.byKey(DriverTripsScreen.cancelKey(id)));
    await tester.pumpAndSettle();

    expect(
      find.byKey(DriverTripsScreen.cancellationLimitDialogKey),
      findsOneWidget,
    );

    await tester.tap(find.byKey(DriverTripsScreen.cancelConfirmButtonKey));
    await tester.pumpAndSettle();

    expect(blocked, 1);
  });

  testWidgets('the daily limit blocks publishing a remaining draft', (
    tester,
  ) async {
    final container = await _pump(
      tester,
      seed: (controller) => controller
        ..publish(_draft())
        ..publish(_draft(destination: 'Клин'))
        ..saveDraft(_draft(destination: 'Могилев')),
    );
    final draftId = container
        .read(driverTripsByStatusProvider)
        .drafts
        .single
        .id;

    expect(find.byKey(DriverTripsScreen.limitNoticeKey), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(DriverTripsScreen.tripKey(draftId)),
      300,
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(DriverTripsScreen.publishKey(draftId)),
          )
          .onPressed,
      isNull,
    );
  });
}
