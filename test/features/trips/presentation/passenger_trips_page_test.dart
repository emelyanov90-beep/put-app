import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/location/data/device_location_permission_service.dart';
import 'package:vput/features/location/domain/location_permission_service.dart';
import 'package:vput/features/location/presentation/location_access_dialog.dart';
import 'package:vput/features/trips/presentation/passenger_trips_page.dart';

void main() {
  testWidgets('requests native permission only after explicit consent', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = _FakeLocationPermissionService();
    final container = ProviderContainer(
      overrides: [locationPermissionServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: PassengerTripsPage(
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

    expect(find.byType(LocationAccessDialog), findsOneWidget);
    expect(service.requestCount, 0);

    await tester.tap(find.byKey(LocationAccessDialog.allowButtonKey));
    await tester.pumpAndSettle();

    expect(service.requestCount, 1);
    expect(find.byType(LocationAccessDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _FakeLocationPermissionService implements LocationPermissionService {
  var requestCount = 0;

  @override
  Future<AppLocationPermission> requestWhenInUse() async {
    requestCount++;
    return AppLocationPermission.granted;
  }
}
