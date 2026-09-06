import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android manifest requests approximate and precise location access', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();

    expect(
      manifest,
      contains('android.permission.ACCESS_COARSE_LOCATION'),
      reason: 'Android needs coarse location to offer approximate access.',
    );
    expect(
      manifest,
      contains('android.permission.ACCESS_FINE_LOCATION'),
      reason: 'Android needs fine location to offer precise access.',
    );
    expect(
      manifest,
      isNot(contains('android.permission.ACCESS_BACKGROUND_LOCATION')),
      reason: 'Passenger search only asks for foreground location access.',
    );
  });
}
