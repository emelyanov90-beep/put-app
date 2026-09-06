import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/vehicles/application/driver_vehicles_controller.dart';
import 'package:vput/features/auth/application/preview_session_controller.dart';
import 'package:vput/features/vehicles/data/preview_driver_vehicle_repository.dart';
import 'package:vput/features/vehicles/domain/driver_vehicle.dart';
import 'package:vput/features/vehicles/domain/driver_vehicle_repository.dart';

const _newVehicle = DriverVehicle(
  id: 'new',
  brand: 'Toyota',
  model: 'Camry',
  plateNumber: '7841HX-7',
  seatCount: 4,
  verificationStatus: VehicleVerificationStatus.draft,
);

const _secondAccountVehicle = DriverVehicle(
  id: 'second-account-car',
  brand: 'Skoda',
  model: 'Rapid',
  plateNumber: 'А 001 АА 77',
  seatCount: 3,
  verificationStatus: VehicleVerificationStatus.approved,
);

class _ListVehicleRepository implements DriverVehicleRepository {
  const _ListVehicleRepository(this.result);

  final Future<List<DriverVehicle>> result;

  @override
  Future<List<DriverVehicle>> list() => result;

  @override
  DriverVehicle? findById(String id) => null;

  @override
  Future<DriverVehicle> create(DriverVehicle vehicle) =>
      throw UnimplementedError();

  @override
  Future<void> remove(String id) => throw UnimplementedError();

  @override
  Future<DriverVehicle> replaceRegistrationDocument(
    DriverVehicle vehicle,
    List<int> bytes,
  ) => throw UnimplementedError();

  @override
  Future<DriverVehicle> update(DriverVehicle vehicle) =>
      throw UnimplementedError();
}

class _AccountController extends Notifier<String?> {
  @override
  String? build() => 'first';

  void select(String value) => state = value;
}

final _accountProvider = NotifierProvider<_AccountController, String?>(
  _AccountController.new,
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

    test(
      "a late response from the previous account can't replace the garage",
      () async {
        final firstResponse = Completer<List<DriverVehicle>>();
        final container = ProviderContainer(
          overrides: [
            currentSessionUserIdProvider.overrideWith(
              (ref) => ref.watch(_accountProvider),
            ),
            driverVehicleRepositoryProvider.overrideWith((ref) {
              return ref.watch(_accountProvider) == 'first'
                  ? _ListVehicleRepository(firstResponse.future)
                  : _ListVehicleRepository(
                      Future.value(const [_secondAccountVehicle]),
                    );
            }),
          ],
        );
        addTearDown(container.dispose);

        expect(container.read(driverVehiclesProvider), isEmpty);
        container.read(_accountProvider.notifier).select('second');
        expect(container.read(driverVehiclesProvider), isEmpty);
        await pumpEventQueue();
        expect(container.read(driverVehiclesProvider), const [
          _secondAccountVehicle,
        ]);

        firstResponse.complete(const [_newVehicle]);
        await pumpEventQueue();
        expect(container.read(driverVehiclesProvider), const [
          _secondAccountVehicle,
        ]);
      },
    );
  });
}
