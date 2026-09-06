import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/trips/presentation/address_search_sheet.dart';

void main() {
  testWidgets('shows address suggestions and filters them by query', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AddressSearchSheet())),
    );

    expect(find.byKey(AddressSearchSheet.sheetKey), findsOneWidget);
    expect(find.byKey(AddressSearchSheet.queryFieldKey), findsOneWidget);
    expect(find.text('Моё местоположение'), findsOneWidget);
    expect(find.text('Московский, 56'), findsOneWidget);

    await tester.enterText(
      find.byKey(AddressSearchSheet.queryFieldKey),
      'Мечты',
    );
    await tester.pump();

    expect(find.text('Проспект Мечты, дом 12'), findsOneWidget);
    expect(find.text('Московский, 56'), findsNothing);

    await tester.enterText(
      find.byKey(AddressSearchSheet.queryFieldKey),
      'Несуществующая улица',
    );
    await tester.pump();

    expect(find.byKey(AddressSearchSheet.emptyStateKey), findsOneWidget);
    expect(find.text('Моё местоположение'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
