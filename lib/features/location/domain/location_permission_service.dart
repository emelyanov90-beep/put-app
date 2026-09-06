enum AppLocationPermission { granted, denied, deniedForever, serviceDisabled }

abstract interface class LocationPermissionService {
  Future<AppLocationPermission> requestWhenInUse();
}
