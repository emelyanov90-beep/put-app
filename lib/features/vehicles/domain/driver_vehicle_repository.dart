import 'package:vput/features/vehicles/domain/driver_vehicle.dart';

abstract interface class DriverVehicleRepository {
  /// Vehicles attached to the current driver account, in display order.
  Future<List<DriverVehicle>> list();

  DriverVehicle? findById(String id);

  Future<DriverVehicle> create(DriverVehicle vehicle);

  Future<DriverVehicle> update(DriverVehicle vehicle);

  Future<void> remove(String id);

  Future<DriverVehicle> replaceRegistrationDocument(
    DriverVehicle vehicle,
    List<int> bytes,
  );
}
