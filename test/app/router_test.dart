import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/app/app.dart';
import 'package:vput/features/auth/presentation/phone_auth_screen.dart';
import 'package:vput/features/auth/presentation/sms_code_screen.dart';
import 'package:vput/features/city/application/city_catalog_provider.dart';
import 'package:vput/features/city/presentation/city_selection_screen.dart';
import 'package:vput/features/legal/presentation/legal_document_screen.dart';
import 'package:vput/features/onboarding/application/onboarding_draft_controller.dart';
import 'package:vput/features/onboarding/presentation/onboarding_slide_one_screen.dart';
import 'package:vput/features/onboarding/presentation/onboarding_slide_three_screen.dart';
import 'package:vput/features/onboarding/presentation/onboarding_slide_two_screen.dart';
import 'package:vput/features/onboarding/presentation/welcome_screen.dart';

void main() {
  testWidgets('welcome actions open the expected next flow', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const VputApp()),
    );
    await tester.runAsync(() => container.read(cityCatalogProvider.future));

    expect(find.byType(WelcomeScreen), findsOneWidget);

    await tester.tap(find.byKey(WelcomeScreen.startButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingSlideOneScreen), findsOneWidget);

    await tester.tap(find.byKey(OnboardingSlideOneScreen.continueButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingSlideTwoScreen), findsOneWidget);

    await tester.tap(find.byKey(OnboardingSlideTwoScreen.continueButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingSlideThreeScreen), findsOneWidget);

    await tester.tap(find.byKey(OnboardingSlideThreeScreen.driverButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(CitySelectionScreen), findsOneWidget);
    expect(container.read(onboardingDraftProvider).role, OnboardingRole.driver);

    await tester.tap(find.byKey(CitySelectionScreen.cityKey('ru_city_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CitySelectionScreen.continueButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(PhoneAuthScreen), findsOneWidget);
    expect(container.read(onboardingDraftProvider).cityId, 'ru_city_1');
    expect(container.read(onboardingDraftProvider).cityName, 'Абаза');

    await tester.enterText(find.byType(TextField), '912 345 67 89');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(PhoneAuthScreen.getCodeButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(LegalDocumentScreen), findsOneWidget);
    expect(find.text('Условия использования'), findsOneWidget);

    // The SMS code screen starts a periodic resend-countdown Timer, which
    // never "settles", so from here on we pump bounded durations instead of
    // pumpAndSettle.
    await tester.tap(find.byKey(LegalDocumentScreen.acceptButtonKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(SmsCodeScreen), findsOneWidget);

    const code = '111111';
    for (var i = 0; i < code.length; i++) {
      await tester.enterText(find.byType(TextField).at(i), code[i]);
      await tester.pump();
    }
    await tester.tap(find.byKey(SmsCodeScreen.submitButtonKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Главный экран'), findsNWidgets(2));
  });
}
