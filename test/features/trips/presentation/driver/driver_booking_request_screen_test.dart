import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/trips/domain/driver_trip.dart';
import 'package:vput/features/trips/domain/trip_draft.dart';
import 'package:vput/features/trips/domain/trip_route_point.dart';
import 'package:vput/features/trips/presentation/driver/driver_booking_request_screen.dart';

import '../../../../support/trip_fares.dart';

const _booking = DriverTripPassengerBooking(
  id: 'booking_1',
  passengerId: 'passenger_1',
  passengerName: 'Анастасия К.',
  passengerRating: 4.8,
  confirmed: false,
  pickupAddress: 'Улица Ленина, дом 5',
  dropoffAddress: 'Улица Пушкина, дом 10',
);

DriverTrip _trip({DriverTripPassengerBooking booking = _booking}) {
  return DriverTrip(
    id: 'trip_1',
    status: DriverTripStatus.published,
    publishedAt: DateTime(2026, 5, 14),
    passengerBookings: [booking],
    draft: TripDraft(
      points: const [
        TripRoutePoint(address: 'Улица Солнечная, дом 1'),
        TripRoutePoint(address: 'Улица Ленина, дом 5'),
        TripRoutePoint(address: 'Улица Пушкина, дом 10'),
        TripRoutePoint(address: 'Улица Лунная, дом 2'),
      ],
      departureAt: DateTime(2026, 5, 15, 8),
      arrivalAt: DateTime(2026, 5, 15, 18),
      seatCount: 24,
      fares: fares({
        [0, 3]: 600,
      }),
    ),
  );
}

Future<void> _pump(
  WidgetTester tester, {
  DriverTrip? trip,
  VoidCallback? onApprove,
  VoidCallback? onReject,
}) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer();
  addTearDown(container.dispose);
  final tripValue = trip ?? _trip();

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: DriverBookingRequestScreen(
          trip: tripValue,
          booking: tripValue.passengerBookings.first,
          onBack: () {},
          onApprove: onApprove ?? () {},
          onReject: onReject ?? () {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the money, both routes and the two answers', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Поездка'), findsOneWidget);
    expect(find.text('Стоимость'), findsOneWidget);
    expect(find.text('660 ₽'), findsOneWidget);
    expect(find.text('Комиссия 10 %'), findsOneWidget);
    expect(find.text('+60 ₽'), findsOneWidget);
    expect(find.text('К оплате водителю'), findsOneWidget);
    expect(find.text('600 ₽'), findsOneWidget);

    expect(find.text('Маршрут поездки'), findsOneWidget);
    expect(find.text('Улица Солнечная, дом 1'), findsOneWidget);
    expect(find.text('Улица Лунная, дом 2'), findsOneWidget);
    // Stops stay behind the chip until the driver opens them.
    expect(find.text('2 остановки'), findsOneWidget);

    expect(find.text('Маршрут пассажира'), findsOneWidget);
    expect(find.text('Точка посадки'), findsOneWidget);
    expect(find.text('Точка высадки'), findsOneWidget);
    expect(find.text('Улица Ленина, дом 5'), findsOneWidget);
    expect(find.text('Улица Пушкина, дом 10'), findsOneWidget);

    expect(find.text('15 мая, 08:00'), findsOneWidget);
    expect(find.text('10 из 24'), findsNothing);
    expect(find.text('24 из 24'), findsOneWidget);
    expect(find.text('Прибытие ~18:00'), findsOneWidget);
  });

  testWidgets('the chip opens the stops of the trip', (tester) async {
    await _pump(tester);

    await tester.tap(find.byKey(DriverBookingRequestScreen.stopsToggleKey));
    await tester.pumpAndSettle();

    // Each stop is now listed on its own, next to the passenger route.
    expect(find.text('Улица Ленина, дом 5'), findsNWidgets(2));
    expect(find.text('Улица Пушкина, дом 10'), findsNWidgets(2));
  });

  testWidgets('a passenger without their own points rides the whole route', (
    tester,
  ) async {
    await _pump(
      tester,
      trip: _trip(
        booking: const DriverTripPassengerBooking(
          id: 'booking_2',
          passengerId: 'passenger_2',
          passengerName: 'Виктор О.',
          passengerRating: 4.5,
          confirmed: false,
        ),
      ),
    );

    expect(find.text('Улица Солнечная, дом 1'), findsNWidgets(2));
    expect(find.text('Улица Лунная, дом 2'), findsNWidgets(2));
  });

  testWidgets('confirming and turning down are both one tap away', (
    tester,
  ) async {
    var approvals = 0;
    var rejections = 0;
    await _pump(
      tester,
      onApprove: () => approvals++,
      onReject: () => rejections++,
    );

    await tester.tap(find.byKey(DriverBookingRequestScreen.approveButtonKey));
    await tester.pump();
    await tester.tap(find.byKey(DriverBookingRequestScreen.rejectButtonKey));
    await tester.pump();

    expect(approvals, 1);
    expect(rejections, 1);
  });
}
