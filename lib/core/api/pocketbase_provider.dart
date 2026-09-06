import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:vput/core/config/app_config.dart';

const _authStorageKey = 'pocketbase_auth';
const _secureStorage = FlutterSecureStorage();

/// Thrown when a build has neither a backend URL nor the preview flag.
class BackendConfigurationException implements Exception {
  const BackendConfigurationException();
}

Future<PocketBase> createPocketBase() async {
  final initialAuth = await _secureStorage.read(key: _authStorageKey);
  final authStore = AsyncAuthStore(
    initial: initialAuth,
    save: (data) => _secureStorage.write(key: _authStorageKey, value: data),
    clear: () => _secureStorage.delete(key: _authStorageKey),
  );

  // PocketBase requires a URL even on the setup screen. This non-routable HTTPS
  // value is never intended to receive requests and avoids a localhost default.
  final baseUrl = AppConfig.hasPocketBaseUrl
      ? AppConfig.pocketBaseUrl
      : 'https://backend-not-configured.invalid';

  return PocketBase(baseUrl, authStore: authStore);
}

/// Builds the client once, off the first frame: reading the stored session from
/// secure storage must not delay the first paint.
final startupClientProvider = FutureProvider<PocketBase>((ref) {
  if (!AppConfig.isConfigured) {
    throw const BackendConfigurationException();
  }
  return createPocketBase().timeout(const Duration(seconds: 10));
});

/// The client every repository and controller talks to.
///
/// It resolves from [startupClientProvider] instead of being overridden in a
/// nested `ProviderScope`: a provider that is not itself overridden lives in
/// the root container, so a nested override never reached the controllers that
/// read this one, and they hit an uninitialised provider at the first request.
/// Tests still override this provider directly at the root of their container.
final pocketBaseProvider = Provider<PocketBase>((ref) {
  final client = ref.watch(startupClientProvider).value;
  if (client == null) {
    throw StateError('PocketBase client is not ready yet.');
  }
  return client;
});
