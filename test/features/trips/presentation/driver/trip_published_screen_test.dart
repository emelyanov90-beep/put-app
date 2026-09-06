import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/trips/data/preview_trip_publication_settings.dart';
import 'package:vput/features/trips/domain/trip_publication_limits.dart';
import 'package:vput/features/trips/presentation/driver/trip_published_screen.dart';

void main() {
  testWidgets('confirms the publication and shows what is left of the limits', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer(
      overrides: [
        tripPublicationUsageProvider.overrideWithValue(
          const TripPublicationUsage(publishedToday: 2, publishedThisWeek: 3),
        ),
      ],
    );
    addTearDown(container.dispose);
    var myTripsTaps = 0;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: TripPublishedScreen(onMyTrips: () => myTripsTaps++),
        ),
      ),
    );

    expect(find.text('Заказ опубликован!'), findsOneWidget);
    expect(
      find.text('Пассажиры уже видят ваш заказ. Ждём отклик!'),
      findsOneWidget,
    );
    expect(find.byKey(TripPublishedScreen.limitsCardKey), findsOneWidget);
    expect(find.text('Лимит публикаций'), findsOneWidget);
    expect(find.text('Сегодня'), findsOneWidget);
    expect(find.text('2 / 2'), findsOneWidget);
    expect(find.text('На неделе'), findsOneWidget);
    expect(find.text('3 / 10'), findsOneWidget);

    await tester.tap(find.byKey(TripPublishedScreen.myTripsButtonKey));
    await tester.pump();

    expect(myTripsTaps, 1);
  });
}
