import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/vehicles/application/driver_vehicles_controller.dart';
import 'package:vput/features/vehicles/data/preview_driver_vehicle_repository.dart';
import 'package:vput/features/vehicles/domain/driver_vehicle.dart';

const _newVehicle = DriverVehicle(
  id: 'new',
  brand: 'Toyota',
  model: 'Camry',
  plateNumber: '7841HX-7',
  seatCount: 4,
  verificationStatus: VehicleVerificationStatus.draft,
);

ProviderContainer _container() {
  final container = ProviderContainer(
    overrides: [
      driverVehicleRepositoryProvider.overrideWithValue(
        const PreviewDriverVehicleRepository(vehicles: []),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('DriverVehiclesController', () {
    test('a car without its document is added as a draft', () async {
      final container = _container();

      final id = await container
          .read(driverVehiclesProvider.notifier)
          .add(_newVehicle);

      final vehicle = container.read(driverVehiclesProvider).single;
      expect(vehicle.id, id);
      expect(vehicle.verificationStatus, VehicleVerificationStatus.draft);
      expect(container.read(approvedDriverVehiclesProvider), isEmpty);
    });

    test('a car with its document goes straight on review', () async {
      final container = _container();

      await container
          .read(driverVehiclesProvider.notifier)
          .add(_newVehicle.copyWith(hasRegistrationDocument: true));

      expect(
        container.read(driverVehiclesProvider).single.verificationStatus,
        VehicleVerificationStatus.pending,
      );
    });

    test('uploading the document sends the car for a check', () async {
      final container = _container();
      final controller = container.read(driverVehiclesProvider.notifier);
      final id = await controller.add(_newVehicle);

      await controller.replaceRegistrationDocument(
        id,
        Uint8List.fromList([1, 2, 3]),
      );

      final vehicle = container.read(driverVehiclesProvider).single;
      expect(vehicle.hasRegistrationDocument, isTrue);
      expect(vehicle.verificationStatus, VehicleVerificationStatus.pending);
    });

    test('only verified cars are offered for a trip', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final approved = container.read(approvedDriverVehiclesProvider);

      expect(approved, hasLength(2));
      expect(approved.every((vehicle) => vehicle.isApproved), isTrue);
    });

    test('removing a car takes it out of the garage', () async {
      final container = _container();
      final controller = container.read(driverVehiclesProvider.notifier);
      final id = await controller.add(_newVehicle);

      await controller.remove(id);

      expect(container.read(driverVehiclesProvider), isEmpty);
    });
  });
}
