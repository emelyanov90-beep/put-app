import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/onboarding/presentation/onboarding_slide_three_screen.dart';

void main() {
  testWidgets('keeps the Figma anchors on a 375x812 viewport', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(375, 812);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    var driverTaps = 0;
    var passengerTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(375, 812),
            padding: EdgeInsets.only(top: 54, bottom: 21),
          ),
          child: OnboardingSlideThreeScreen(
            onDriverSelected: () => driverTaps++,
            onPassengerSelected: () => passengerTaps++,
          ),
        ),
      ),
    );

    expect(
      tester.getRect(find.byKey(OnboardingSlideThreeScreen.headerKey)),
      const Rect.fromLTWH(0, 0, 375, 222),
    );
    expect(
      tester.getRect(find.byKey(OnboardingSlideThreeScreen.logoKey)),
      const Rect.fromLTWH(132, 60, 50, 50),
    );
    expect(
      tester.getRect(find.byKey(OnboardingSlideThreeScreen.illustrationKey)),
      const Rect.fromLTWH(0, 143, 375, 274),
    );
    expect(
      tester.getRect(find.byKey(OnboardingSlideThreeScreen.cardKey)).top,
      455,
    );
    expect(
      tester.getSize(find.byKey(OnboardingSlideThreeScreen.driverButtonKey)),
      const Size(167, 132),
    );
    expect(
      tester.getSize(find.byKey(OnboardingSlideThreeScreen.passengerButtonKey)),
      const Size(167, 132),
    );

    await tester.tap(find.byKey(OnboardingSlideThreeScreen.driverButtonKey));
    await tester.tap(find.byKey(OnboardingSlideThreeScreen.passengerButtonKey));

    expect(driverTaps, 1);
    expect(passengerTaps, 1);
  });
}
