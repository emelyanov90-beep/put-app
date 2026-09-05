import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/onboarding/presentation/onboarding_slide_one_screen.dart';

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
          child: OnboardingSlideOneScreen(onContinue: () => continueTaps++),
        ),
      ),
    );

    final titleRect = tester.getRect(
      find.byKey(OnboardingSlideOneScreen.titleKey),
    );
    final illustrationRect = tester.getRect(
      find.byKey(OnboardingSlideOneScreen.illustrationKey),
    );
    final descriptionRect = tester.getRect(
      find.byKey(OnboardingSlideOneScreen.descriptionKey),
    );

    expect(titleRect.top, 79);
    expect(illustrationRect.top, 164);
    expect(illustrationRect.size, const Size(375, 290));
    expect(descriptionRect.top, greaterThanOrEqualTo(503));
    expect(tester.getSize(find.byType(FilledButton)).width, 343);

    await tester.tap(find.byKey(OnboardingSlideOneScreen.continueButtonKey));
    expect(continueTaps, 1);
  });
}
