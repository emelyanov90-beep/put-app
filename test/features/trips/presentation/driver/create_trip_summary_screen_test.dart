import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/trips/application/trip_draft_controller.dart';
import 'package:vput/features/trips/data/preview_trip_publication_settings.dart';
import 'package:vput/features/trips/domain/trip_publication_limits.dart';
import 'package:vput/features/trips/domain/trip_route_point.dart';
import 'package:vput/features/trips/presentation/driver/create_trip_summary_screen.dart';

final _now = DateTime(2026, 5, 15, 9);

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  bool complete = true,
  TripPublicationUsage? usage,
  VoidCallback? onPublish,
  VoidCallback? onSaveDraft,
}) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer(
    overrides: [
      if (usage != null) tripPublicationUsageProvider.overrideWithValue(usage),
    ],
  );
  addTearDown(container.dispose);
  final controller = container.read(tripDraftProvider.notifier);
  controller
    ..setOrigin(const TripRoutePoint(address: 'Москва'))
    ..setDestination(const TripRoutePoint(address: 'Тверь'));
  if (complete) {
    controller
      ..setDepartureAt(DateTime(2026, 5, 16, 9, 30))
      ..setArrivalTimeOfDay(hour: 18, minute: 0)
      ..setSeatCount(3)
      ..setFullRoutePrice(1800)
      ..setMinimumBoardingPrice(300)
      ..selectVehicle('preview_vehicle_largus');
  }

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: CreateTripSummaryScreen(
          now: _now,
          onBack: () {},
          onPublish: onPublish ?? () {},
          onSaveDraft: onSaveDraft ?? () {},
          onEditType: () {},
          onEditRoute: () {},
          onEditPricing: () {},
          onEditVehicle: () {},
          onEditServices: () {},
        ),
      ),
    ),
  );
  return container;
}

void main() {
  testWidgets('shows the trip and publishes it when everything is filled in', (
    tester,
  ) async {
    var publishes = 0;
    await _pump(tester, onPublish: () => publishes++);

    expect(find.text('Проверьте заказ'), findsOneWidget);
    expect(find.text('16 мая, 09:30'), findsOneWidget);
    expect(find.text('16 мая, 18:00'), findsOneWidget);
    // The order type row and the section title both read «Автомобиль».
    expect(find.text('Автомобиль'), findsNWidgets(2));
    expect(find.text('1800 ₽'), findsNWidgets(2));
    expect(find.text('Общая стоимость'), findsOneWidget);
    expect(find.text('Комиссия 10 %'), findsOneWidget);
    expect(find.text('+180 ₽'), findsOneWidget);
    expect(find.text('Вы получите'), findsOneWidget);
    expect(find.text('1980 ₽'), findsOneWidget);
    expect(find.text('LADA Largus · А 777 АА 7'), findsOneWidget);
    expect(find.text('Стандартное'), findsOneWidget);
    expect(
      find.text('Сегодня опубликовано 0 из 2 · за неделю 0 из 10'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(CreateTripSummaryScreen.publishButtonKey));
    await tester.pump();

    expect(publishes, 1);
  });

  testWidgets('an unfinished trip cannot be published but can be saved', (
    tester,
  ) async {
    var saves = 0;
    await _pump(tester, complete: false, onSaveDraft: () => saves++);

    expect(
      find.text(
        'Заполните: дату и время, количество мест, стоимость, автомобиль.',
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(CreateTripSummaryScreen.publishButtonKey),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.byKey(CreateTripSummaryScreen.saveDraftButtonKey));
    await tester.pump();

    expect(saves, 1);
  });

  testWidgets('the daily publication limit blocks publishing', (tester) async {
    await _pump(
      tester,
      usage: const TripPublicationUsage(
        publishedToday: 2,
        publishedThisWeek: 5,
      ),
    );

    expect(find.byKey(CreateTripSummaryScreen.limitNoticeKey), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(CreateTripSummaryScreen.publishButtonKey),
          )
          .onPressed,
      isNull,
    );
  });
}
