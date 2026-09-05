import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/features/city/application/city_catalog_provider.dart';
import 'package:vput/features/city/domain/city_option.dart';
import 'package:vput/features/city/presentation/city_selection_screen.dart';

class CitySelectionPage extends ConsumerWidget {
  const CitySelectionPage({required this.onContinue, super.key});

  final ValueChanged<CityOption> onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(cityCatalogProvider);

    return catalog.when(
      data: (cities) =>
          CitySelectionScreen(cities: cities, onContinue: onContinue),
      loading: () => const _CatalogLoadingScreen(),
      error: (error, stackTrace) => _CatalogErrorScreen(
        onRetry: () => ref.invalidate(cityCatalogProvider),
      ),
    );
  }
}

class _CatalogLoadingScreen extends StatelessWidget {
  const _CatalogLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.brandGreen),
      ),
    );
  }
}

class _CatalogErrorScreen extends StatelessWidget {
  const _CatalogErrorScreen({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Не удалось загрузить список городов',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Повторить'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
