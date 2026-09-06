import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/city/application/city_catalog_provider.dart';
import 'package:vput/features/city/domain/city_option.dart';
import 'package:vput/features/city/domain/city_repository.dart';
import 'package:vput/features/city/presentation/city_selection_page.dart';
import 'package:vput/features/city/presentation/city_selection_screen.dart';
import 'package:vput/features/system/data/device_connectivity_service.dart';
import 'package:vput/features/system/domain/connectivity_service.dart';
import 'package:vput/features/system/presentation/system_failure_view.dart';
import 'package:vput/features/system/presentation/system_loading_screen.dart';

class _PendingCityRepository implements CityRepository {
  @override
  Future<List<CityOption>> getCities() => Completer<List<CityOption>>().future;
}

/// Fails the first call, then succeeds — so a retry can be observed.
class _FlakyCityRepository implements CityRepository {
  int calls = 0;

  @override
  Future<List<CityOption>> getCities() async {
    calls++;
    if (calls == 1) throw Exception('network down');
    return const [
      CityOption(
        id: 'ru_city_1',
        name: 'Абаза',
        region: 'Хакасия',
        countryCode: 'RU',
        latitude: 52.65,
        longitude: 90.09,
      ),
    ];
  }
}

class _OfflineConnectivityService implements ConnectivityService {
  @override
  Future<bool> hasConnection() async => false;

  @override
  Stream<bool> watchConnection() => Stream.value(false);
}

void main() {
  testWidgets('shows the system loader while the catalog is loading', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cityRepositoryProvider.overrideWithValue(_PendingCityRepository()),
        ],
        child: MaterialApp(home: CitySelectionPage(onContinue: (_) {})),
      ),
    );

    expect(find.byType(SystemLoadingScreen), findsOneWidget);
    expect(find.byKey(SystemLoadingView.progressKey), findsOneWidget);
  });

  testWidgets('a failed catalog load offers a retry that reloads it', (
    tester,
  ) async {
    final repository = _FlakyCityRepository();
    // Riverpod retries failed providers on its own; disabling that here keeps
    // the assertions about the explicit "Обновить" action unambiguous.
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        cityRepositoryProvider.overrideWithValue(repository),
        connectivityServiceProvider.overrideWithValue(
          _OfflineConnectivityService(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: CitySelectionPage(onContinue: (_) {})),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(SystemFailureView.noInternetKey), findsOneWidget);
    expect(repository.calls, 1);

    await tester.tap(find.byKey(SystemFailureView.retryButtonKey));
    await tester.pumpAndSettle();

    expect(repository.calls, 2);
    expect(find.byType(CitySelectionScreen), findsOneWidget);
    expect(find.byKey(SystemFailureView.noInternetKey), findsNothing);
  });
}
