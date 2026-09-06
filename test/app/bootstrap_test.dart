import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:vput/app/bootstrap.dart';
import 'package:vput/features/onboarding/presentation/welcome_screen.dart';
import 'package:vput/features/system/application/connection_status_provider.dart';
import 'package:vput/features/system/presentation/system_loading_screen.dart';
import 'package:vput/features/system/presentation/system_failure_view.dart';

void main() {
  testWidgets(
    'renders a first frame while storage is pending then starts app',
    (tester) async {
      final pending = Completer<PocketBase>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            startupClientProvider.overrideWith((ref) => pending.future),
          ],
          child: const ApplicationBootstrap(),
        ),
      );
      expect(find.byType(SystemLoadingView), findsOneWidget);
      pending.complete(PocketBase('https://example.invalid'));
      await tester.pumpAndSettle();
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('storage error has retry and retry recovers', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isOnlineProvider.overrideWithValue(true),
          startupClientProvider.overrideWith((ref) async {
            if (++attempts == 1) throw StateError('storage unavailable');
            return PocketBase('https://example.invalid');
          }),
        ],
        child: const ApplicationBootstrap(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SystemFailureScreen), findsOneWidget);
    await tester.tap(find.byKey(SystemFailureView.retryButtonKey));
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(attempts, 2);
    expect(tester.takeException(), isNull);
  });
}
