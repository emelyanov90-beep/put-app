abstract final class AppConfig {
  static const pocketBaseUrl = String.fromEnvironment('PB_BASE_URL');

  static bool get hasPocketBaseUrl => pocketBaseUrl.trim().isNotEmpty;
}
