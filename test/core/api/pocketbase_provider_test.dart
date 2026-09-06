import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:vput/core/api/pocketbase_provider.dart';
import 'package:vput/core/config/app_config.dart';
import 'package:vput/features/auth/application/preview_session_controller.dart';

void main() {
  setUp(AppConfig.disablePreviewModeForTests);
  tearDown(AppConfig.enablePreviewModeForTests);

  ProviderContainer containerWith(PocketBase client) {
    final container = ProviderContainer(
      overrides: [startupClientProvider.overrideWith((ref) async => client)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('the client resolves once startup finished', () async {
    final client = PocketBase('https://example.invalid');
    final container = containerWith(client);

    await container.read(startupClientProvider.future);

    expect(container.read(pocketBaseProvider), same(client));
  });

  test('reading the client before startup finished is an error', () {
    final container = containerWith(PocketBase('https://example.invalid'));

    // Riverpod wraps the error, so only the fact of failing is asserted.
    expect(() => container.read(pocketBaseProvider), throwsA(anything));
  });

  test('a controller in the root container reaches the client', () async {
    // Regression: the client used to be injected through a nested
    // `ProviderScope`. Controllers are not overridden, so they live in the root
    // container and never saw that override — the first request threw
    // «pocketBaseProvider must be overridden in main()» and the screen looked
    // like a dead button.
    final container = containerWith(PocketBase('https://example.invalid'));
    await container.read(startupClientProvider.future);

    await expectLater(
      container
          .read(previewSessionProvider.notifier)
          .requestCode('+79990000001'),
      throwsA(isA<AuthFailure>()),
    );
  });

  test('the restored session reaches the session controller', () async {
    final client = PocketBase('https://example.invalid');
    final container = containerWith(client);
    await container.read(startupClientProvider.future);

    expect(container.read(initialAuthStateProvider), client.authStore.isValid);
    expect(container.read(previewSessionProvider), client.authStore.isValid);
  });
}
