import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/features/trips/application/trip_draft_controller.dart';
import 'package:vput/features/trips/data/preview_trip_publication_settings.dart';
import 'package:vput/features/trips/presentation/widgets/create_trip_controls.dart';
import 'package:vput/features/trips/presentation/widgets/driver_vehicle_picker.dart';
import 'package:vput/features/trips/presentation/widgets/trip_money_breakdown_card.dart';
import 'package:vput/features/vehicles/application/driver_vehicles_controller.dart';

/// Step 4: the car the trip runs on, with the money split of step 3 repeated
/// above it.
class CreateTripVehicleScreen extends ConsumerWidget {
  const CreateTripVehicleScreen({
    required this.onBack,
    required this.onContinue,
    required this.onAddVehicle,
    this.isEditing = false,
    super.key,
  });

  final VoidCallback onBack;
  final VoidCallback onContinue;
  final VoidCallback onAddVehicle;
  final bool isEditing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(tripDraftProvider);
    final commission = ref.watch(tripCommissionPolicyProvider);
    final fullRoutePrice = draft.fullRoutePrice;
    final hasVehicles = ref.watch(approvedDriverVehiclesProvider).isNotEmpty;

    return CreateTripStepScaffold(
      step: 4,
      onBack: onBack,
      primaryLabel: isEditing ? 'Сохранить' : 'Далее',
      onPrimary: ref.watch(tripDraftVehicleReadyProvider) ? onContinue : null,
      children: [
        if (fullRoutePrice != null && fullRoutePrice > 0) ...[
          TripMoneyBreakdownCard(
            breakdown: commission.breakdownFor(fullRoutePrice),
          ),
          const SizedBox(height: 20),
        ],
        CreateTripSection(
          title: 'Автомобиль',
          padded: false,
          // With no verified car the call to action lives inside the empty card.
          action: hasVehicles
              ? AddVehicleAction(onPressed: onAddVehicle)
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DriverVehiclePicker(onAddVehicle: onAddVehicle),
          ),
        ),
      ],
    );
  }
}
