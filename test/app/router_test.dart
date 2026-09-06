import 'package:vput/features/auth/application/preview_session_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/app/app.dart';
import 'package:vput/app/router.dart';
import 'package:vput/features/auth/presentation/phone_auth_screen.dart';
import 'package:vput/features/auth/presentation/sms_code_screen.dart';
import 'package:vput/features/city/application/city_catalog_provider.dart';
import 'package:vput/features/city/presentation/city_selection_screen.dart';
import 'package:vput/features/legal/presentation/legal_document_screen.dart';
import 'package:vput/features/location/presentation/location_access_dialog.dart';
import 'package:vput/features/onboarding/application/onboarding_draft_controller.dart';
import 'package:vput/features/onboarding/presentation/onboarding_slide_one_screen.dart';
import 'package:vput/features/onboarding/presentation/onboarding_slide_three_screen.dart';
import 'package:vput/features/onboarding/presentation/onboarding_slide_two_screen.dart';
import 'package:vput/features/onboarding/presentation/welcome_screen.dart';
import 'package:vput/features/profile/presentation/create_profile_screen.dart';
import 'package:vput/features/profile/presentation/personal_data_screen.dart';
import 'package:vput/features/profile/presentation/profile_loading_screen.dart';
import 'package:vput/features/profile/presentation/profile_screen.dart';
import 'package:vput/features/profile/presentation/role_switch_screen.dart';
import 'package:vput/features/system/presentation/account_blocked_screen.dart';
import 'package:vput/features/trips/presentation/driver/create_trip_type_screen.dart';
import 'package:vput/features/trips/presentation/passenger_order_schedule_screen.dart';
import 'package:vput/features/trips/presentation/passenger_trips_screen.dart';
import 'package:vput/features/trips/presentation/trip_details_screen.dart';
import 'package:vput/features/trips/presentation/widgets/passenger_bottom_bar.dart';

void main() {
  testWidgets('new user completes registration before role and city', (
    tester,
  ) async {
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

    expect(find.byType(PhoneAuthScreen), findsOneWidget);
    expect(
      container.read(onboardingDraftProvider).authEntryMode,
      AuthEntryMode.registration,
    );

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

    expect(find.byType(CreateProfileScreen), findsOneWidget);

    await tester.enterText(
      find.byKey(CreateProfileScreen.nameFieldKey),
      'Анастасия',
    );
    await tester.pump();
    await tester.tap(find.byKey(CreateProfileScreen.continueButtonKey));
    await tester.pump();

    expect(find.byType(ProfileLoadingScreen), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();

    expect(find.byType(OnboardingSlideThreeScreen), findsOneWidget);

    await tester.tap(find.byKey(OnboardingSlideThreeScreen.driverButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(CitySelectionScreen), findsOneWidget);
    expect(container.read(onboardingDraftProvider).role, OnboardingRole.driver);

    await tester.tap(find.byKey(CitySelectionScreen.cityKey('ru_city_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CitySelectionScreen.continueButtonKey));
    await tester.pumpAndSettle();

    expect(container.read(onboardingDraftProvider).cityId, 'ru_city_1');
    expect(container.read(onboardingDraftProvider).cityName, 'Абаза');
    expect(find.byType(CreateTripTypeScreen), findsOneWidget);
    expect(find.text('Тип заказа'), findsOneWidget);
  });

  testWidgets('existing-account action skips onboarding and profile', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const VputApp()),
    );

    await tester.tap(find.byKey(WelcomeScreen.signInButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(PhoneAuthScreen), findsOneWidget);
    expect(
      container.read(onboardingDraftProvider).authEntryMode,
      AuthEntryMode.signIn,
    );

    await tester.enterText(find.byType(TextField), '912 345 67 89');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(PhoneAuthScreen.getCodeButtonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(LegalDocumentScreen.acceptButtonKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    const code = '111111';
    for (var i = 0; i < code.length; i++) {
      await tester.enterText(find.byType(TextField).at(i), code[i]);
      await tester.pump();
    }
    await tester.tap(find.byKey(SmsCodeScreen.submitButtonKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(CreateProfileScreen), findsNothing);
    expect(find.byType(PassengerTripsScreen), findsOneWidget);
  });

  testWidgets('a deactivated account is stopped right after the code check', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const VputApp()),
    );

    await tester.tap(find.byKey(WelcomeScreen.signInButtonKey));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '900 000 00 00');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(PhoneAuthScreen.getCodeButtonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(LegalDocumentScreen.acceptButtonKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    const code = '111111';
    for (var i = 0; i < code.length; i++) {
      await tester.enterText(find.byType(TextField).at(i), code[i]);
      await tester.pump();
    }
    await tester.tap(find.byKey(SmsCodeScreen.submitButtonKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(AccountBlockedScreen), findsOneWidget);
    expect(find.text('Ваш аккаунт заблокирован'), findsOneWidget);
    expect(find.text('Главный экран'), findsNothing);
    expect(find.byType(CreateProfileScreen), findsNothing);
  });

  testWidgets('passenger home opens the trip search screen', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(onboardingDraftProvider.notifier)
        .selectRole(OnboardingRole.passenger);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const VputApp()),
    );

    container.read(previewSessionProvider.notifier).signIn();
    container.read(routerProvider).go(AppRoutes.home);
    await tester.pumpAndSettle();

    expect(find.byType(PassengerTripsScreen), findsOneWidget);
    expect(find.text('Виктор О.'), findsOneWidget);
    expect(find.byType(LocationAccessDialog), findsOneWidget);

    await tester.tap(find.byKey(LocationAccessDialog.skipButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(LocationAccessDialog), findsNothing);

    await tester.tap(
      find.byKey(PassengerTripsScreen.tripCardKey('preview_trip_viktor')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TripDetailsScreen), findsOneWidget);
    expect(find.text('0 из 3'), findsOneWidget);
    expect(find.text('Мест нет'), findsOneWidget);
  });

  testWidgets('passenger create action opens a passenger order draft', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(onboardingDraftProvider.notifier)
        .selectRole(OnboardingRole.passenger);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const VputApp()),
    );

    container.read(previewSessionProvider.notifier).signIn();
    container.read(routerProvider).go(AppRoutes.orders);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(PassengerBottomBar.createButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(PassengerOrderScheduleScreen), findsOneWidget);
    expect(find.text('Шаг 2 из 4'), findsOneWidget);
  });

  testWidgets(
    'profile: editing personal data, switching role, and logging out',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(onboardingDraftProvider.notifier)
          .selectRole(OnboardingRole.passenger);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const VputApp()),
      );

      container.read(previewSessionProvider.notifier).signIn();
      container.read(routerProvider).go(AppRoutes.profile);
      await tester.pumpAndSettle();

      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text('Перейти в режим водителя'), findsOneWidget);

      await tester.tap(find.byKey(ProfileScreen.personalDataItemKey));
      await tester.pumpAndSettle();

      expect(find.byType(PersonalDataScreen), findsOneWidget);

      await tester.enterText(
        find.byKey(PersonalDataScreen.nameFieldKey),
        'Мария',
      );
      await tester.pump();
      await tester.tap(find.byKey(PersonalDataScreen.saveButtonKey));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text('Мария'), findsOneWidget);

      await tester.tap(find.byKey(ProfileScreen.switchRoleItemKey));
      await tester.pumpAndSettle();

      expect(find.byType(RoleSwitchScreen), findsOneWidget);

      await tester.tap(find.byKey(RoleSwitchScreen.driverOptionKey));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(
        container.read(onboardingDraftProvider).role,
        OnboardingRole.driver,
      );
      expect(find.text('Перейти в режим пассажира'), findsOneWidget);

      await tester.ensureVisible(find.byKey(ProfileScreen.logoutButtonKey));
      await tester.tap(find.byKey(ProfileScreen.logoutButtonKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ProfileScreen.logoutConfirmKey));
      await tester.pumpAndSettle();

      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(container.read(onboardingDraftProvider).role, isNull);
    },
  );
}
