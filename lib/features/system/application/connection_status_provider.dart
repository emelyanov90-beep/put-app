import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/features/system/data/device_connectivity_service.dart';

/// Live connectivity of the device. While the first value is still pending —
/// or if connectivity cannot be determined — this resolves to `true`, so the
/// UI falls back to the generic error state instead of blaming the network.
final connectionStatusProvider = StreamProvider<bool>((ref) {
  return ref.watch(connectivityServiceProvider).watchConnection();
});

final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectionStatusProvider).value ?? true;
});
