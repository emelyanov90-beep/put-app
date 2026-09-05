import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:vput/core/config/app_config.dart';

const _authStorageKey = 'pocketbase_auth';
const _secureStorage = FlutterSecureStorage();

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

final pocketBaseProvider = Provider<PocketBase>((ref) {
  throw StateError('pocketBaseProvider must be overridden in main().');
});
