import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/app/app.dart';
import 'package:vput/app/theme/app_theme.dart';
import 'package:vput/core/api/pocketbase_provider.dart';
import 'package:vput/features/system/presentation/system_failure_view.dart';
import 'package:vput/features/system/presentation/system_loading_screen.dart';

export 'package:vput/core/api/pocketbase_provider.dart'
    show BackendConfigurationException, startupClientProvider;

/// Renders immediately, including when secure storage is slow or unavailable,
/// and hands over to the application once the client is ready.
///
/// The client is not injected through a nested `ProviderScope`: everything
/// reads it through [pocketBaseProvider], which resolves it in the root
/// container where the controllers live.
class ApplicationBootstrap extends ConsumerWidget {
  const ApplicationBootstrap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(startupClientProvider)
        .when(
          data: (_) => const VputApp(),
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
