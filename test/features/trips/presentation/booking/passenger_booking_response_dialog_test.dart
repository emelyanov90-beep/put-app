import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/trips/presentation/booking/passenger_booking_response_dialog.dart';

void main() {
  testWidgets('returns payment action from the accepted booking dialog', (
    tester,
  ) async {
    PassengerBookingResponseAction? action;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                action = await showPassengerBookingAcceptedFlow(context);
              },
              child: const Text('show'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();

    expect(find.text('Водитель принял заявку'), findsOneWidget);
    expect(find.text('Перейти к оплате'), findsOneWidget);

    await tester.tap(find.byKey(PassengerBookingAcceptedDialog.payButtonKey));
    await tester.pumpAndSettle();

    expect(action, PassengerBookingResponseAction.pay);
  });

  testWidgets('opens the withdrawal confirmation and allows going back', (
    tester,
  ) async {
    PassengerBookingResponseAction? action;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                action = await showPassengerBookingAcceptedFlow(context);
              },
              child: const Text('show'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(PassengerBookingAcceptedDialog.withdrawButtonKey),
    );
    await tester.pumpAndSettle();

    expect(find.text('Отменить бронирование?'), findsOneWidget);
    expect(find.text('Водитель принял заявку'), findsNothing);

    await tester.tap(
      find.byKey(PassengerBookingWithdrawDialog.returnButtonKey),
    );
    await tester.pumpAndSettle();

    expect(find.text('Водитель принял заявку'), findsOneWidget);
    expect(action, isNull);

    await tester.tap(
      find.byKey(PassengerBookingAcceptedDialog.withdrawButtonKey),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(PassengerBookingWithdrawDialog.confirmButtonKey),
    );
    await tester.pumpAndSettle();

    expect(action, PassengerBookingResponseAction.withdrawRequest);
  });

  testWidgets('shows rejected booking dialog and closes it with ok', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showPassengerBookingRejectedDialog(context),
              child: const Text('show'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();

    expect(find.text('Водитель отклонил заявку'), findsOneWidget);
    expect(
      find.text(
        'К сожалению, водитель отклонил вашу заявку на поездку. '
        'Вы можете выбрать другую поездку или создать собственную.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(PassengerBookingRejectedDialog.okButtonKey));
    await tester.pumpAndSettle();

    expect(find.text('Водитель отклонил заявку'), findsNothing);
  });
}
