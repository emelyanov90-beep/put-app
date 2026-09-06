import 'package:vput/features/auth/application/preview_session_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/app/router.dart';
import 'package:vput/features/trips/application/driver_trips_controller.dart';
import 'package:vput/features/trips/application/trip_draft_controller.dart';
import 'package:vput/features/trips/domain/trip_draft.dart';
import 'package:vput/features/trips/domain/trip_route_point.dart';
import 'package:vput/features/trips/presentation/driver/create_return_trip_screen.dart';
import 'package:vput/features/trips/presentation/driver/driver_trips_screen.dart';
import 'package:vput/features/trips/presentation/driver/trip_published_screen.dart';
import 'package:vput/features/trips/presentation/widgets/publish_confirmation_sheet.dart';
import 'package:vput/features/trips/presentation/widgets/trip_schedule_sheets.dart';

import '../../../../support/trip_fares.dart';

TripDraft _publishedDraft() {
  return TripDraft(
    points: const [
      TripRoutePoint(address: 'Победителей 1, Минск'),
      TripRoutePoint(address: 'Комсомонавтов 13, Минск'),
      TripRoutePoint(address: 'Рынок местный, Могилев'),
    ],
    departureAt: DateTime.now().add(const Duration(days: 1)),
    arrivalAt: DateTime.now().add(const Duration(days: 1, hours: 4)),
    seatCount: 3,
    fares: fares({
      [0, 2]: 1200,
      [0, 1]: 600,
      [1, 2]: 600,
    }),
    vehicleId: 'preview_vehicle_largus',
  );
}

Future<void> _tap(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'the return trip mirrors the route and asks for a new departure',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = ProviderContainer();
      container.read(previewSessionProvider.notifier).signIn();
      addTearDown(container.dispose);
      final sourceId = container
          .read(driverTripsProvider.notifier)
          .publish(_publishedDraft());
      final router = container.read(routerProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      router.go(AppRoutes.driverTrips);
      await tester.pumpAndSettle();

      await _tap(tester, DriverTripsScreen.returnTripKey(sourceId));

      // The route runs the other way round and the money is carried over.
      expect(find.byType(CreateReturnTripScreen), findsOneWidget);
      expect(find.text('Обратное направление'), findsOneWidget);
      expect(find.text('Рынок местный, Могилев'), findsOneWidget);
      expect(find.text('Победителей 1, Минск'), findsOneWidget);
      expect(find.text('Общая стоимость'), findsOneWidget);
      expect(find.text('1320 ₽'), findsOneWidget);
      expect(find.text('1200 ₽'), findsOneWidget);

      final started = container.read(tripDraftProvider);
      expect(started.origin.address, 'Рынок местный, Могилев');
      expect(started.destination.address, 'Победителей 1, Минск');
      expect(started.departureAt, isNull);
      expect(started.pairedTripId, sourceId);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(CreateReturnTripScreen.publishButtonKey),
            )
            .onPressed,
        isNull,
        reason: 'the departure has to be set first',
      );

      // A day after tomorrow keeps every half-hour slot available.
      await _tap(tester, CreateReturnTripScreen.dateFieldKey);
      await _tap(tester, TripDatePickerSheet.dayKey(2));
      await _tap(tester, CreateReturnTripScreen.departureTimeFieldKey);
      await _tap(tester, TripTimePickerSheet.slotKey('08:00'));
      await _tap(tester, CreateReturnTripScreen.arrivalTimeFieldKey);
      await _tap(tester, TripTimePickerSheet.slotKey('12:00'));

      expect(find.text('8:00'), findsOneWidget);
      expect(find.text('12:00'), findsOneWidget);

      // Publication is confirmed in a sheet that repeats the trip.
      await _tap(tester, CreateReturnTripScreen.publishButtonKey);

      expect(find.byKey(PublishConfirmationSheet.sheetKey), findsOneWidget);
      expect(find.text('Опубликовать поездку?'), findsOneWidget);
      expect(find.text('Доп. остановки'), findsOneWidget);
      expect(find.text('Тип бронирования'), findsOneWidget);
      expect(find.text('Toyota Camry, 7841HX-7'), findsNothing);

      await _tap(tester, PublishConfirmationSheet.segmentsToggleKey);
      expect(find.text('600₽'), findsNWidgets(2));

      await _tap(tester, PublishConfirmationSheet.confirmButtonKey);

      expect(find.byType(TripPublishedScreen), findsOneWidget);
      final trips = container.read(driverTripsProvider);
      expect(trips, hasLength(2));
      expect(trips.last.pairedTripId, sourceId);
      expect(
        trips.last.routeLabel,
        'Рынок местный, Могилев → Победителей 1, Минск',
      );

      await _tap(tester, TripPublishedScreen.myTripsButtonKey);

      expect(find.byType(DriverTripsScreen), findsOneWidget);
      // Both cards carry the action, and the new one is marked as the return.
      expect(find.text('Обратный маршрут'), findsWidgets);
      expect(find.text('Активная'), findsNWidgets(2));
    },
  );

  testWidgets('cancelling the confirmation leaves the trip unpublished', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer();
    container.read(previewSessionProvider.notifier).signIn();
    addTearDown(container.dispose);
    final sourceId = container
        .read(driverTripsProvider.notifier)
        .publish(_publishedDraft());
    final router = container.read(routerProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    router.go(AppRoutes.driverTrips);
    await tester.pumpAndSettle();

    await _tap(tester, DriverTripsScreen.returnTripKey(sourceId));
    await _tap(tester, CreateReturnTripScreen.dateFieldKey);
    await _tap(tester, TripDatePickerSheet.dayKey(2));
    await _tap(tester, CreateReturnTripScreen.departureTimeFieldKey);
    await _tap(tester, TripTimePickerSheet.slotKey('08:00'));
    await _tap(tester, CreateReturnTripScreen.arrivalTimeFieldKey);
    await _tap(tester, TripTimePickerSheet.slotKey('12:00'));
    await _tap(tester, CreateReturnTripScreen.publishButtonKey);
    await _tap(tester, PublishConfirmationSheet.cancelButtonKey);

    expect(find.byType(CreateReturnTripScreen), findsOneWidget);
    expect(container.read(driverTripsProvider), hasLength(1));
  });
}
