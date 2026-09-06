import 'package:flutter/material.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/features/vehicles/domain/driver_vehicle.dart';

/// Photo of a vehicle: what the driver uploaded, the catalogue render, or a
/// placeholder while there is neither.
class VehiclePhoto extends StatelessWidget {
  const VehiclePhoto({
    required this.vehicle,
    this.borderRadius = 8,
    this.iconSize = 22,
    super.key,
  });

  final DriverVehicle vehicle;
  final double borderRadius;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final bytes = vehicle.photoBytes;
    final asset = vehicle.photoAsset;

    final Widget image;
    if (bytes != null) {
      image = Image.memory(
        bytes,
        fit: BoxFit.cover,
        excludeFromSemantics: true,
      );
    } else if (asset != null) {
      image = Image.asset(asset, fit: BoxFit.cover, excludeFromSemantics: true);
    } else {
      image = ColoredBox(
        color: AppColors.surfaceMuted,
        child: Icon(
          Icons.directions_car_filled_rounded,
          size: iconSize,
          color: AppColors.textSecondary,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: image,
    );
  }
}
