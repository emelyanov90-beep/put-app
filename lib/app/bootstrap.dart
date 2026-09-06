import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:vput/app/app.dart';
import 'package:vput/app/theme/app_theme.dart';
import 'package:vput/core/api/pocketbase_provider.dart';
import 'package:vput/core/config/app_config.dart';
import 'package:vput/features/auth/application/preview_session_controller.dart';
import 'package:vput/features/system/presentation/system_failure_view.dart';
import 'package:vput/features/system/presentation/system_loading_screen.dart';

/// Render immediately, including when secure storage is slow or unavailable.
final startupClientProvider = FutureProvider<PocketBase>((ref) {
  if (!AppConfig.isConfigured) {
    throw const BackendConfigurationException();
  }
  return createPocketBase().timeout(const Duration(seconds: 10));
});

class BackendConfigurationException implements Exception {
  const BackendConfigurationException();
}

class ApplicationBootstrap extends ConsumerWidget {
  const ApplicationBootstrap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(startupClientProvider)
        .when(
          data: (client) => ProviderScope(
            overrides: [
              pocketBaseProvider.overrideWithValue(client),
              initialAuthStateProvider.overrideWithValue(
                client.authStore.isValid,
              ),
              clearStoredAuthProvider.overrideWithValue(client.authStore.clear),
            ],
            child: const VputApp(),
          ),
          loading: () => MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(body: SafeArea(child: SystemLoadingView())),
          ),
          error: (_, _) => MaterialApp(
            theme: AppTheme.light,
            home: SystemFailureScreen(
              onRetry: () => ref.invalidate(startupClientProvider),
            ),
          ),
        );
  }
}
