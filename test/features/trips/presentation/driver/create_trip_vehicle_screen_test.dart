import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/trips/application/trip_draft_controller.dart';
import 'package:vput/features/trips/presentation/driver/create_trip_vehicle_screen.dart';
import 'package:vput/features/trips/presentation/widgets/create_trip_controls.dart';
import 'package:vput/features/trips/presentation/widgets/driver_vehicle_picker.dart';
import 'package:vput/features/trips/presentation/widgets/trip_money_breakdown_card.dart';
import 'package:vput/features/vehicles/data/preview_driver_vehicle_repository.dart';
import 'package:vput/features/vehicles/domain/driver_vehicle_repository.dart';

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  DriverVehicleRepository? repository,
  VoidCallback? onNext,
  VoidCallback? onAddVehicle,
  int fullRoutePrice = 1200,
}) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer(
    overrides: [
      if (repository != null)
        driverVehicleRepositoryProvider.overrideWithValue(repository),
    ],
  );
  addTearDown(container.dispose);
  container.read(tripDraftProvider.notifier).setFullRoutePrice(fullRoutePrice);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: CreateTripVehicleScreen(
          onBack: () {},
          onContinue: onNext ?? () {},
          onAddVehicle: onAddVehicle ?? () {},
        ),
      ),
    ),
  );
  return container;
}

VoidCallback? _primaryAction(WidgetTester tester) {
  return tester
      .widget<FilledButton>(find.byKey(CreateTripStepScaffold.primaryButtonKey))
      .onPressed;
}

void main() {
  testWidgets('repeats the money split and unlocks after a car is chosen', (
    tester,
  ) async {
    var continues = 0;
    final container = await _pump(tester, onNext: () => continues++);

    expect(find.text('Шаг 4 из 6'), findsOneWidget);
    expect(find.byKey(TripMoneyBreakdownCard.cardKey), findsOneWidget);
    expect(find.text('Общая стоимость'), findsOneWidget);
    expect(find.text('1320 ₽'), findsOneWidget);
    expect(find.text('+120 ₽'), findsOneWidget);
    expect(find.text('Вы получите'), findsOneWidget);
    expect(find.text('1200 ₽'), findsOneWidget);
    expect(_primaryAction(tester), isNull);

    await tester.tap(
      find.byKey(DriverVehiclePicker.vehicleKey('preview_vehicle_largus')),
    );
    await tester.pump();

    expect(
      container.read(tripDraftProvider).vehicleId,
      'preview_vehicle_largus',
    );
    expect(_primaryAction(tester), isNotNull);

    await tester.tap(find.byKey(CreateTripStepScaffold.primaryButtonKey));
    await tester.pump();

    expect(continues, 1);
  });

  testWidgets('lists only cars that passed verification', (tester) async {
    await _pump(tester);

    expect(find.text('LADA Largus'), findsOneWidget);
    expect(find.text('KIA Rio'), findsOneWidget);
    expect(find.text('Hyundai Solaris'), findsNothing);
    expect(find.text('А 777 АА 7 • 4 места'), findsOneWidget);
  });

  testWidgets('an empty garage explains what to do and offers to add a car', (
    tester,
  ) async {
    var addTaps = 0;
    await _pump(
      tester,
      repository: const PreviewDriverVehicleRepository(vehicles: []),
      onAddVehicle: () => addTaps++,
    );

    expect(find.byKey(DriverVehiclePicker.emptyStateKey), findsOneWidget);
    expect(find.text('Нет добавленных авто'), findsOneWidget);
    expect(
      find.text(
        'Чтобы создать поездку, добавьте автомобиль и пришлите СТС на '
        'проверку администратору',
      ),
      findsOneWidget,
    );
    expect(_primaryAction(tester), isNull);

    await tester.tap(find.byKey(DriverVehiclePicker.addVehicleButtonKey));
    await tester.pump();

    expect(addTaps, 1);
  });
}
