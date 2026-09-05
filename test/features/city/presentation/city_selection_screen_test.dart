import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/city/data/asset_city_repository.dart';
import 'package:vput/features/city/domain/city_option.dart';
import 'package:vput/features/city/presentation/city_selection_screen.dart';

const testCities = <CityOption>[
  CityOption(
    id: 'abakan',
    name: 'Абакан',
    region: 'Хакасия',
    countryCode: 'RU',
    latitude: 53.72,
    longitude: 91.43,
  ),
  CityOption(
    id: 'moscow',
    name: 'Москва',
    region: 'Москва',
    countryCode: 'RU',
    latitude: 55.75,
    longitude: 37.62,
  ),
];

void main() {
  testWidgets('supports search, selection and confirmation', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(375, 812);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    CityOption? confirmedCity;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(375, 812),
            padding: EdgeInsets.only(top: 54, bottom: 21),
          ),
          child: CitySelectionScreen(
            cities: testCities,
            onContinue: (city) => confirmedCity = city,
          ),
        ),
      ),
    );

    expect(
      tester.getRect(find.byKey(CitySelectionScreen.headerKey)),
      const Rect.fromLTWH(0, 0, 375, 124),
    );
    expect(
      tester.getRect(find.byKey(CitySelectionScreen.searchBarKey)).top,
      188,
    );
    expect(
      tester.getRect(find.byKey(CitySelectionScreen.resultsPanelKey)).top,
      248,
    );
    expect(find.byKey(CitySelectionScreen.continueButtonKey), findsNothing);

    await tester.tap(find.byKey(CitySelectionScreen.searchFieldKey));
    await tester.enterText(
      find.byKey(CitySelectionScreen.searchFieldKey),
      'Москва',
    );
    await tester.pump();

    expect(find.byKey(CitySelectionScreen.clearSearchKey), findsOneWidget);
    expect(find.byKey(CitySelectionScreen.cityKey('moscow')), findsOneWidget);
    expect(find.byKey(CitySelectionScreen.cityKey('abakan')), findsNothing);

    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    await tester.tap(find.byKey(CitySelectionScreen.cityKey('moscow')));
    await tester.pumpAndSettle();

    expect(find.byKey(CitySelectionScreen.resultsPanelKey), findsNothing);
    expect(find.byKey(CitySelectionScreen.continueButtonKey), findsOneWidget);
    expect(
      tester.getSize(find.byKey(CitySelectionScreen.continueButtonKey)),
      const Size(343, 48),
    );

    await tester.tap(find.byKey(CitySelectionScreen.continueButtonKey));
    expect(confirmedCity?.id, 'moscow');
    expect(confirmedCity?.name, 'Москва');
  });

  testWidgets('shows the missing city state and clears a query', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CitySelectionScreen(cities: testCities, onContinue: (_) {}),
      ),
    );

    await tester.enterText(
      find.byKey(CitySelectionScreen.searchFieldKey),
      'Несуществующий город',
    );
    await tester.pump();

    expect(find.text('Моего города нет в списке'), findsOneWidget);

    await tester.tap(find.byKey(CitySelectionScreen.clearSearchKey));
    await tester.pump();

    expect(find.text('Абакан'), findsOneWidget);
    expect(find.byKey(CitySelectionScreen.clearSearchKey), findsNothing);
  });

  testWidgets('catalog includes cities after Moscow and the list scrolls', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(375, 812);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final cities = await tester.runAsync(
      () => AssetCityRepository().getCities(),
    );
    expect(cities, isNotNull);
    final catalog = cities!;
    expect(catalog, hasLength(1134));
    expect(catalog.map((city) => city.id).toSet(), hasLength(1134));
    expect(catalog[614].name, 'Москва');
    expect(catalog.last.name, 'Яхрома');
    final citiesAfterMoscow = catalog.sublist(614, 641);

    await tester.pumpWidget(
      MaterialApp(
        home: CitySelectionScreen(
          cities: citiesAfterMoscow,
          onContinue: (_) {},
        ),
      ),
    );

    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.text('Невинномысск'), findsOneWidget);
  });
}
