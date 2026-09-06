import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/trips/application/trip_draft_controller.dart';
import 'package:vput/features/trips/presentation/driver/create_trip_route_screen.dart';
import 'package:vput/features/trips/presentation/widgets/create_trip_controls.dart';
import 'package:vput/features/trips/presentation/widgets/trip_schedule_sheets.dart';

final _now = DateTime(2026, 5, 15, 9, 20);

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  VoidCallback? onNext,
}) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer();
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: CreateTripRouteScreen(
          now: _now,
          onBack: () {},
          onContinue: onNext ?? () {},
        ),
      ),
    ),
  );
  return container;
}

Future<void> _tap(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

VoidCallback? _primaryAction(WidgetTester tester) {
  return tester
      .widget<FilledButton>(find.byKey(CreateTripStepScaffold.primaryButtonKey))
      .onPressed;
}

void main() {
  testWidgets('collects route, schedule and seats before the next step', (
    tester,
  ) async {
    var continues = 0;
    final container = await _pump(tester, onNext: () => continues++);

    expect(find.text('Шаг 2 из 6'), findsOneWidget);
    expect(find.text('Маршрут'), findsOneWidget);
    expect(find.text('Точка посадки'), findsOneWidget);
    expect(find.text('Пункт назначения'), findsOneWidget);
    expect(find.text('Дата и время выезда'), findsOneWidget);
    expect(find.text('Примерное время прибытия'), findsOneWidget);
    expect(find.text('Количество мест:'), findsOneWidget);
    expect(_primaryAction(tester), isNull);

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
    expect(find.byKey(TripDatePickerSheet.sheetKey), findsOneWidget);
    await _tap(tester, TripDatePickerSheet.dayKey(2));

    await _tap(tester, CreateTripRouteScreen.departureTimeFieldKey);
    await _tap(tester, TripTimePickerSheet.slotKey('10:00'));

    await _tap(tester, CreateTripRouteScreen.arrivalTimeFieldKey);
    await _tap(tester, TripTimePickerSheet.slotKey('18:00'));

    expect(_primaryAction(tester), isNull, reason: 'seats are still zero');

    await _tap(tester, CreateTripSeatCounter.increaseKey);

    final draft = container.read(tripDraftProvider);
    expect(draft.departureAt, DateTime(2026, 5, 17, 10));
    expect(draft.arrivalAt, DateTime(2026, 5, 17, 18));
    expect(draft.seatCount, 1);
    expect(find.text('17 мая'), findsOneWidget);
    expect(find.text('10:00'), findsOneWidget);
    expect(find.text('18:00'), findsOneWidget);

    await tester.tap(find.byKey(CreateTripStepScaffold.primaryButtonKey));
    await tester.pump();

    expect(continues, 1);
  });

  testWidgets('the departure time offers only slots still ahead today', (
    tester,
  ) async {
    await _pump(tester);

    await _tap(tester, CreateTripRouteScreen.departureTimeFieldKey);

    expect(find.byKey(TripTimePickerSheet.slotKey('09:00')), findsNothing);
    expect(find.byKey(TripTimePickerSheet.slotKey('09:15')), findsNothing);
    expect(find.byKey(TripTimePickerSheet.slotKey('09:30')), findsOneWidget);
  });

  testWidgets('adds and removes a planned stop', (tester) async {
    final container = await _pump(tester);

    await _tap(tester, CreateTripRouteScreen.addStopButtonKey);

    expect(find.byKey(CreateTripRouteScreen.stopFieldKey(1)), findsOneWidget);
    expect(find.text('Точка посадки'), findsNWidgets(2));

    await tester.enterText(
      find.byKey(CreateTripRouteScreen.stopFieldKey(1)),
      'Клин',
    );
    await tester.pump();

    expect(
      container.read(tripDraftProvider).intermediateStops.single.address,
      'Клин',
    );

    await _tap(tester, CreateTripRouteScreen.removeStopKey(1));

    expect(find.byKey(CreateTripRouteScreen.stopFieldKey(1)), findsNothing);
    expect(container.read(tripDraftProvider).points.length, 2);
  });

  testWidgets('keeps three route points in travel order', (tester) async {
    final container = await _pump(tester);

    await tester.enterText(
      find.byKey(CreateTripRouteScreen.originFieldKey),
      'Победителей 1, Минск',
    );
    await tester.enterText(
      find.byKey(CreateTripRouteScreen.destinationFieldKey),
      'Рынок местный, Могилев',
    );
    await tester.pump();
    await _tap(tester, CreateTripRouteScreen.addStopButtonKey);
    await tester.enterText(
      find.byKey(CreateTripRouteScreen.stopFieldKey(1)),
      'Комсомонавтов 13, Минск',
    );
    await tester.pump();

    expect(
      container.read(tripDraftProvider).points.map((p) => p.address).toList(),
      [
        'Победителей 1, Минск',
        'Комсомонавтов 13, Минск',
        'Рынок местный, Могилев',
      ],
    );
    expect(find.text('Точка посадки'), findsNWidgets(2));
    expect(find.text('Пункт назначения'), findsOneWidget);
    expect(find.byKey(CreateTripRouteScreen.removeStopKey(1)), findsOneWidget);
    expect(
      find.byKey(CreateTripRouteScreen.clearDestinationKey),
      findsOneWidget,
    );
  });

  testWidgets('the cross clears an endpoint instead of removing it', (
    tester,
  ) async {
    final container = await _pump(tester);

    expect(find.byKey(CreateTripRouteScreen.clearOriginKey), findsNothing);

    await tester.enterText(
      find.byKey(CreateTripRouteScreen.originFieldKey),
      'Победителей 1, Минск',
    );
    await tester.pump();

    await _tap(tester, CreateTripRouteScreen.clearOriginKey);

    expect(container.read(tripDraftProvider).origin.address, isEmpty);
    expect(container.read(tripDraftProvider).points.length, 2);
    expect(find.byKey(CreateTripRouteScreen.originFieldKey), findsOneWidget);
  });

  testWidgets('caps the seats at the vehicle capacity', (tester) async {
    final container = await _pump(tester);
    container
        .read(tripDraftProvider.notifier)
        .selectVehicle('preview_vehicle_rio');
    await tester.pump();

    for (var tap = 0; tap < 5; tap++) {
      await _tap(tester, CreateTripSeatCounter.increaseKey);
    }

    expect(container.read(tripDraftProvider).seatCount, 3);
  });
}
