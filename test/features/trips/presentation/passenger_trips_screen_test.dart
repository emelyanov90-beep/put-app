import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/trips/application/passenger_trip_search_controller.dart';
import 'package:vput/features/trips/data/preview_trip_catalog_repository.dart';
import 'package:vput/features/trips/domain/passenger_trip.dart';
import 'package:vput/features/trips/domain/trip_catalog_repository.dart';
import 'package:vput/features/trips/presentation/address_search_sheet.dart';
import 'package:vput/features/trips/presentation/passenger_trips_screen.dart';
import 'package:vput/features/trips/presentation/trip_filters_sheet.dart';
import 'package:vput/features/trips/presentation/widgets/passenger_bottom_bar.dart';

void main() {
  testWidgets('shows the car empty state and switches transport tabs', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        tripCatalogRepositoryProvider.overrideWithValue(
          const _EmptyTripCatalogRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: PassengerTripsScreen(
            onOrders: () {},
            onCreate: () {},
            onChats: () {},
            onProfile: () {},
            onTripSelected: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Поездки'), findsOneWidget);
    expect(find.byKey(PassengerTripsScreen.emptyStateKey), findsOneWidget);
    expect(find.byKey(PassengerTripsScreen.emptyImageKey), findsOneWidget);
    expect(find.text('Здесь ещё нет заказов'), findsOneWidget);
    expect(
      container.read(passengerTripSearchProvider).transportType,
      PassengerTransportType.car,
    );

    await tester.tap(find.byKey(PassengerTripsScreen.busTabKey));
    await tester.pump();

    expect(
      container.read(passengerTripSearchProvider).transportType,
      PassengerTransportType.bus,
    );
    expect(find.byKey(PassengerTripsScreen.emptyStateKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('exposes filter and bottom navigation actions', (tester) async {
    var orderTaps = 0;
    var createTaps = 0;
    var chatTaps = 0;
    var profileTaps = 0;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: PassengerTripsScreen(
            onOrders: () => orderTaps++,
            onCreate: () => createTaps++,
            onChats: () => chatTaps++,
            onProfile: () => profileTaps++,
            onTripSelected: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(PassengerBottomBar.ordersButtonKey));
    await tester.tap(find.byKey(PassengerBottomBar.createButtonKey));
    await tester.tap(find.byKey(PassengerBottomBar.chatsButtonKey));
    await tester.tap(find.byKey(PassengerBottomBar.profileButtonKey));

    expect(orderTaps, 1);
    expect(createTaps, 1);
    expect(chatTaps, 1);
    expect(profileTaps, 1);
  });

  testWidgets('shows ranked trip cards and opens the selected trip', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    PassengerTrip? selectedTrip;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: PassengerTripsScreen(
            onOrders: () {},
            onCreate: () {},
            onChats: () {},
            onProfile: () {},
            onTripSelected: (trip) => selectedTrip = trip,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Виктор О.'), findsOneWidget);
    expect(find.text('Топ'), findsOneWidget);
    expect(
      find.byKey(PassengerTripsScreen.registrationStatusKey),
      findsOneWidget,
    );
    expect(find.text('Идёт регистрация пассажиров'), findsOneWidget);
    expect(
      find.byKey(
        PassengerTripsScreen.tripCardKey(previewPassengerTrips.first.id),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(
        PassengerTripsScreen.tripCardKey(previewPassengerTrips.first.id),
      ),
    );

    expect(selectedTrip?.id, previewPassengerTrips.first.id);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens the modal filter sheet and applies route filters', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: PassengerTripsScreen(
            onOrders: () {},
            onCreate: () {},
            onChats: () {},
            onProfile: () {},
            onTripSelected: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(PassengerTripsScreen.filterButtonKey));
    await tester.pumpAndSettle();

    expect(find.byKey(TripFiltersSheet.sheetKey), findsOneWidget);
    expect(find.text('Фильтры'), findsOneWidget);
    expect(find.text('Откуда'), findsOneWidget);
    expect(find.text('Куда'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(TripFiltersSheet.applyButtonKey))
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.byKey(TripFiltersSheet.originFieldKey));
    await tester.pumpAndSettle();
    expect(find.byKey(AddressSearchSheet.sheetKey), findsOneWidget);

    await tester.enterText(
      find.byKey(AddressSearchSheet.queryFieldKey),
      'Солнечная, дом 5',
    );
    await tester.pump();
    await tester.tap(find.byKey(AddressSearchSheet.suggestionKey(0)));
    await tester.pumpAndSettle();

    expect(find.byKey(AddressSearchSheet.sheetKey), findsNothing);
    expect(find.text('Улица Солнечная, дом 5'), findsWidgets);

    await tester.tap(find.byKey(TripFiltersSheet.destinationFieldKey));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(AddressSearchSheet.queryFieldKey),
      'Мечты',
    );
    await tester.pump();
    await tester.tap(find.byKey(AddressSearchSheet.suggestionKey(0)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(TripFiltersSheet.applyButtonKey));
    await tester.pumpAndSettle();

    expect(find.byKey(TripFiltersSheet.sheetKey), findsNothing);
    expect(find.text('Александр П.'), findsOneWidget);
    expect(find.text('Виктор О.'), findsNothing);
    expect(container.read(passengerTripSearchProvider).hasFilters, isTrue);

    await tester.tap(find.byKey(PassengerTripsScreen.filterButtonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(TripFiltersSheet.clearButtonKey));
    await tester.pump();

    expect(container.read(passengerTripSearchProvider).hasFilters, isFalse);
    expect(find.byKey(TripFiltersSheet.sheetKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows active filter badge when filters return no trips', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: PassengerTripsScreen(
            onOrders: () {},
            onCreate: () {},
            onChats: () {},
            onProfile: () {},
            onTripSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.byKey(PassengerTripsScreen.filterActiveBadgeKey), findsNothing);

    await tester.tap(find.byKey(PassengerTripsScreen.filterButtonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(TripFiltersSheet.originFieldKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AddressSearchSheet.suggestionKey(0)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(TripFiltersSheet.applyButtonKey));
    await tester.pumpAndSettle();

    expect(container.read(passengerTripSearchProvider).hasFilters, isTrue);
    expect(find.byKey(PassengerTripsScreen.emptyStateKey), findsOneWidget);
    expect(
      find.byKey(PassengerTripsScreen.filterActiveBadgeKey),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

class _EmptyTripCatalogRepository implements TripCatalogRepository {
  const _EmptyTripCatalogRepository();

  @override
  PassengerTrip? findById(String id) => null;

  @override
  Future<List<PassengerTrip>> search(
    PassengerTransportType transportType,
  ) async => const [];
}
