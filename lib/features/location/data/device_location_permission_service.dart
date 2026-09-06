import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vput/features/location/domain/location_permission_service.dart';

class DeviceLocationPermissionService implements LocationPermissionService {
  const DeviceLocationPermissionService();

  @override
  Future<AppLocationPermission> requestWhenInUse() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return AppLocationPermission.serviceDisabled;
      }
      return AppLocationPermission.granted;
    }

    return switch (permission) {
      LocationPermission.deniedForever => AppLocationPermission.deniedForever,
      LocationPermission.denied ||
      LocationPermission.unableToDetermine => AppLocationPermission.denied,
      LocationPermission.always ||
      LocationPermission.whileInUse => AppLocationPermission.granted,
    };
  }
}

final locationPermissionServiceProvider = Provider<LocationPermissionService>(
  (ref) => const DeviceLocationPermissionService(),
);
