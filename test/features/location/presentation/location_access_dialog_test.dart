import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/location/presentation/location_access_dialog.dart';

void main() {
  testWidgets('shows geolocation rationale and exposes both choices', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var allowTaps = 0;
    var skipTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LocationAccessDialog(
            onAllow: () async => allowTaps++,
            onSkip: () => skipTaps++,
          ),
        ),
      ),
    );

    expect(find.text('Доступ к геолокации'), findsOneWidget);
    expect(
      find.textContaining('проще найти подходящий вариант'),
      findsOneWidget,
    );
    expect(find.byKey(LocationAccessDialog.allowButtonKey), findsOneWidget);
    expect(find.byKey(LocationAccessDialog.skipButtonKey), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);

    await tester.tap(find.byKey(LocationAccessDialog.allowButtonKey));
    await tester.pump();
    await tester.tap(find.byKey(LocationAccessDialog.skipButtonKey));

    expect(allowTaps, 1);
    expect(skipTaps, 1);
    expect(tester.takeException(), isNull);
  });
}
