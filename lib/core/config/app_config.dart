import 'package:flutter/foundation.dart';

abstract final class AppConfig {
  static const pocketBaseUrl = String.fromEnvironment('PB_BASE_URL');
  static const _compiledPreviewMode = bool.fromEnvironment('PREVIEW_MODE');
  static bool _testPreviewMode = false;

  static bool get hasPocketBaseUrl => pocketBaseUrl.trim().isNotEmpty;

  /// Demo data is available only in an explicitly preview build. Widget tests
  /// enable it through [enablePreviewModeForTests]. A normal app build without
  /// `PB_BASE_URL` is intentionally treated as misconfigured.
  static bool get isPreviewMode =>
      !hasPocketBaseUrl && (_compiledPreviewMode || _testPreviewMode);

  static bool get isConfigured => hasPocketBaseUrl || isPreviewMode;

  @visibleForTesting
  static void enablePreviewModeForTests() => _testPreviewMode = true;

  @visibleForTesting
  static void disablePreviewModeForTests() => _testPreviewMode = false;
}
