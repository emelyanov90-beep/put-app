import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/features/trips/application/trip_draft_controller.dart';
import 'package:vput/features/trips/data/preview_trip_publication_settings.dart';
import 'package:vput/features/trips/presentation/widgets/create_trip_controls.dart';
import 'package:vput/features/vehicles/application/driver_vehicles_controller.dart';
import 'package:vput/features/vehicles/domain/driver_vehicle.dart';
import 'package:vput/features/vehicles/presentation/widgets/vehicle_photo.dart';

/// Tint of the selected row in the design.
const _selectedTint = Color(0xFFE9F6EE);

/// Vehicle chooser of the wizard: only cars that passed verification can carry
/// a published trip, so the list holds exactly those.
class DriverVehiclePicker extends ConsumerWidget {
  const DriverVehiclePicker({required this.onAddVehicle, super.key});

  static const addVehicleButtonKey = Key('create_trip_add_vehicle');
  static const emptyStateKey = Key('create_trip_vehicles_empty');

  static Key vehicleKey(String id) => Key('create_trip_vehicle_$id');

  final VoidCallback onAddVehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(
      tripDraftProvider.select((draft) => draft.vehicleId),
    );
    final controller = ref.read(tripDraftProvider.notifier);
    final vehicles = ref.watch(approvedDriverVehiclesProvider);

    if (vehicles.isEmpty) {
      return DriverVehicleEmptyCard(onAddVehicle: onAddVehicle);
    }

    return CreateTripCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final vehicle in vehicles) ...[
            if (vehicle != vehicles.first) const SizedBox(height: 8),
            _VehicleRow(
              vehicle: vehicle,
              selected: selectedId == vehicle.id,
              onTap: () => controller.selectVehicle(vehicle.id),
            ),
          ],
        ],
      ),
    );
  }
}

/// Green pill next to the «Автомобиль» section title.
class AddVehicleAction extends StatelessWidget {
  const AddVehicleAction({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CreateTripOutlinedAction(
      actionKey: DriverVehiclePicker.addVehicleButtonKey,
      label: 'Добавить авто',
      showIcon: false,
      onPressed: onPressed,
    );
  }
}

class _VehicleRow extends StatelessWidget {
  const _VehicleRow({
    required this.vehicle,
    required this.selected,
    required this.onTap,
  });

  final DriverVehicle vehicle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        key: DriverVehiclePicker.vehicleKey(vehicle.id),
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: selected ? _selectedTint : AppColors.accentWhite,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppColors.brandGreen : AppColors.divider,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 56,
                height: 44,
                child: VehiclePhoto(vehicle: vehicle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            vehicle.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.accentBlack,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              height: 1.33,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const _VerifiedBadge(),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      vehicle.summaryLabel,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.38,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _RadioMark(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return const Tooltip(
      message: 'Авто проверено',
      child: Icon(
        Icons.check_circle_rounded,
        size: 14,
        color: AppColors.brandGreen,
      ),
    );
  }
}

class _RadioMark extends StatelessWidget {
  const _RadioMark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 20,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(width: 2, color: AppColors.brandGreen),
        ),
        child: selected
            ? const Padding(
                padding: EdgeInsets.all(3.5),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.brandGreen,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

/// State of the design for a driver with no usable car yet.
class DriverVehicleEmptyCard extends ConsumerWidget {
  const DriverVehicleEmptyCard({required this.onAddVehicle, super.key});

  final VoidCallback onAddVehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // With moderation switched off a car is ready the moment it is saved, so
    // the hint must not promise an administrator review.
    final autoApprove = ref.watch(vehicleAutoApproveProvider);
    return CreateTripCard(
      key: DriverVehiclePicker.emptyStateKey,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        children: [
          const Icon(
            Icons.assignment_rounded,
            size: 56,
            color: AppColors.divider,
          ),
          const SizedBox(height: 8),
          const Text(
            'Нет добавленных авто',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.accentBlack,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.29,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            autoApprove
                ? 'Чтобы создать поездку, добавьте автомобиль — он сразу '
                      'будет доступен для публикации'
                : 'Чтобы создать поездку, добавьте автомобиль и пришлите СТС '
                      'на проверку администратору',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF95969C),
              fontSize: 15,
              height: 1.33,
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            key: DriverVehiclePicker.addVehicleButtonKey,
            onPressed: onAddVehicle,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: AppColors.brandGreen,
              foregroundColor: AppColors.accentWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            child: const Text('Добавить авто'),
          ),
        ],
      ),
    );
  }
}
