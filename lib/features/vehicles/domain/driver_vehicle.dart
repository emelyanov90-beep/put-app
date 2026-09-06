import 'package:flutter/foundation.dart';

/// Verification state of a vehicle (`vehicles.verification_status`).
/// Only [approved] vehicles may carry a published trip.
enum VehicleVerificationStatus { draft, pending, approved, rejected }

/// Kind of vehicle (`vehicles.transport_type`).
enum VehicleTransportType { car, bus }

/// Vehicle attached to the driver account, shown in «Мои автомобили».
@immutable
class DriverVehicle {
  const DriverVehicle({
    required this.id,
    required this.brand,
    required this.model,
    required this.seatCount,
    required this.verificationStatus,
    this.plateNumber = '',
    this.transportType = VehicleTransportType.car,
    this.color,
    this.year,
    this.photoAsset,
    this.photoBytes,
    this.hasRegistrationDocument = false,
    this.registrationDocumentBytes,
  });

  final String id;
  final String brand;
  final String model;

  /// Empty until the registration certificate is checked — the driver does not
  /// type it in by hand.
  final String plateNumber;
  final int seatCount;
  final VehicleVerificationStatus verificationStatus;
  final VehicleTransportType transportType;
  final String? color;
  final int? year;
  final String? photoAsset;

  /// Photo the driver uploaded, kept in memory until the file storage exists.
  final Uint8List? photoBytes;

  bool get hasPhoto => photoBytes != null || photoAsset != null;
  bool get hasPlateNumber => plateNumber.trim().isNotEmpty;

  /// Whether the registration certificate (СТС) has been uploaded — the
  /// document the administrator checks.
  final bool hasRegistrationDocument;

  /// Private local selection for upload. Never shown in public trip/profile DTOs.
  final Uint8List? registrationDocumentBytes;

  String get title => '$brand $model';

  bool get isApproved =>
      verificationStatus == VehicleVerificationStatus.approved;

  /// «А 777 АА 7 • 4 места», or just the seats while the plate is unknown.
  String get summaryLabel =>
      hasPlateNumber ? '$plateNumber • $seatCount места' : '$seatCount места';

  String get transportLabel =>
      transportType == VehicleTransportType.car ? 'Легковой' : 'Автобус';

  String get statusLabel => switch (verificationStatus) {
    VehicleVerificationStatus.approved => 'Проверен',
    VehicleVerificationStatus.pending => 'На проверке',
    VehicleVerificationStatus.rejected => 'Отклонён',
    VehicleVerificationStatus.draft => 'Черновик',
  };

  DriverVehicle copyWith({
    String? brand,
    String? model,
    String? plateNumber,
    int? seatCount,
    VehicleVerificationStatus? verificationStatus,
    VehicleTransportType? transportType,
    String? color,
    int? year,
    String? photoAsset,
    Uint8List? photoBytes,
    bool clearPhoto = false,
    bool? hasRegistrationDocument,
    Uint8List? registrationDocumentBytes,
  }) {
    return DriverVehicle(
      id: id,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      plateNumber: plateNumber ?? this.plateNumber,
      seatCount: seatCount ?? this.seatCount,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      transportType: transportType ?? this.transportType,
      color: color ?? this.color,
      year: year ?? this.year,
      photoAsset: clearPhoto ? null : photoAsset ?? this.photoAsset,
      photoBytes: clearPhoto ? null : photoBytes ?? this.photoBytes,
      registrationDocumentBytes:
          registrationDocumentBytes ?? this.registrationDocumentBytes,
      hasRegistrationDocument:
          hasRegistrationDocument ?? this.hasRegistrationDocument,
    );
  }
}
