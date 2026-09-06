import 'dart:async';

import 'package:vput/core/config/app_config.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  AppConfig.enablePreviewModeForTests();
  await testMain();
}
