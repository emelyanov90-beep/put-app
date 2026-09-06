import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/features/trips/application/driver_trips_controller.dart';
import 'package:vput/features/trips/application/trip_draft_controller.dart';
import 'package:vput/features/trips/domain/trip_fare_table.dart';
import 'package:vput/features/trips/presentation/widgets/create_trip_controls.dart';
import 'package:vput/features/trips/presentation/widgets/trip_fare_fields.dart';

/// «Изменение стоимости» — the fares of a saved trip: the whole route, every
/// other pair of points and the boarding price.
class EditTripPricingScreen extends ConsumerWidget {
  const EditTripPricingScreen({
    required this.onBack,
    required this.onSave,
    super.key,
  });

  static const keyPrefix = 'edit_trip';

  static final fullRouteFieldKey = TripFareFields.fullRouteFieldKey(keyPrefix);
  static final minimumFieldKey = TripFareFields.minimumFieldKey(keyPrefix);
  static const saveButtonKey = CreateTripStepScaffold.primaryButtonKey;

  static Key legFieldKey(int fromIndex, int toIndex) =>
      TripFareFields.legFieldKey(keyPrefix, TripFareLeg(fromIndex, toIndex));

  final VoidCallback onBack;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(tripDraftProvider);
    final hasChanges = ref.watch(tripDraftHasChangesProvider);

    return CreateTripStepScaffold(
      title: 'Изменение стоимости',
      onBack: onBack,
      primaryLabel: 'Сохранить',
      onPrimary: hasChanges && draft.isPricingValid ? onSave : null,
      children: const [TripFareFields(keyPrefix: keyPrefix)],
    );
  }
}
