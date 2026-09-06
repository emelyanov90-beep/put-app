import 'package:flutter_test/flutter_test.dart';
import 'package:vput/core/config/app_config.dart';

void main() {
  test('an app without backend configuration does not enter preview', () {
    AppConfig.disablePreviewModeForTests();
    addTearDown(AppConfig.enablePreviewModeForTests);

    expect(AppConfig.hasPocketBaseUrl, isFalse);
    expect(AppConfig.isPreviewMode, isFalse);
    expect(AppConfig.isConfigured, isFalse);
  });
}
