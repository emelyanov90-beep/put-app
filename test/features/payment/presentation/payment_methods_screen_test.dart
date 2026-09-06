import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vput/features/payment/application/payment_methods_controller.dart';
import 'package:vput/features/payment/presentation/payment_methods_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('adds a card and keeps only its last four digits', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: PaymentMethodsScreen(onBack: () {})),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(PaymentMethodsScreen.addButtonKey));
    await tester.pumpAndSettle();

    final save = tester.widget<FilledButton>(
      find.byKey(PaymentMethodsScreen.saveButtonKey),
    );
    expect(save.onPressed, isNull, reason: 'an empty form cannot be saved');

    await tester.enterText(
      find.byKey(PaymentMethodsScreen.numberFieldKey),
      '4111111111111234',
    );
    await tester.enterText(
      find.byKey(PaymentMethodsScreen.expiryFieldKey),
      '12/29',
    );
    await tester.pump();
    await tester.tap(find.byKey(PaymentMethodsScreen.saveButtonKey));
    await tester.pumpAndSettle();

    final cards = container.read(paymentMethodsProvider).value!;
    expect(cards, hasLength(1));
    expect(cards.single.last4, '1234');
    expect(cards.single.isDefault, isTrue);
    // The full number never reaches storage.
    expect(cards.single.toJson().toString(), isNot(contains('4111111111111')));
    expect(find.text('Visa •••• •••• •••• 1234'), findsOneWidget);
  });
}
