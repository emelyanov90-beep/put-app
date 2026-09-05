import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/onboarding/presentation/welcome_screen.dart';

void main() {
  testWidgets('matches the 375px welcome layout and handles both actions', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(375, 812);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    var startTaps = 0;
    var signInTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: WelcomeScreen(
          onStart: () => startTaps++,
          onSignIn: () => signInTaps++,
        ),
      ),
    );

    expect(find.text('Путь'), findsOneWidget);
    expect(find.text('Попутчики и посылки по вашему маршруту'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(WelcomeScreen.illustrationKey)),
      const Size(299, 299),
    );
    expect(tester.getSize(find.byType(FilledButton)).width, 343);
    expect(tester.getSize(find.byType(OutlinedButton)).width, 343);

    await tester.tap(find.byKey(WelcomeScreen.startButtonKey));
    await tester.tap(find.byKey(WelcomeScreen.signInButtonKey));

    expect(startTaps, 1);
    expect(signInTaps, 1);
  });
}
