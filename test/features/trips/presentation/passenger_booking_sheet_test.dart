import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/trips/data/preview_trip_catalog_repository.dart';
import 'package:vput/features/trips/domain/passenger_booking_request.dart';
import 'package:vput/features/trips/domain/passenger_trip.dart';
import 'package:vput/features/trips/presentation/booking/passenger_booking_sheet.dart';

void main() {
  testWidgets('builds a passenger booking request from selected options', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    PassengerBookingRequest? booking;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                booking = await showModalBottomSheet<PassengerBookingRequest>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) =>
                      PassengerBookingSheet(trip: previewPassengerTrips[1]),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byKey(PassengerBookingSheet.sheetKey), findsOneWidget);
    expect(find.text('Откликнуться на заказ'), findsOneWidget);
    expect(find.text('Точка отправления'), findsOneWidget);
    expect(find.text('Конечная точка'), findsOneWidget);
    expect(find.text('Доп. услуги'), findsOneWidget);
    expect(find.text('Пассажиров'), findsOneWidget);

    await tester.tap(
      find.byKey(PassengerBookingSheet.extraKey(TripExtraService.luggage)),
    );
    await tester.tap(find.byKey(PassengerBookingSheet.passengerPlusKey));
    await tester.pump();

    expect(find.text('1'), findsWidgets);

    await tester.ensureVisible(
      find.byKey(PassengerBookingSheet.submitButtonKey),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(PassengerBookingSheet.submitButtonKey));
    await tester.pumpAndSettle();

    expect(booking, isNotNull);
    expect(booking?.selectedExtras, contains(TripExtraService.luggage));
    expect(booking?.seatCount, 1);
    expect(booking?.pickupIndex, 0);
    expect(booking?.dropoffIndex, 1);
    expect(booking?.amountRubles, 1350);
    expect(booking?.awaitsDriver, isTrue);
    expect(tester.takeException(), isNull);
  });
}
