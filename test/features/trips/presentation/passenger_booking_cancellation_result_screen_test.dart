import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/trips/domain/passenger_order.dart';
import 'package:vput/features/trips/presentation/passenger_booking_cancellation_result_screen.dart';

void main() {
  testWidgets('shows refund result after a normal cancellation', (
    tester,
  ) async {
    var done = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: PassengerBookingCancellationResultScreen(
          outcome: PassengerCancellationOutcome.refundRequested,
          refundAmountRubles: 1800,
          onDone: () => done++,
        ),
      ),
    );

    expect(find.text('Бронь отменена'), findsOneWidget);
    expect(find.textContaining('Заявка на возврат 1800 ₽'), findsOneWidget);

    await tester.tap(
      find.byKey(PassengerBookingCancellationResultScreen.doneButtonKey),
    );
    await tester.pump();

    expect(done, 1);
  });

  testWidgets('shows blocked result after reaching the cancellation limit', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PassengerBookingCancellationResultScreen(
          outcome: PassengerCancellationOutcome.bookingBlocked,
          onDone: () {},
        ),
      ),
    );

    expect(find.text('Бронирование временно\nнедоступно'), findsOneWidget);
    expect(
      find.byKey(PassengerBookingCancellationResultScreen.warningCardKey),
      findsOneWidget,
    );
    expect(find.text('Понятно'), findsOneWidget);
  });
}
