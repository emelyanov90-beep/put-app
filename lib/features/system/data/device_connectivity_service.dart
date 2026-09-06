import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/features/system/domain/connectivity_service.dart';

class DeviceConnectivityService implements ConnectivityService {
  DeviceConnectivityService([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<bool> hasConnection() async {
    try {
      return _isOnline(await _connectivity.checkConnectivity());
    } catch (_) {
      return true;
    }
  }

  @override
  Stream<bool> watchConnection() async* {
    yield await hasConnection();
    yield* _connectivity.onConnectivityChanged
        .map(_isOnline)
        .handleError((_) {});
  }

  static bool _isOnline(List<ConnectivityResult> results) {
    if (results.isEmpty) return true;
    return results.any((result) => result != ConnectivityResult.none);
  }
}

final connectivityServiceProvider = Provider<ConnectivityService>(
  (ref) => DeviceConnectivityService(),
);
