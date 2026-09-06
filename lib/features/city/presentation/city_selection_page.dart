import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/features/city/application/city_catalog_provider.dart';
import 'package:vput/features/city/domain/city_option.dart';
import 'package:vput/features/city/presentation/city_selection_screen.dart';
import 'package:vput/features/system/presentation/system_failure_view.dart';
import 'package:vput/features/system/presentation/system_loading_screen.dart';

class CitySelectionPage extends ConsumerWidget {
  const CitySelectionPage({required this.onContinue, super.key});

  final ValueChanged<CityOption> onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(cityCatalogProvider);

    return catalog.when(
      data: (cities) =>
          CitySelectionScreen(cities: cities, onContinue: onContinue),
      loading: () => const SystemLoadingScreen(),
      error: (error, stackTrace) => SystemFailureScreen(
        onRetry: () => ref.invalidate(cityCatalogProvider),
      ),
    );
  }
}
