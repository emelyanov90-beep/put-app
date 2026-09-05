import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/onboarding/presentation/onboarding_slide_two_screen.dart';

void main() {
  testWidgets('keeps the Figma anchors on a 375x812 viewport', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(375, 812);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    var continueTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(375, 812),
            padding: EdgeInsets.only(top: 54, bottom: 21),
          ),
          child: OnboardingSlideTwoScreen(onContinue: () => continueTaps++),
        ),
      ),
    );

    final headerRect = tester.getRect(
      find.byKey(OnboardingSlideTwoScreen.headerKey),
    );
    final logoRect = tester.getRect(
      find.byKey(OnboardingSlideTwoScreen.logoKey),
    );
    final illustrationRect = tester.getRect(
      find.byKey(OnboardingSlideTwoScreen.illustrationKey),
    );
    final cardRect = tester.getRect(
      find.byKey(OnboardingSlideTwoScreen.cardKey),
    );

    expect(headerRect, const Rect.fromLTWH(0, 0, 375, 222));
    expect(logoRect, const Rect.fromLTWH(132, 60, 50, 50));
    expect(illustrationRect, const Rect.fromLTWH(0, 145, 375, 273));
    expect(cardRect.top, 457);
    expect(
      tester.getSize(find.byKey(OnboardingSlideTwoScreen.continueButtonKey)),
      const Size(343, 42),
    );

    await tester.tap(find.byKey(OnboardingSlideTwoScreen.continueButtonKey));
    expect(continueTaps, 1);
  });
}
