import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/core/api/pocketbase_provider.dart';
import 'package:vput/core/config/app_config.dart';
import 'package:vput/features/auth/application/preview_session_controller.dart';
import 'package:vput/features/trips/application/driver_trips_controller.dart';
import 'package:vput/features/trips/domain/passenger_trip.dart';
import 'package:vput/features/trips/domain/trip_commission.dart';
import 'package:vput/features/trips/domain/trip_publication_limits.dart';

/// Offline/demo fallback mirroring the seeded server values.
const previewTripPublicationLimits = TripPublicationLimits(
  perDay: 2,
  perWeek: 10,
);

final _runtimeTripConfigProvider = FutureProvider<Map<String, dynamic>>((ref) {
  if (AppConfig.isPreviewMode) return Future.value(const {});
  if (ref.watch(currentSessionUserIdProvider) == null) {
    return Future.value(const {});
  }
  return ref
      .watch(pocketBaseProvider)
      .send<Map<String, dynamic>>('/api/app/config');
});

final tripPublicationLimitsProvider = Provider<TripPublicationLimits>((ref) {
  final raw = ref.watch(_runtimeTripConfigProvider).value;
  final limits = raw?['trip_publication_limits'];
  if (limits is! Map) return previewTripPublicationLimits;
  return TripPublicationLimits(
    perDay:
        (limits['driver_trip_limit_per_day'] as num?)?.toInt() ??
        previewTripPublicationLimits.perDay,
    perWeek:
        (limits['driver_trip_limit_per_week'] as num?)?.toInt() ??
        previewTripPublicationLimits.perWeek,
    outboundPerDay:
        (limits['outbound_limit_per_pair'] as num?)?.toInt() ??
        previewTripPublicationLimits.outboundPerDay,
    returnPerDay:
        (limits['return_limit_per_pair'] as num?)?.toInt() ??
        previewTripPublicationLimits.returnPerDay,
  );
});

/// Counted from the trips the driver has actually published for immediate UI
/// feedback. The backend independently enforces the configured limits.
final tripPublicationUsageProvider = Provider<TripPublicationUsage>((ref) {
  return driverPublicationUsage(
    ref.watch(driverTripsProvider),
    now: DateTime.now(),
  );
});

/// Offline/demo rate mirroring the seeded `commission_percent` setting.
const previewTripCommission = TripCommissionPolicy(percent: 10);

final tripCommissionPolicyProvider = Provider<TripCommissionPolicy>((ref) {
  final raw = ref.watch(_runtimeTripConfigProvider).value;
  return TripCommissionPolicy(
    percent:
        (raw?['commission_percent'] as num?)?.toInt() ??
        previewTripCommission.percent,
  );
});

/// Whether a vehicle is usable as soon as it is saved, with no administrator
/// review. The server decides it; the client only adapts its wording.
final vehicleAutoApproveProvider = Provider<bool>((ref) {
  final raw = ref.watch(_runtimeTripConfigProvider).value;
  return raw?['vehicle_auto_approve'] != false;
});

/// Preview prices of the seat extras. The driver switches a service on, the
/// price comes from the catalogue.
const previewExtraServicePrices = <TripExtraService, int>{
  TripExtraService.childSeat: 150,
  TripExtraService.luggage: 150,
  TripExtraService.pets: 150,
};

final tripExtraServicePricesProvider = Provider<Map<TripExtraService, int>>((
  ref,
) {
  final raw = ref.watch(_runtimeTripConfigProvider).value;
  final prices = raw?['extra_service_prices'];
  if (prices is! Map) return previewExtraServicePrices;
  return {
    TripExtraService.childSeat: (prices['child_seat'] as num?)?.toInt() ?? 150,
    TripExtraService.luggage: (prices['luggage'] as num?)?.toInt() ?? 150,
    TripExtraService.pets: (prices['pets'] as num?)?.toInt() ?? 150,
  };
});
