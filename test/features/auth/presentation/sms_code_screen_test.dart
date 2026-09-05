import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/auth/presentation/sms_code_screen.dart';

void main() {
  Future<void> enterCode(
    WidgetTester tester,
    String code, {
    int from = 0,
  }) async {
    for (var i = 0; i < code.length; i++) {
      await tester.enterText(find.byType(TextField).at(from + i), code[i]);
      await tester.pump();
    }
  }

  testWidgets('disables submit until 6 digits are entered, then verifies', (
    tester,
  ) async {
    var verifiedTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: SmsCodeScreen(
          phone: '+7 912 345 67 89',
          expectedCode: '111111',
          onVerified: () => verifiedTaps++,
          onBack: () {},
        ),
      ),
    );

    FilledButton submitButton() =>
        tester.widget(find.byKey(SmsCodeScreen.submitButtonKey));

    expect(submitButton().onPressed, isNull);
    expect(find.textContaining('+7 912 345 67 89'), findsOneWidget);

    await enterCode(tester, '11111');
    expect(submitButton().onPressed, isNull);

    await enterCode(tester, '1', from: 5);
    expect(submitButton().onPressed, isNotNull);

    await tester.tap(find.byKey(SmsCodeScreen.submitButtonKey));
    expect(verifiedTaps, 1);
  });

  testWidgets(
    'shows an error banner for a wrong code and blocks resubmission',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SmsCodeScreen(
            phone: '+7 912 345 67 89',
            expectedCode: '111111',
            onVerified: () {},
            onBack: () {},
          ),
        ),
      );

      await enterCode(tester, '133229');
      await tester.tap(find.byKey(SmsCodeScreen.submitButtonKey));
      await tester.pump();

      expect(find.byKey(SmsCodeScreen.errorBannerKey), findsOneWidget);
      final submitButton = tester.widget<FilledButton>(
        find.byKey(SmsCodeScreen.submitButtonKey),
      );
      expect(submitButton.onPressed, isNull);

      await tester.enterText(find.byType(TextField).first, '9');
      await tester.pump();

      expect(find.byKey(SmsCodeScreen.errorBannerKey), findsNothing);
    },
  );

  testWidgets('switches to a resend link once the countdown finishes', (
    tester,
  ) async {
    var resendTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: SmsCodeScreen(
          phone: '+7 912 345 67 89',
          expectedCode: '111111',
          onVerified: () {},
          onBack: () {},
          onResend: () => resendTaps++,
        ),
      ),
    );

    expect(find.textContaining('0:59'), findsOneWidget);
    expect(find.byKey(SmsCodeScreen.resendButtonKey), findsNothing);

    await enterCode(tester, '3779');
    await tester.pump(const Duration(seconds: 59));

    expect(find.byKey(SmsCodeScreen.resendButtonKey), findsOneWidget);

    await tester.tap(find.byKey(SmsCodeScreen.resendButtonKey));
    await tester.pump();

    expect(resendTaps, 1);
    expect(find.textContaining('0:59'), findsOneWidget);
    for (var i = 0; i < 4; i++) {
      expect(
        tester.widget<TextField>(find.byType(TextField).at(i)).controller!.text,
        isEmpty,
      );
    }
  });
}
