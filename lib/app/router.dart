import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vput/features/auth/data/preview_sms_code.dart';
import 'package:vput/features/auth/presentation/phone_auth_screen.dart';
import 'package:vput/features/auth/presentation/sms_code_screen.dart';
import 'package:vput/features/city/presentation/city_selection_page.dart';
import 'package:vput/features/foundation/presentation/pending_flow_screen.dart';
import 'package:vput/features/legal/data/legal_documents.dart';
import 'package:vput/features/legal/presentation/legal_document_screen.dart';
import 'package:vput/features/onboarding/application/onboarding_draft_controller.dart';
import 'package:vput/features/onboarding/presentation/onboarding_slide_one_screen.dart';
import 'package:vput/features/onboarding/presentation/onboarding_slide_three_screen.dart';
import 'package:vput/features/onboarding/presentation/onboarding_slide_two_screen.dart';
import 'package:vput/features/onboarding/presentation/welcome_screen.dart';

abstract final class AppRoutes {
  static const welcome = '/';
  static const onboardingSlideOne = '/onboarding/1';
  static const onboardingSlideTwo = '/onboarding/2';
  static const onboardingSlideThree = '/onboarding/3';
  static const city = '/city';
  static const phoneAuth = '/auth/phone';
  static const termsAcceptance = '/auth/phone/terms';
  static const termsOfService = '/legal/terms';
  static const privacyPolicy = '/legal/privacy';
  static const otpVerify = '/auth/otp';
  static const home = '/home';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => WelcomeScreen(
          onStart: () => context.go(AppRoutes.onboardingSlideOne),
          onSignIn: () => context.go(AppRoutes.phoneAuth),
        ),
      ),
      GoRoute(
        path: AppRoutes.onboardingSlideOne,
        builder: (context, state) => OnboardingSlideOneScreen(
          onContinue: () => context.go(AppRoutes.onboardingSlideTwo),
        ),
      ),
      GoRoute(
        path: AppRoutes.onboardingSlideTwo,
        builder: (context, state) => OnboardingSlideTwoScreen(
          onContinue: () => context.go(AppRoutes.onboardingSlideThree),
        ),
      ),
      GoRoute(
        path: AppRoutes.onboardingSlideThree,
        builder: (context, state) => OnboardingSlideThreeScreen(
          onDriverSelected: () {
            ref
                .read(onboardingDraftProvider.notifier)
                .selectRole(OnboardingRole.driver);
            context.go(AppRoutes.city);
          },
          onPassengerSelected: () {
            ref
                .read(onboardingDraftProvider.notifier)
                .selectRole(OnboardingRole.passenger);
            context.go(AppRoutes.city);
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.city,
        builder: (context, state) => CitySelectionPage(
          onContinue: (city) {
            ref
                .read(onboardingDraftProvider.notifier)
                .selectCity(id: city.id, name: city.name);
            context.go(AppRoutes.phoneAuth);
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.phoneAuth,
        builder: (context, state) => PhoneAuthScreen(
          onCodeRequested: (phone) =>
              context.push(AppRoutes.termsAcceptance, extra: phone),
          onOpenTermsOfService: () => context.push(AppRoutes.termsOfService),
          onOpenPrivacyPolicy: () => context.push(AppRoutes.privacyPolicy),
        ),
      ),
      GoRoute(
        path: AppRoutes.termsAcceptance,
        builder: (context, state) {
          final phone = state.extra! as String;
          return LegalDocumentScreen(
            title: 'Условия использования',
            sections: termsOfServiceSections,
            onBack: () => context.pop(),
            onAccept: () =>
                context.pushReplacement(AppRoutes.otpVerify, extra: phone),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.termsOfService,
        builder: (context, state) => LegalDocumentScreen(
          title: 'Условия использования',
          sections: termsOfServiceSections,
          onBack: () => context.pop(),
        ),
      ),
      GoRoute(
        path: AppRoutes.privacyPolicy,
        builder: (context, state) => LegalDocumentScreen(
          title: 'Политика конфиденциальности',
          sections: privacyPolicySections,
          onBack: () => context.pop(),
        ),
      ),
      GoRoute(
        path: AppRoutes.otpVerify,
        builder: (context, state) {
          final phone = state.extra! as String;
          return SmsCodeScreen(
            phone: phone,
            expectedCode: previewValidSmsCode,
            onVerified: () => context.go(AppRoutes.home),
            onBack: () => context.pop(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) =>
            const PendingFlowScreen(title: 'Главный экран'),
      ),
    ],
  );
});
