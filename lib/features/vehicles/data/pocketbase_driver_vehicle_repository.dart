import 'package:http/http.dart' as http;
import 'package:pocketbase/pocketbase.dart';
import 'package:vput/features/vehicles/domain/driver_vehicle.dart';
import 'package:vput/features/vehicles/domain/driver_vehicle_repository.dart';

class PocketBaseDriverVehicleRepository implements DriverVehicleRepository {
  PocketBaseDriverVehicleRepository(this._client);

  final PocketBase _client;
  final Map<String, DriverVehicle> _cache = {};

  @override
  Future<List<DriverVehicle>> list() async {
    final response = await _client.send<Map<String, dynamic>>(
      '/api/app/vehicles',
    );
    final items = response['items'];
    if (items is! List) throw const FormatException('Invalid vehicles list');
    final vehicles = items
        .whereType<Map>()
        .map((raw) => _fromJson(Map<String, dynamic>.from(raw)))
        .toList(growable: false);
    _cache
      ..clear()
      ..addEntries(vehicles.map((vehicle) => MapEntry(vehicle.id, vehicle)));
    return vehicles;
  }

  @override
  DriverVehicle? findById(String id) => _cache[id];

  @override
  Future<DriverVehicle> create(DriverVehicle vehicle) async {
    final record = await _client
        .collection('vehicles')
        .create(
          body: _body(vehicle)
            ..['owner_id'] = _client.authStore.record!.id
            ..['verification_status'] = 'draft',
          files: _files(vehicle),
        );
    var result = _fromRecord(record);
    if (vehicle.hasRegistrationDocument) result = await _submit(result.id);
    _cache[result.id] = result;
    return result;
  }

  @override
  Future<DriverVehicle> update(DriverVehicle vehicle) async {
    final record = await _client
        .collection('vehicles')
        .update(vehicle.id, body: _body(vehicle), files: _files(vehicle));
    var result = _fromRecord(record);
    if (vehicle.hasRegistrationDocument) result = await _submit(result.id);
    _cache[result.id] = result;
    return result;
  }

  @override
  Future<DriverVehicle> replaceRegistrationDocument(
    DriverVehicle vehicle,
    List<int> bytes,
  ) async {
    final record = await _client
        .collection('vehicles')
        .update(
          vehicle.id,
          files: [
            http.MultipartFile.fromBytes(
              'registration_document',
              bytes,
              filename: 'registration-document.jpg',
            ),
          ],
        );
    final updated = _fromRecord(record);
    final result = await _submit(updated.id);
    _cache[result.id] = result;
    return result;
  }

  @override
  Future<void> remove(String id) async {
    await _client.collection('vehicles').delete(id);
    _cache.remove(id);
  }

  Future<DriverVehicle> _submit(String id) async {
    final response = await _client.send<Map<String, dynamic>>(
      '/api/app/vehicles/$id/submit-verification',
      method: 'POST',
    );
    final raw = response['vehicle'];
    if (raw is! Map) throw const FormatException('Invalid vehicle response');
    return _fromJson(Map<String, dynamic>.from(raw));
  }

  Map<String, dynamic> _body(DriverVehicle vehicle) => {
    'transport_type': vehicle.transportType.name,
    'brand': vehicle.brand,
    'model': vehicle.model,
    'plate_number': vehicle.plateNumber,
    'color': vehicle.color ?? '',
    'year': vehicle.year ?? 0,
    'seat_count': vehicle.seatCount,
  };

  List<http.MultipartFile> _files(DriverVehicle vehicle) => [
    if (vehicle.photoBytes case final bytes?)
      http.MultipartFile.fromBytes('photo', bytes, filename: 'vehicle.jpg'),
    if (vehicle.registrationDocumentBytes case final bytes?)
      http.MultipartFile.fromBytes(
        'registration_document',
        bytes,
        filename: 'registration-document.jpg',
      ),
  ];

  DriverVehicle _fromRecord(RecordModel record) => _fromJson(record.toJson());

  DriverVehicle _fromJson(Map<String, dynamic> json) => DriverVehicle(
    id: json['id'] as String,
    brand: json['brand'] as String? ?? '',
    model: json['model'] as String? ?? '',
    plateNumber: json['plate_number'] as String? ?? '',
    color: json['color'] as String?,
    year: (json['year'] as num?)?.toInt(),
    seatCount: (json['seat_count'] as num?)?.toInt() ?? 1,
    verificationStatus: switch (json['verification_status']) {
      'pending' => VehicleVerificationStatus.pending,
      'approved' => VehicleVerificationStatus.approved,
      'rejected' => VehicleVerificationStatus.rejected,
      _ => VehicleVerificationStatus.draft,
    },
    transportType: json['transport_type'] == 'bus'
        ? VehicleTransportType.bus
        : VehicleTransportType.car,
    photoAsset: 'docs/imgs/car.png',
    hasRegistrationDocument:
        (json['registration_document'] as String? ?? '').isNotEmpty,
  );
}
