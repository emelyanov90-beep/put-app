import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/trips/application/trip_draft_controller.dart';
import 'package:vput/features/trips/domain/trip_route_point.dart';
import 'package:vput/features/trips/presentation/driver/create_trip_pricing_screen.dart';
import 'package:vput/features/trips/presentation/widgets/create_trip_controls.dart';

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  bool withStop = false,
  VoidCallback? onNext,
}) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer();
  addTearDown(container.dispose);
  final controller = container.read(tripDraftProvider.notifier);
  controller
    ..setOrigin(const TripRoutePoint(address: 'Победителей 1, Минск'))
    ..setDestination(const TripRoutePoint(address: 'Рынок местный, Могилев'));
  if (withStop) {
    controller.addStop(
      const TripRoutePoint(address: 'Комсомонавтов 13, Минск'),
    );
  }

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: CreateTripPricingScreen(
          onBack: () {},
          onContinue: onNext ?? () {},
        ),
      ),
    ),
  );
  return container;
}

VoidCallback? _primaryAction(WidgetTester tester) {
  return tester
      .widget<FilledButton>(find.byKey(CreateTripStepScaffold.primaryButtonKey))
      .onPressed;
}

void main() {
  testWidgets('asks for the fare of the whole route before the next step', (
    tester,
  ) async {
    var continues = 0;
    final container = await _pump(tester, onNext: () => continues++);

    expect(find.text('Шаг 3 из 6'), findsOneWidget);
    expect(find.text('Стоимость'), findsOneWidget);
    expect(find.text('Весь маршрут'), findsOneWidget);
    expect(find.text('Стоимость посадки'), findsOneWidget);
    expect(find.text('Между остановками'), findsNothing);
    expect(_primaryAction(tester), isNull);

    await tester.enterText(
      find.byKey(CreateTripPricingScreen.fullRouteFieldKey),
      '1200',
    );
    await tester.pump();

    expect(_primaryAction(tester), isNotNull);

    await tester.tap(find.byKey(CreateTripStepScaffold.primaryButtonKey));
    await tester.pump();

    expect(continues, 1);
    expect(container.read(tripDraftProvider).fullRoutePrice, 1200);
  });

  testWidgets('shows what the passenger pays and what the driver keeps', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.byKey(CreateTripPricingScreen.moneyBreakdownKey), findsNothing);

    await tester.enterText(
      find.byKey(CreateTripPricingScreen.fullRouteFieldKey),
      '1200',
    );
    await tester.pump();

    expect(
      find.byKey(CreateTripPricingScreen.moneyBreakdownKey),
      findsOneWidget,
    );
    // The driver names what they receive and the commission goes on top:
    // 1200 + 10 % = 1320 for the passenger.
    expect(find.text('Общая стоимость'), findsOneWidget);
    expect(find.text('1320 ₽'), findsOneWidget);
    expect(find.text('Комиссия 10 %'), findsOneWidget);
    expect(find.text('+120 ₽'), findsOneWidget);
    expect(find.text('Вы получите'), findsOneWidget);
    expect(find.text('1200 ₽'), findsOneWidget);
  });

  testWidgets('a stop adds a fare line for every leg, both optional', (
    tester,
  ) async {
    final container = await _pump(tester, withStop: true);

    expect(find.text('Между остановками'), findsOneWidget);
    expect(find.text('Комсомонавтов 13, Минск'), findsNWidgets(2));

    await tester.enterText(
      find.byKey(CreateTripPricingScreen.fullRouteFieldKey),
      '1200',
    );
    await tester.enterText(
      find.byKey(CreateTripPricingScreen.legFieldKey(0, 1)),
      '600',
    );
    await tester.pump();

    // The driver may move on with the other pairs still empty; each pair is
    // priced by hand, never derived from the ones around it.
    final draft = container.read(tripDraftProvider);
    expect(draft.fares.priceFor(0, 1), 600);
    expect(draft.fares.priceFor(1, 2), isNull);
    expect(draft.fullRoutePrice, 1200);
    expect(_primaryAction(tester), isNotNull);
  });

  testWidgets('a boarding price above the full fare blocks the step', (
    tester,
  ) async {
    await _pump(tester);

    await tester.enterText(
      find.byKey(CreateTripPricingScreen.fullRouteFieldKey),
      '1000',
    );
    await tester.enterText(
      find.byKey(CreateTripPricingScreen.minimumFieldKey),
      '1500',
    );
    await tester.pump();

    expect(_primaryAction(tester), isNull);
  });
}
