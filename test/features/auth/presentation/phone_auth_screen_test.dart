import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/auth/presentation/phone_auth_screen.dart';

void main() {
  testWidgets('small screen with keyboard can scroll to submit', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    String? requested;
    await tester.pumpWidget(
      MaterialApp(
        home: PhoneAuthScreen(
          onCodeRequested: (phone) => requested = phone,
          onOpenTermsOfService: () {},
          onOpenPrivacyPolicy: () {},
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), '9123456789');
    await tester.pump();
    await tester.ensureVisible(find.byKey(PhoneAuthScreen.getCodeButtonKey));
    await tester.tap(find.byKey(PhoneAuthScreen.getCodeButtonKey));
    expect(requested, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('formats the phone number and enables the button once complete', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(375, 812);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    String? requestedPhone;

    await tester.pumpWidget(
      MaterialApp(
        home: PhoneAuthScreen(
          onCodeRequested: (phone) => requestedPhone = phone,
          onOpenTermsOfService: () {},
          onOpenPrivacyPolicy: () {},
        ),
      ),
    );

    FilledButton getCodeButton() =>
        tester.widget(find.byKey(PhoneAuthScreen.getCodeButtonKey));

    expect(getCodeButton().onPressed, isNull);

    await tester.enterText(find.byType(TextField), '9123456');
    await tester.pump();

    expect(find.text('+7 912 345 6'), findsOneWidget);
    expect(getCodeButton().onPressed, isNull);

    await tester.enterText(find.byType(TextField), '9123456789');
    await tester.pump();

    expect(find.text('+7 912 345 67 89'), findsOneWidget);
    expect(getCodeButton().onPressed, isNotNull);

    await tester.tap(find.byKey(PhoneAuthScreen.getCodeButtonKey));

    expect(requestedPhone, '+7 912 345 67 89');
  });

  testWidgets(
    'keeps the floated label visible after losing focus with a value',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PhoneAuthScreen(
            onCodeRequested: (_) {},
            onOpenTermsOfService: () {},
            onOpenPrivacyPolicy: () {},
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '9123456789');
      await tester.pump();

      expect(find.text('Номер телефона'), findsOneWidget);
      expect(find.text('+7 912 345 67 89'), findsOneWidget);

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(find.text('Номер телефона'), findsOneWidget);
      expect(find.text('+7 912 345 67 89'), findsOneWidget);
    },
  );

  testWidgets('opens the terms of service and privacy policy links', (
    tester,
  ) async {
    var termsTaps = 0;
    var privacyTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: PhoneAuthScreen(
          onCodeRequested: (_) {},
          onOpenTermsOfService: () => termsTaps++,
          onOpenPrivacyPolicy: () => privacyTaps++,
        ),
      ),
    );

    await tester.tapOnText(
      find.textRange.ofSubstring('условиями использования'),
    );
    expect(termsTaps, 1);
    expect(privacyTaps, 0);

    await tester.tapOnText(
      find.textRange.ofSubstring('политикой конфиденциальности'),
    );
    expect(termsTaps, 1);
    expect(privacyTaps, 1);
  });
}
