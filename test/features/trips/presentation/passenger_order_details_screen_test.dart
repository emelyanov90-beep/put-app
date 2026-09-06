import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/trips/data/preview_passenger_orders.dart';
import 'package:vput/features/trips/domain/passenger_order.dart';
import 'package:vput/features/trips/presentation/passenger_order_details_screen.dart';

Widget _details({
  required PassengerOrder order,
  ValueChanged<PassengerCancellationOutcome>? onCancellationCompleted,
  VoidCallback? onChatDriver,
}) {
  return MaterialApp(
    home: PassengerOrderDetailsScreen(
      order: order,
      onBack: () {},
      onDriver: () {},
      onCancellationCompleted: onCancellationCompleted ?? (_) {},
      onChatDriver: onChatDriver ?? () {},
    ),
  );
}

void main() {
  testWidgets('shows passenger order details and exposes chat action', (
    tester,
  ) async {
    var chats = 0;
    await tester.pumpWidget(
      _details(
        order: previewPassengerOrders.first,
        onChatDriver: () => chats++,
      ),
    );

    expect(find.text('Поездка'), findsOneWidget);
    expect(
      find.byKey(PassengerOrderDetailsScreen.routeCardKey),
      findsOneWidget,
    );
    expect(find.text('Улица Солнечная, дом 1'), findsOneWidget);
    expect(find.text('Улица Ленина, дом 5'), findsOneWidget);
    expect(find.text('10 из 24'), findsOneWidget);
    expect(find.text('С посылкой • S, M • 2 из 3'), findsOneWidget);
    expect(find.text('Виктор О.'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(PassengerOrderDetailsScreen.chatButtonKey),
    );
    await tester.tap(find.byKey(PassengerOrderDetailsScreen.chatButtonKey));
    await tester.pump();

    expect(chats, 1);
  });

  testWidgets(
    'first cancellation asks for confirmation and requests a refund',
    (tester) async {
      PassengerCancellationOutcome? outcome;
      await tester.pumpWidget(
        _details(
          order: previewPassengerOrders.first,
          onCancellationCompleted: (value) => outcome = value,
        ),
      );

      await tester.ensureVisible(
        find.byKey(PassengerOrderDetailsScreen.cancelButtonKey),
      );
      await tester.tap(find.byKey(PassengerOrderDetailsScreen.cancelButtonKey));
      await tester.pumpAndSettle();

      expect(find.text('Отменить бронирование?'), findsOneWidget);
      expect(find.text('Заявка на mock-возврат'), findsOneWidget);
      expect(find.text('1800 ₽'), findsOneWidget);
      expect(find.text('0 / 2'), findsOneWidget);

      await tester.tap(
        find.byKey(PassengerOrderDetailsScreen.confirmCancelButtonKey),
      );
      await tester.pumpAndSettle();

      expect(outcome, PassengerCancellationOutcome.refundRequested);
    },
  );

  testWidgets(
    'second cancellation requires an extra warning and blocks booking',
    (tester) async {
      PassengerCancellationOutcome? outcome;
      await tester.pumpWidget(
        _details(
          order: previewPassengerOrders[1],
          onCancellationCompleted: (value) => outcome = value,
        ),
      );

      await tester.ensureVisible(
        find.byKey(PassengerOrderDetailsScreen.cancelButtonKey),
      );
      await tester.tap(find.byKey(PassengerOrderDetailsScreen.cancelButtonKey));
      await tester.pumpAndSettle();

      expect(find.text('Отменить бронирование?'), findsOneWidget);
      expect(find.text('1 / 2'), findsOneWidget);

      await tester.tap(
        find.byKey(PassengerOrderDetailsScreen.confirmCancelButtonKey),
      );
      await tester.pumpAndSettle();

      expect(find.text('Это может повлиять на ваш\nаккаунт'), findsOneWidget);

      await tester.tap(
        find.byKey(PassengerOrderDetailsScreen.confirmLimitCancelButtonKey),
      );
      await tester.pumpAndSettle();

      expect(outcome, PassengerCancellationOutcome.bookingBlocked);
    },
  );
}
