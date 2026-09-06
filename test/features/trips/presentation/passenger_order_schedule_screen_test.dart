import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/trips/application/passenger_order_draft_controller.dart';
import 'package:vput/features/trips/presentation/passenger_order_schedule_screen.dart';

void main() {
  testWidgets('fills date, time and passenger count for a new order', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    var continued = 0;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: PassengerOrderScheduleScreen(
            now: DateTime(2026, 6),
            onBack: () {},
            onContinue: () => continued++,
          ),
        ),
      ),
    );

    expect(find.text('Новый заказ'), findsOneWidget);
    expect(find.text('Шаг 2 из 4'), findsOneWidget);
    expect(find.text('Маршрут'), findsOneWidget);
    expect(find.text('Победителей 1, Минск'), findsOneWidget);
    expect(find.text('Количество мест:'), findsOneWidget);

    var continueButton = tester.widget<FilledButton>(
      find.byKey(PassengerOrderScheduleScreen.continueButtonKey),
    );
    expect(continueButton.onPressed, isNull);

    await tester.tap(find.byKey(PassengerOrderScheduleScreen.dateFieldKey));
    await tester.pumpAndSettle();
    expect(find.byKey(PassengerOrderDatePickerSheet.sheetKey), findsOneWidget);

    await tester.tap(
      find.byKey(PassengerOrderDatePickerSheet.dayKey(DateTime(2026, 6, 4))),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(PassengerOrderDatePickerSheet.confirmButtonKey),
    );
    await tester.pumpAndSettle();

    expect(find.text('04.06.2026'), findsOneWidget);
    expect(find.text('8:00'), findsOneWidget);

    await tester.tap(
      find.byKey(PassengerOrderScheduleScreen.departureTimeFieldKey),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(PassengerOrderTimePickerSheet.sheetKey), findsOneWidget);
    await tester.tap(
      find.byKey(PassengerOrderTimePickerSheet.confirmButtonKey),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(PassengerOrderScheduleScreen.arrivalTimeFieldKey),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(PassengerOrderScheduleScreen.arrivalTimeFieldKey),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(PassengerOrderTimePickerSheet.sheetKey), findsOneWidget);
    await tester.tap(
      find.byKey(PassengerOrderTimePickerSheet.confirmButtonKey),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(PassengerOrderScheduleScreen.passengerIncreaseKey),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(PassengerOrderScheduleScreen.passengerIncreaseKey),
    );
    await tester.pump();

    expect(find.text('2'), findsOneWidget);

    final draft = container.read(passengerOrderDraftProvider);
    expect(draft.departureAt, DateTime(2026, 6, 4, 8));
    expect(draft.arrivalAt, DateTime(2026, 6, 5, 8));
    expect(draft.passengerCount, 2);
    expect(draft.canContinue(now: DateTime(2026, 6)), isTrue);

    continueButton = tester.widget<FilledButton>(
      find.byKey(PassengerOrderScheduleScreen.continueButtonKey),
    );
    expect(continueButton.onPressed, isNotNull);

    await tester.tap(
      find.byKey(PassengerOrderScheduleScreen.continueButtonKey),
    );
    await tester.pump();

    expect(continued, 1);
  });
}
