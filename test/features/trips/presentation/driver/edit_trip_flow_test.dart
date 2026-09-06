import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/trips/application/driver_trips_controller.dart';
import 'package:vput/features/trips/application/trip_draft_controller.dart';
import 'package:vput/features/trips/domain/trip_draft.dart';
import 'package:vput/features/trips/domain/trip_route_point.dart';
import 'package:vput/features/trips/presentation/driver/create_trip_route_screen.dart';
import 'package:vput/features/trips/presentation/driver/edit_trip_pricing_screen.dart';

final _now = DateTime(2026, 6, 1, 9);

TripDraft _savedDraft() {
  return TripDraft(
    points: const [
      TripRoutePoint(address: 'Победителей 1, Минск'),
      TripRoutePoint(address: 'Комсомонавтов 13, Минск'),
      TripRoutePoint(address: 'Рынок местный, Могилев'),
    ],
    departureAt: DateTime(2026, 6, 4, 8),
    arrivalAt: DateTime(2026, 6, 4, 12),
    seatCount: 4,
    fullRoutePrice: 1200,
    segmentPrices: const [600, 600],
    minimumBoardingPrice: 300,
    vehicleId: 'preview_vehicle_largus',
  );
}

/// Opens a stored trip for editing, the way «Мои поездки» does.
ProviderContainer _editingContainer() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  final id = container
      .read(driverTripsProvider.notifier)
      .publish(_savedDraft(), now: DateTime(2026, 6, 1, 8));
  container.read(tripDraftProvider.notifier).load(_savedDraft());
  container.read(editedDriverTripProvider.notifier).select(id);
  return container;
}

Future<void> _pumpRouteStep(
  WidgetTester tester,
  ProviderContainer container, {
  VoidCallback? onSave,
  VoidCallback? onEditPricing,
  VoidCallback? onContinue,
}) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: CreateTripRouteScreen(
          now: _now,
          isEditing: true,
          onBack: () {},
          onContinue: onContinue ?? () {},
          onSave: onSave,
          onEditPricing: onEditPricing,
        ),
      ),
    ),
  );
}

VoidCallback? _saveAction(WidgetTester tester) {
  return tester
      .widget<OutlinedButton>(find.byKey(CreateTripRouteScreen.saveButtonKey))
      .onPressed;
}

void main() {
  testWidgets('«Сохранить» stays off until something is actually changed', (
    tester,
  ) async {
    var saves = 0;
    final container = _editingContainer();
    await _pumpRouteStep(tester, container, onSave: () => saves++);

    expect(find.text('Изменение заказа'), findsOneWidget);
    expect(find.text('Шаг 2 из 6'), findsOneWidget);
    expect(find.text('Далее'), findsOneWidget);
    expect(find.text('Победителей 1, Минск'), findsOneWidget);
    expect(_saveAction(tester), isNull);

    await tester.enterText(
      find.byKey(CreateTripRouteScreen.stopFieldKey(1)),
      'Комсомонавтов 15, Минск',
    );
    await tester.pump();

    expect(_saveAction(tester), isNotNull);

    await tester.tap(find.byKey(CreateTripRouteScreen.saveButtonKey));
    await tester.pump();

    expect(saves, 1);
  });

  testWidgets('removing a stop is a change the driver can save', (
    tester,
  ) async {
    final container = _editingContainer();
    await _pumpRouteStep(tester, container, onSave: () {});

    expect(container.read(tripDraftHasChangesProvider), isFalse);

    await tester.tap(find.byKey(CreateTripRouteScreen.removeStopKey(1)));
    await tester.pump();

    expect(container.read(tripDraftProvider).points, hasLength(2));
    expect(container.read(tripDraftHasChangesProvider), isTrue);
    expect(_saveAction(tester), isNotNull);
  });

  testWidgets('the fares open in «Изменение стоимости»', (tester) async {
    var pricingTaps = 0;
    final container = _editingContainer();
    await _pumpRouteStep(tester, container, onEditPricing: () => pricingTaps++);

    await tester.ensureVisible(
      find.byKey(CreateTripRouteScreen.editPricingButtonKey),
    );
    await tester.tap(find.byKey(CreateTripRouteScreen.editPricingButtonKey));
    await tester.pump();

    expect(pricingTaps, 1);
  });

  testWidgets('«Изменение стоимости» saves the new fares', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var saves = 0;
    final container = _editingContainer();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: EditTripPricingScreen(
            onBack: () {},
            onSave: () {
              saves++;
              final id = container.read(editedDriverTripProvider)!;
              container
                  .read(driverTripsProvider.notifier)
                  .updateTrip(id, container.read(tripDraftProvider));
            },
          ),
        ),
      ),
    );

    expect(find.text('Изменение стоимости'), findsOneWidget);
    expect(find.text('Между остановками'), findsOneWidget);
    expect(find.text('Стоимость посадки'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(EditTripPricingScreen.saveButtonKey))
          .onPressed,
      isNull,
      reason: 'nothing has changed yet',
    );

    await tester.enterText(
      find.byKey(EditTripPricingScreen.segmentFieldKey(0)),
      '700',
    );
    await tester.pump();

    expect(container.read(tripDraftProvider).segmentPrices, [700, 600]);

    await tester.tap(find.byKey(EditTripPricingScreen.saveButtonKey));
    await tester.pump();

    expect(saves, 1);
    // The trip keeps its published state after the edit.
    final stored = container.read(driverTripsProvider).single;
    expect(stored.isPublished, isTrue);
    expect(stored.draft.segmentPrices, [700, 600]);
    expect(container.read(tripDraftHasChangesProvider), isFalse);
  });
}
