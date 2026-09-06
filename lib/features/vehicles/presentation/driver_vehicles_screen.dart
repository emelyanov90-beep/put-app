import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/app/widgets/screen_header.dart';
import 'package:vput/features/vehicles/application/driver_vehicles_controller.dart';
import 'package:vput/features/vehicles/domain/driver_vehicle.dart';
import 'package:vput/features/vehicles/presentation/widgets/vehicle_photo.dart';

/// «Транспортные средства» — the driver garage: every car of the account with
/// its verification mark, or an invitation to add the first one.
class DriverVehiclesScreen extends ConsumerWidget {
  const DriverVehiclesScreen({
    required this.onBack,
    required this.onAddVehicle,
    required this.onOpenVehicle,
    super.key,
  });

  static const addButtonKey = Key('driver_vehicles_add');
  static const emptyAddButtonKey = Key('driver_vehicles_empty_add');
  static const emptyStateKey = Key('driver_vehicles_empty');

  static Key vehicleKey(String id) => Key('driver_vehicle_row_$id');

  final VoidCallback onBack;
  final VoidCallback onAddVehicle;
  final ValueChanged<DriverVehicle> onOpenVehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicles = ref.watch(driverVehiclesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ScreenHeader(
                title: 'Транспортные средства',
                onBack: onBack,
              ),
            ),
            Expanded(
              child: vehicles.isEmpty
                  ? _EmptyState(onAddVehicle: onAddVehicle)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                      itemCount: vehicles.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => _VehicleRow(
                        vehicle: vehicles[index],
                        onTap: () => onOpenVehicle(vehicles[index]),
                      ),
                    ),
            ),
            if (vehicles.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: FilledButton(
                    key: addButtonKey,
                    onPressed: onAddVehicle,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandGreen,
                      foregroundColor: AppColors.accentWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Добавить ТС'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VehicleRow extends StatelessWidget {
  const _VehicleRow({required this.vehicle, required this.onTap});

  final DriverVehicle vehicle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accentWhite,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: DriverVehiclesScreen.vehicleKey(vehicle.id),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
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
                        if (vehicle.isApproved)
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 14,
                            color: AppColors.brandGreen,
                          )
                        else
                          Text(
                            vehicle.statusLabel,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              height: 1.33,
                            ),
                          ),
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
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.accentBlack,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAddVehicle});

  final VoidCallback onAddVehicle;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: DriverVehiclesScreen.emptyStateKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Foundation placeholder: the design shows a licence illustration,
            // which is not in the repository yet.
            const Icon(Icons.badge_rounded, size: 56, color: AppColors.divider),
            const SizedBox(height: 12),
            const Text(
              'У вас еще нет транспортного средства',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.accentBlack,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                height: 1.29,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Добавьте информацию о ТС и берите или создавайте заказы',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF95969C),
                fontSize: 15,
                height: 1.33,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: DriverVehiclesScreen.emptyAddButtonKey,
              onPressed: onAddVehicle,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                backgroundColor: AppColors.brandGreen,
                foregroundColor: AppColors.accentWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Добавить ТС'),
            ),
          ],
        ),
      ),
    );
  }
}
