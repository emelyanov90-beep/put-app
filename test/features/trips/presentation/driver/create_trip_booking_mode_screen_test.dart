import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/trips/application/trip_draft_controller.dart';
import 'package:vput/features/trips/data/preview_trip_publication_settings.dart';
import 'package:vput/features/trips/domain/trip_draft.dart';
import 'package:vput/features/trips/domain/trip_publication_limits.dart';
import 'package:vput/features/trips/domain/trip_route_point.dart';
import 'package:vput/features/trips/presentation/driver/create_trip_booking_mode_screen.dart';
import 'package:vput/features/trips/presentation/widgets/publication_limit_dialog.dart';

final _now = DateTime(2026, 5, 15, 9);

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  bool complete = true,
  TripPublicationUsage? usage,
  VoidCallback? onPublish,
  VoidCallback? onSaveTemplate,
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
    ..setOrigin(const TripRoutePoint(address: 'Минск'))
    ..setDestination(const TripRoutePoint(address: 'Могилев'));
  if (complete) {
    controller
      ..setDepartureAt(DateTime(2026, 5, 16, 9, 30))
      ..setArrivalTimeOfDay(hour: 14, minute: 0)
      ..setSeatCount(3)
      ..setFullRoutePrice(1200)
      ..selectVehicle('preview_vehicle_largus');
  }

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: CreateTripBookingModeScreen(
          now: _now,
          onBack: () {},
          onPublish: onPublish ?? () {},
          onSaveTemplate: onSaveTemplate ?? () {},
        ),
      ),
    ),
  );
  return container;
}

void main() {
  testWidgets('explains both booking types and publishes the trip', (
    tester,
  ) async {
    var publishes = 0;
    final container = await _pump(tester, onPublish: () => publishes++);

    expect(find.text('Шаг 6 из 6'), findsOneWidget);
    expect(find.text('Тип бронирования'), findsOneWidget);
    expect(
      find.text('Вы рассматриваете каждую заявку отдельно'),
      findsOneWidget,
    );
    expect(find.text('Можете перейти в профиль пассажира'), findsOneWidget);
    expect(find.text('Подходит для постоянных маршрутов'), findsOneWidget);
    expect(
      container.read(tripDraftProvider).bookingMode,
      TripBookingMode.standard,
    );

    await tester.tap(find.byKey(CreateTripBookingModeScreen.instantOptionKey));
    await tester.pump();

    expect(
      container.read(tripDraftProvider).bookingMode,
      TripBookingMode.instant,
    );

    await tester.tap(find.byKey(CreateTripBookingModeScreen.publishButtonKey));
    await tester.pump();

    expect(publishes, 1);
  });

  testWidgets('an unfinished trip can only be kept as a template', (
    tester,
  ) async {
    var templates = 0;
    await _pump(tester, complete: false, onSaveTemplate: () => templates++);

    expect(
      tester
          .widget<FilledButton>(
            find.byKey(CreateTripBookingModeScreen.publishButtonKey),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(
      find.byKey(CreateTripBookingModeScreen.saveTemplateButtonKey),
    );
    await tester.pump();

    expect(templates, 1);
  });

  testWidgets('the daily limit opens the dialog instead of publishing', (
    tester,
  ) async {
    var publishes = 0;
    var templates = 0;
    await _pump(
      tester,
      usage: const TripPublicationUsage(
        publishedToday: 2,
        publishedThisWeek: 5,
        publishedOutboundToday: 1,
        publishedReturnToday: 1,
      ),
      onPublish: () => publishes++,
      onSaveTemplate: () => templates++,
    );

    await tester.tap(find.byKey(CreateTripBookingModeScreen.publishButtonKey));
    await tester.pumpAndSettle();

    expect(find.byKey(PublicationLimitDialog.dialogKey), findsOneWidget);
    expect(find.text('Достигнут лимит на сегодня'), findsOneWidget);
    expect(
      find.text(
        'На легковой автомобиль можно опубликовать не более 1 поездки в сутки '
        'в двух направлениях (туда и обратно). Сегодня у вас уже '
        '2 публикации.',
      ),
      findsOneWidget,
    );
    expect(find.text('Туда'), findsOneWidget);
    expect(find.text('Обратно'), findsOneWidget);
    expect(find.text('1/ 1'), findsNWidgets(2));
    expect(publishes, 0);

    await tester.tap(find.byKey(PublicationLimitDialog.saveTemplateButtonKey));
    await tester.pumpAndSettle();

    expect(templates, 1);
    expect(publishes, 0);
  });

  testWidgets('cancelling the limit dialog leaves the trip unpublished', (
    tester,
  ) async {
    var publishes = 0;
    var templates = 0;
    await _pump(
      tester,
      usage: const TripPublicationUsage(
        publishedToday: 1,
        publishedThisWeek: 1,
        publishedOutboundToday: 1,
      ),
      onPublish: () => publishes++,
      onSaveTemplate: () => templates++,
    );

    await tester.tap(find.byKey(CreateTripBookingModeScreen.publishButtonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(PublicationLimitDialog.cancelButtonKey));
    await tester.pumpAndSettle();

    expect(find.byKey(PublicationLimitDialog.dialogKey), findsNothing);
    expect(publishes, 0);
    expect(templates, 0);
  });
}
