abstract interface class ConnectivityService {
  /// Whether the device currently has a network interface available.
  ///
  /// Implementations return `true` when connectivity cannot be determined:
  /// wrongly claiming the user is offline is worse than showing the generic
  /// error state.
  Future<bool> hasConnection();

  /// Emits on every connectivity change, starting with the current value.
  Stream<bool> watchConnection();
}
