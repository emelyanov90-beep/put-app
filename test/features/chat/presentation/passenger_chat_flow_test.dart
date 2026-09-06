import 'package:vput/features/auth/application/preview_session_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/app/router.dart';
import 'package:vput/features/chat/application/chats_controller.dart';
import 'package:vput/features/chat/presentation/chat_screen.dart';
import 'package:vput/features/chat/presentation/chats_screen.dart';
import 'package:vput/features/trips/application/driver_trips_controller.dart';
import 'package:vput/features/trips/domain/driver_trip.dart';
import 'package:vput/features/trips/domain/trip_draft.dart';
import 'package:vput/features/trips/domain/trip_route_point.dart';
import 'package:vput/features/trips/presentation/driver/passenger_profile_screen.dart';
import 'package:vput/features/trips/presentation/widgets/passenger_bottom_bar.dart';

import '../../../support/trip_fares.dart';

const _passenger = DriverTripPassengerBooking(
  id: 'booking_1',
  passengerId: 'passenger_1',
  passengerName: 'Виктор О.',
  passengerRating: 4.8,
  pickupAddress: 'Улица Солнечная, дом 1',
  dropoffAddress: 'Улица Лунная, дом 2',
);

TripDraft _draft() {
  return TripDraft(
    points: const [
      TripRoutePoint(address: 'Улица Солнечная, дом 1'),
      TripRoutePoint(address: 'Улица Лунная, дом 2'),
    ],
    departureAt: DateTime.now().add(const Duration(days: 1)),
    arrivalAt: DateTime.now().add(const Duration(days: 1, hours: 5)),
    seatCount: 4,
    fares: fares({
      [0, 1]: 600,
    }),
    vehicleId: 'preview_vehicle_largus',
  );
}

Future<ProviderContainer> _pumpProfile(
  WidgetTester tester, {
  bool confirmed = true,
}) async {
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
    _passenger.copyWith(confirmed: confirmed),
  );
  final router = container.read(routerProvider);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  router.go('/passengers/passenger_1');
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets(
    'a confirmed passenger keeps the phone private and shows their route',
    (tester) async {
      await _pumpProfile(tester);

      expect(find.text('Профиль пассажира'), findsOneWidget);
      expect(find.text('Виктор О.'), findsOneWidget);
      expect(find.text('Номер телефона'), findsNothing);
      expect(find.text('Напишите в чат'), findsOneWidget);
      expect(find.text('Рейтинг поездок'), findsOneWidget);
      expect(find.byKey(PassengerProfileScreen.routeCardKey), findsOneWidget);
      expect(find.text('Точка посадки'), findsOneWidget);
      expect(find.text('Точка высадки'), findsOneWidget);
      expect(find.text('Написать'), findsOneWidget);
    },
  );

  testWidgets('before the decision the phone and route stay closed', (
    tester,
  ) async {
    await _pumpProfile(tester, confirmed: false);

    expect(find.text('Рейтинг поездок'), findsOneWidget);
    expect(find.text('Номер телефона'), findsNothing);
    expect(find.byKey(PassengerProfileScreen.routeCardKey), findsNothing);
  });

  testWidgets('«Написать» opens a chat and the message is sent', (
    tester,
  ) async {
    final container = await _pumpProfile(tester);

    await tester.tap(find.byKey(PassengerProfileScreen.chatButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(ChatScreen), findsOneWidget);
    expect(find.byKey(ChatScreen.emptyStateKey), findsOneWidget);
    // Nothing to send yet.
    expect(
      tester.widget<IconButton>(find.byKey(ChatScreen.sendButtonKey)).onPressed,
      isNull,
    );

    await tester.enterText(
      find.byKey(ChatScreen.messageFieldKey),
      'Буду через 5 минут',
    );
    await tester.pump();
    await tester.tap(find.byKey(ChatScreen.sendButtonKey));
    await tester.pumpAndSettle();

    expect(find.text('Буду через 5 минут'), findsOneWidget);
    expect(find.byKey(ChatScreen.emptyStateKey), findsNothing);

    final thread = container.read(chatsProvider).single;
    expect(thread.peerName, 'Виктор О.');
    expect(thread.messages.single.text, 'Буду через 5 минут');
  });

  testWidgets('the conversation shows up in «Чаты» and reopens', (
    tester,
  ) async {
    final container = await _pumpProfile(tester);

    await tester.tap(find.byKey(PassengerProfileScreen.chatButtonKey));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(ChatScreen.messageFieldKey), 'Еду');
    await tester.pump();
    await tester.tap(find.byKey(ChatScreen.sendButtonKey));
    await tester.pumpAndSettle();

    container.read(routerProvider).go(AppRoutes.chats);
    await tester.pumpAndSettle();

    expect(find.byType(ChatsScreen), findsOneWidget);
    expect(find.text('Виктор О.'), findsOneWidget);
    expect(find.text('Еду'), findsOneWidget);

    final threadId = container.read(chatsProvider).single.id;
    await tester.tap(find.byKey(ChatsScreen.threadKey(threadId)));
    await tester.pumpAndSettle();

    expect(find.byType(ChatScreen), findsOneWidget);
    expect(find.text('Еду'), findsOneWidget);
  });

  testWidgets('with no conversations «Чаты» explains what to do', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer();
    container.read(previewSessionProvider.notifier).signIn();
    addTearDown(container.dispose);
    final router = container.read(routerProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    router.go(AppRoutes.chats);
    await tester.pumpAndSettle();

    expect(find.byKey(ChatsScreen.emptyStateKey), findsOneWidget);
    expect(find.text('Чатов пока нет'), findsOneWidget);

    // The tab keeps the navigation, so the driver is never stuck here.
    expect(find.byType(PassengerBottomBar), findsOneWidget);

    await tester.tap(find.byKey(PassengerBottomBar.ordersButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(ChatsScreen), findsNothing);
    expect(find.text('Мои заказы'), findsWidgets);
  });
}
