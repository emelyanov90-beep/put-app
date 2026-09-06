import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/core/api/pocketbase_provider.dart';
import 'package:vput/core/config/app_config.dart';
import 'package:vput/features/auth/application/preview_session_controller.dart';
import 'package:vput/features/vehicles/data/pocketbase_driver_vehicle_repository.dart';
import 'package:vput/features/vehicles/domain/driver_vehicle.dart';
import 'package:vput/features/vehicles/domain/driver_vehicle_repository.dart';

/// Preview garage used until the vehicles backend is connected.
const previewDriverVehicles = <DriverVehicle>[
  DriverVehicle(
    id: 'preview_vehicle_largus',
    brand: 'LADA',
    model: 'Largus',
    plateNumber: 'А 777 АА 7',
    color: 'Белый',
    year: 2021,
    seatCount: 4,
    verificationStatus: VehicleVerificationStatus.approved,
    photoAsset: 'docs/imgs/car.png',
    hasRegistrationDocument: true,
  ),
  DriverVehicle(
    id: 'preview_vehicle_rio',
    brand: 'KIA',
    model: 'Rio',
    plateNumber: 'В 123 ВС 77',
    color: 'Серый',
    year: 2019,
    seatCount: 3,
    verificationStatus: VehicleVerificationStatus.approved,
    photoAsset: 'docs/imgs/car.png',
    hasRegistrationDocument: true,
  ),
  DriverVehicle(
    id: 'preview_vehicle_solaris',
    brand: 'Hyundai',
    model: 'Solaris',
    plateNumber: 'Е 456 ЕК 197',
    color: 'Синий',
    year: 2022,
    seatCount: 4,
    verificationStatus: VehicleVerificationStatus.pending,
    photoAsset: 'docs/imgs/car.png',
    hasRegistrationDocument: true,
  ),
];

class PreviewDriverVehicleRepository implements DriverVehicleRepository {
  const PreviewDriverVehicleRepository({this.vehicles = previewDriverVehicles});

  final List<DriverVehicle> vehicles;

  @override
  Future<List<DriverVehicle>> list() async => vehicles;

  @override
  DriverVehicle? findById(String id) {
    for (final vehicle in vehicles) {
      if (vehicle.id == id) return vehicle;
    }
    return null;
  }

  @override
  Future<DriverVehicle> create(DriverVehicle vehicle) async => vehicle;

  @override
  Future<void> remove(String id) async {}

  @override
  Future<DriverVehicle> replaceRegistrationDocument(
    DriverVehicle vehicle,
    List<int> bytes,
  ) async => vehicle.copyWith(
    hasRegistrationDocument: true,
    registrationDocumentBytes: Uint8List.fromList(bytes),
    verificationStatus: VehicleVerificationStatus.pending,
  );

  @override
  Future<DriverVehicle> update(DriverVehicle vehicle) async => vehicle;
}

final driverVehicleRepositoryProvider = Provider<DriverVehicleRepository>((
  ref,
) {
  ref.watch(currentSessionUserIdProvider);
  return AppConfig.isPreviewMode
      ? const PreviewDriverVehicleRepository()
      : PocketBaseDriverVehicleRepository(ref.watch(pocketBaseProvider));
});
