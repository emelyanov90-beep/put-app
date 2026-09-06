import 'package:vput/features/auth/application/preview_session_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/app/router.dart';
import 'package:vput/features/trips/application/driver_trips_controller.dart';
import 'package:vput/features/trips/application/trip_draft_controller.dart';
import 'package:vput/features/trips/domain/trip_route_point.dart';
import 'package:vput/features/trips/presentation/driver/create_trip_pricing_screen.dart';
import 'package:vput/features/trips/presentation/driver/create_trip_route_screen.dart';
import 'package:vput/features/trips/presentation/driver/create_trip_booking_mode_screen.dart';
import 'package:vput/features/trips/presentation/driver/create_trip_extras_screen.dart';
import 'package:vput/features/trips/presentation/driver/create_trip_summary_screen.dart';
import 'package:vput/features/trips/presentation/driver/create_trip_type_screen.dart';
import 'package:vput/features/trips/presentation/driver/create_trip_vehicle_screen.dart';
import 'package:vput/features/trips/presentation/driver/driver_trips_screen.dart';
import 'package:vput/features/trips/presentation/driver/trip_published_screen.dart';
import 'package:vput/features/trips/presentation/widgets/create_trip_controls.dart';
import 'package:vput/features/trips/presentation/widgets/driver_vehicle_picker.dart';
import 'package:vput/features/trips/presentation/widgets/trip_schedule_sheets.dart';

Future<void> _tap(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

Future<void> _next(WidgetTester tester) =>
    _tap(tester, CreateTripStepScaffold.primaryButtonKey);

void main() {
  testWidgets('a driver walks the six steps through to a published order', (
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
    router.go(AppRoutes.createTrip);
    await tester.pumpAndSettle();

    // Step 1 — order type.
    expect(find.byType(CreateTripTypeScreen), findsOneWidget);
    await _next(tester);

    // Step 2 — route, schedule and seats. A day after tomorrow keeps every
    // half-hour slot available whatever the wall clock says.
    expect(find.byType(CreateTripRouteScreen), findsOneWidget);
    await tester.enterText(
      find.byKey(CreateTripRouteScreen.originFieldKey),
      'Москва',
    );
    await tester.enterText(
      find.byKey(CreateTripRouteScreen.destinationFieldKey),
      'Тверь',
    );
    await tester.pump();

    await _tap(tester, CreateTripRouteScreen.dateFieldKey);
    await _tap(tester, TripDatePickerSheet.dayKey(2));
    await _tap(tester, CreateTripRouteScreen.departureTimeFieldKey);
    await _tap(tester, TripTimePickerSheet.slotKey('10:00'));
    await _tap(tester, CreateTripRouteScreen.arrivalTimeFieldKey);
    await _tap(tester, TripTimePickerSheet.slotKey('18:00'));
    await _tap(tester, CreateTripSeatCounter.increaseKey);
    await _next(tester);

    // Step 3 — price.
    expect(find.byType(CreateTripPricingScreen), findsOneWidget);
    await tester.enterText(
      find.byKey(CreateTripPricingScreen.fullRouteFieldKey),
      '1800',
    );
    await tester.pump();
    await _next(tester);

    // Step 4 — the car.
    expect(find.byType(CreateTripVehicleScreen), findsOneWidget);
    await _tap(
      tester,
      DriverVehiclePicker.vehicleKey('preview_vehicle_largus'),
    );
    await _next(tester);

    // Step 5 — extra services keep their defaults.
    expect(find.byType(CreateTripExtrasScreen), findsOneWidget);
    await _next(tester);

    // Step 6 — booking type, then publication.
    expect(find.byType(CreateTripBookingModeScreen), findsOneWidget);
    await _tap(tester, CreateTripBookingModeScreen.instantOptionKey);
    await _tap(tester, CreateTripBookingModeScreen.publishButtonKey);

    // The published trip is now in «Мои поездки».
    expect(find.byType(TripPublishedScreen), findsOneWidget);
    final published = container.read(driverTripsProvider).single;
    expect(published.isPublished, isTrue);
    expect(published.routeLabel, 'Москва → Тверь');
    expect(published.publishedAt, isNotNull);

    // «Мои заказы» closes the flow and shows the published trip.
    await _tap(tester, TripPublishedScreen.myTripsButtonKey);

    expect(find.byType(DriverTripsScreen), findsOneWidget);
    // The card lists the route as two points, one per line.
    expect(find.text('Москва'), findsOneWidget);
    expect(find.text('Тверь'), findsOneWidget);
    expect(find.text('Активная'), findsOneWidget);
  });

  testWidgets('a saved draft lands in «Мои поездки» and can be reopened', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer();
    container.read(previewSessionProvider.notifier).signIn();
    addTearDown(container.dispose);
    container.read(tripDraftProvider.notifier)
      ..setOrigin(const TripRoutePoint(address: 'Минск'))
      ..setDestination(const TripRoutePoint(address: 'Могилев'))
      ..setSeatCount(2)
      ..setFullRoutePrice(1200);
    final router = container.read(routerProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    router.go(AppRoutes.createTripSummary);
    await tester.pumpAndSettle();

    await _tap(tester, CreateTripSummaryScreen.saveDraftButtonKey);

    expect(find.byType(DriverTripsScreen), findsOneWidget);
    expect(find.text('Минск'), findsOneWidget);
    expect(find.text('Могилев'), findsOneWidget);
    expect(find.text('Черновик'), findsOneWidget);

    final saved = container.read(driverTripsProvider).single;
    expect(saved.isPublished, isFalse);
    expect(saved.draft.fullRoutePrice, 1200);

    // Reopening the draft brings the wizard back with its data.
    await _tap(tester, DriverTripsScreen.editKey(saved.id));

    expect(find.text('Изменение заказа'), findsOneWidget);
    expect(find.text('Могилев'), findsOneWidget);
    expect(container.read(editedDriverTripProvider), saved.id);
  });
}
