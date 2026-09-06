import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/app/widgets/screen_header.dart';
import 'package:vput/features/trips/data/preview_trip_catalog_repository.dart';
import 'package:vput/features/trips/domain/passenger_booking_request.dart';
import 'package:vput/features/trips/presentation/booking/passenger_booking_sheet.dart';
import 'package:vput/features/trips/presentation/trip_details_screen.dart';

void main() {
  testWidgets('shows no-seat details and keeps parcel action available', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var backTaps = 0;
    PassengerBookingRequest? booking;
    var parcelTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: TripDetailsScreen(
          trip: previewPassengerTrips.first,
          onBack: () => backTaps++,
          onDriver: () {},
          onBookingSubmitted: (request) => booking = request,
          onSendParcel: () => parcelTaps++,
        ),
      ),
    );

    expect(find.text('Поездка'), findsOneWidget);
    expect(find.byKey(TripDetailsScreen.routeCardKey), findsOneWidget);
    expect(find.text('Улица Солнечная, дом 1'), findsOneWidget);
    expect(find.text('Улица Лунная, дом 2'), findsOneWidget);
    expect(find.text('0 из 3'), findsOneWidget);
    expect(find.text('Мест нет'), findsOneWidget);
    expect(find.text('Отправить посылку'), findsOneWidget);

    final bookingButton = tester.widget<FilledButton>(
      find.byKey(TripDetailsScreen.bookSeatButtonKey),
    );
    expect(bookingButton.onPressed, isNull);

    await tester.tap(find.byKey(TripDetailsScreen.sendParcelButtonKey));
    expect(parcelTaps, 1);
    expect(booking, isNull);

    await tester.tap(find.byKey(ScreenHeader.backButtonKey));
    expect(backTaps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('enables booking when the selected trip has a free seat', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    PassengerBookingRequest? booking;

    await tester.pumpWidget(
      MaterialApp(
        home: TripDetailsScreen(
          trip: previewPassengerTrips[1],
          onBack: () {},
          onDriver: () {},
          onBookingSubmitted: (request) => booking = request,
          onSendParcel: () {},
        ),
      ),
    );

    expect(find.text('1 из 3'), findsOneWidget);
    expect(find.text('Забронировать место'), findsOneWidget);
    expect(find.text('150 ₽'), findsOneWidget);

    await tester.tap(find.byKey(TripDetailsScreen.bookSeatButtonKey));
    await tester.pumpAndSettle();
    expect(find.byKey(PassengerBookingSheet.sheetKey), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(PassengerBookingSheet.submitButtonKey),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(PassengerBookingSheet.submitButtonKey));
    await tester.pumpAndSettle();

    expect(booking, isNotNull);
    expect(booking?.tripId, previewPassengerTrips[1].id);
    expect(booking?.seatCount, 1);
    expect(booking?.status, PassengerBookingStatus.pendingDriver);
    expect(booking?.paymentStatus, PassengerPaymentStatus.unpaid);
    expect(tester.takeException(), isNull);
  });
}
