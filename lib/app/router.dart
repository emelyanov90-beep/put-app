import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vput/features/foundation/presentation/pending_flow_screen.dart';
import 'package:vput/features/onboarding/presentation/welcome_screen.dart';

abstract final class AppRoutes {
  static const welcome = '/';
  static const city = '/city';
  static const phoneAuth = '/auth/phone';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => WelcomeScreen(
          onStart: () => context.go(AppRoutes.city),
          onSignIn: () => context.go(AppRoutes.phoneAuth),
        ),
      ),
      GoRoute(
        path: AppRoutes.city,
        builder: (context, state) =>
            const PendingFlowScreen(title: 'Выбор города'),
      ),
      GoRoute(
        path: AppRoutes.phoneAuth,
        builder: (context, state) =>
            const PendingFlowScreen(title: 'Вход по номеру телефона'),
      ),
    ],
  );
});
