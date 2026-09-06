import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/trips/presentation/booking/passenger_booking_success_screen.dart';

void main() {
  testWidgets('shows successful seat booking result and exposes actions', (
    tester,
  ) async {
    var ordersOpened = 0;
    var chatOpened = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: PassengerBookingSuccessScreen(
          onOrders: () => ordersOpened++,
          onChatDriver: () => chatOpened++,
        ),
      ),
    );

    expect(find.text('Место забронировано'), findsOneWidget);
    expect(
      find.textContaining('Детали маршрута и данные водителя доступны'),
      findsOneWidget,
    );
    expect(find.text('Мои поездки'), findsOneWidget);
    expect(find.text('Написать водителю'), findsOneWidget);

    await tester.tap(find.byKey(PassengerBookingSuccessScreen.ordersButtonKey));
    await tester.pump();
    await tester.tap(find.byKey(PassengerBookingSuccessScreen.chatButtonKey));
    await tester.pump();

    expect(ordersOpened, 1);
    expect(chatOpened, 1);
  });
}
