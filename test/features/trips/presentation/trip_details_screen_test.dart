import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/app/widgets/screen_header.dart';
import 'package:vput/features/trips/data/preview_trip_catalog_repository.dart';
import 'package:vput/features/trips/domain/passenger_booking_request.dart';
import 'package:vput/features/trips/presentation/booking/passenger_booking_sheet.dart';
import 'package:vput/features/trips/domain/trip_extras.dart';
import 'package:vput/features/trips/presentation/booking/passenger_parcel_sheet.dart';
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
    PassengerParcelRequest? parcel;

    await tester.pumpWidget(
      MaterialApp(
        home: TripDetailsScreen(
          trip: previewPassengerTrips.first,
          onBack: () => backTaps++,
          onDriver: () {},
          onBookingSubmitted: (request) => booking = request,
          onParcelSubmitted: (request) => parcel = request,
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

    // «Отправить посылку» opens its own sheet instead of a pending stub.
    await tester.tap(find.byKey(TripDetailsScreen.sendParcelButtonKey));
    await tester.pumpAndSettle();
    expect(find.byKey(PassengerParcelSheet.sheetKey), findsOneWidget);

    final submit = tester.widget<FilledButton>(
      find.byKey(PassengerParcelSheet.submitButtonKey),
    );
    expect(submit.onPressed, isNull, reason: 'a size has to be picked first');

    await tester.tap(
      find.byKey(PassengerParcelSheet.sizeKey(ParcelSize.medium)),
    );
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(PassengerParcelSheet.submitButtonKey),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(PassengerParcelSheet.submitButtonKey));
    await tester.pumpAndSettle();

    expect(parcel, isNotNull);
    expect(parcel!.sizeCode, 'M');
    expect(parcel!.amountRubles, 250);
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
          onParcelSubmitted: (_) {},
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
