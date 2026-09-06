import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/app/widgets/screen_header.dart';
import 'package:vput/features/onboarding/application/onboarding_draft_controller.dart';
import 'package:vput/features/profile/presentation/role_switch_screen.dart';

void main() {
  testWidgets('reflects the current role and reports the tapped selection', (
    tester,
  ) async {
    OnboardingRole? selected;
    var backTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: RoleSwitchScreen(
          currentRole: OnboardingRole.passenger,
          onRoleSelected: (role) => selected = role,
          onBack: () => backTaps++,
        ),
      ),
    );

    Icon driverIcon() => tester.widget(
      find.descendant(
        of: find.byKey(RoleSwitchScreen.driverOptionKey),
        matching: find.byType(Icon),
      ),
    );
    Icon passengerIcon() => tester.widget(
      find.descendant(
        of: find.byKey(RoleSwitchScreen.passengerOptionKey),
        matching: find.byType(Icon),
      ),
    );

    expect(passengerIcon().icon, Icons.radio_button_checked_rounded);
    expect(driverIcon().icon, Icons.radio_button_off_rounded);

    await tester.tap(find.byKey(RoleSwitchScreen.driverOptionKey));
    expect(selected, OnboardingRole.driver);

    await tester.tap(find.byKey(ScreenHeader.backButtonKey));
    expect(backTaps, 1);
  });
}
