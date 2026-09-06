import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/features/vehicles/data/preview_driver_vehicle_repository.dart';
import 'package:vput/features/vehicles/domain/driver_vehicle.dart';
import 'package:vput/features/vehicles/domain/driver_vehicle_repository.dart';

/// The driver garage: what «Мои автомобили» lists and what a trip can be
/// published on.
///
class DriverVehiclesController extends Notifier<List<DriverVehicle>> {
  var _nextId = 1;

  @override
  List<DriverVehicle> build() {
    final repository = ref.watch(driverVehicleRepositoryProvider);
    if (repository is PreviewDriverVehicleRepository) {
      return repository.vehicles;
    }
    unawaited(Future<void>.microtask(_load));
    return const [];
  }

  DriverVehicleRepository get _repository =>
      ref.read(driverVehicleRepositoryProvider);

  Future<void> _load() async {
    final vehicles = await _repository.list();
    if (ref.mounted) state = vehicles;
  }

  DriverVehicle? findById(String id) {
    for (final vehicle in state) {
      if (vehicle.id == id) return vehicle;
    }
    return null;
  }

  /// Adds a vehicle and returns its id. A car with its registration document
  /// goes on review, one without it stays a draft.
  Future<String> add(DriverVehicle vehicle) async {
    final pending = DriverVehicle(
      id: 'driver_vehicle_${_nextId++}',
      brand: vehicle.brand,
      model: vehicle.model,
      seatCount: vehicle.seatCount,
      verificationStatus: vehicle.hasRegistrationDocument
          ? VehicleVerificationStatus.pending
          : VehicleVerificationStatus.draft,
      transportType: vehicle.transportType,
      color: vehicle.color,
      year: vehicle.year,
      photoAsset: vehicle.photoAsset,
      photoBytes: vehicle.photoBytes,
      plateNumber: vehicle.plateNumber,
      hasRegistrationDocument: vehicle.hasRegistrationDocument,
      registrationDocumentBytes: vehicle.registrationDocumentBytes,
    );
    final created = await _repository.create(pending);
    if (!ref.mounted) return created.id;
    state = [...state, created];
    return created.id;
  }

  Future<void> update(DriverVehicle vehicle) async {
    final updated = await _repository.update(vehicle);
    if (!ref.mounted) return;
    state = [
      for (final item in state)
        if (item.id == updated.id) updated else item,
    ];
  }

  /// Replaces the registration certificate, which sends the car back to the
  /// administrator for a new check.
  Future<void> replaceRegistrationDocument(String id, Uint8List bytes) async {
    final vehicle = findById(id);
    if (vehicle == null) return;
    final updated = await _repository.replaceRegistrationDocument(
      vehicle,
      bytes,
    );
    if (!ref.mounted) return;
    state = [
      for (final item in state)
        if (item.id == id) updated else item,
    ];
  }

  Future<void> remove(String id) async {
    await _repository.remove(id);
    if (!ref.mounted) return;
    state = [
      for (final vehicle in state)
        if (vehicle.id != id) vehicle,
    ];
  }
}

final driverVehiclesProvider =
    NotifierProvider<DriverVehiclesController, List<DriverVehicle>>(
      DriverVehiclesController.new,
    );

/// Vehicles that passed verification — the only ones a trip may run on.
final approvedDriverVehiclesProvider = Provider<List<DriverVehicle>>((ref) {
  return [
    for (final vehicle in ref.watch(driverVehiclesProvider))
      if (vehicle.isApproved) vehicle,
  ];
});
