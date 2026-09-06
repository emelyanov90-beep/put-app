import 'package:flutter/material.dart';
import 'package:vput/features/profile/data/device_profile_image_repository.dart';
import 'package:vput/features/profile/presentation/widgets/photo_source_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/app/widgets/screen_header.dart';
import 'package:vput/features/vehicles/application/driver_vehicles_controller.dart';
import 'package:vput/features/vehicles/domain/driver_vehicle.dart';
import 'package:vput/features/vehicles/presentation/widgets/vehicle_photo.dart';

/// Card of one vehicle: its photo, verification mark, documents and the two
/// actions — edit it or remove it from the garage.
class DriverVehicleDetailsScreen extends ConsumerStatefulWidget {
  const DriverVehicleDetailsScreen({
    required this.vehicleId,
    required this.onBack,
    required this.onEdit,
    required this.onDeleted,
    super.key,
  });

  static const editButtonKey = Key('driver_vehicle_edit');
  static const deleteButtonKey = Key('driver_vehicle_delete');
  static const replaceDocumentKey = Key('driver_vehicle_replace_document');
  static const confirmDeleteKey = Key('driver_vehicle_confirm_delete');

  final String vehicleId;
  final VoidCallback onBack;
  final ValueChanged<DriverVehicle> onEdit;
  final VoidCallback onDeleted;

  @override
  ConsumerState<DriverVehicleDetailsScreen> createState() =>
      _DriverVehicleDetailsState();
}

class _DriverVehicleDetailsState
    extends ConsumerState<DriverVehicleDetailsScreen> {
  bool _pickingDocument = false;
  String get vehicleId => widget.vehicleId;
  VoidCallback get onBack => widget.onBack;
  ValueChanged<DriverVehicle> get onEdit => widget.onEdit;
  VoidCallback get onDeleted => widget.onDeleted;

  Future<void> _replaceDocument() async {
    if (_pickingDocument) return;
    setState(() => _pickingDocument = true);
    try {
      final source = await PhotoSourceSheet.show(context);
      if (source == null || !mounted) return;
      final bytes = await ref.read(profileImageRepositoryProvider).pick(source);
      if (bytes == null || !mounted) return;
      await ref
          .read(driverVehiclesProvider.notifier)
          .replaceRegistrationDocument(vehicleId, bytes);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось выбрать СТС. Попробуйте ещё раз.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _pickingDocument = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(driverVehiclesProvider);
    final vehicle = ref
        .read(driverVehiclesProvider.notifier)
        .findById(vehicleId);
    if (vehicle == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ScreenHeader(title: 'Транспорт', onBack: onBack),
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    'Автомобиль не найден',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ScreenHeader(title: vehicle.title, onBack: onBack),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.accentWhite,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: VehiclePhoto(
                              vehicle: vehicle,
                              borderRadius: 12,
                              iconSize: 40,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        vehicle.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppColors.accentBlack,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          height: 1.33,
                                        ),
                                      ),
                                    ),
                                    if (vehicle.hasPlateNumber) ...[
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: _PlateBadge(
                                          plateNumber: vehicle.plateNumber,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              _StatusChip(vehicle: vehicle),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${vehicle.transportLabel} · '
                            '${vehicle.seatCount} места',
                            style: const TextStyle(
                              color: AppColors.accentBlack,
                              fontSize: 15,
                              height: 1.33,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Документы',
                      style: TextStyle(
                        color: AppColors.accentBlack,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.33,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.accentWhite,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'СТС (свидетельство о регистрации)',
                                  style: TextStyle(
                                    color: AppColors.accentBlack,
                                    fontSize: 15,
                                    height: 1.33,
                                  ),
                                ),
                                if (!vehicle.hasRegistrationDocument) ...[
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Не загружено — без него авто не пройдёт '
                                    'проверку',
                                    style: TextStyle(
                                      color: AppColors.errorText,
                                      fontSize: 13,
                                      height: 1.38,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            key: DriverVehicleDetailsScreen.replaceDocumentKey,
                            onPressed: _pickingDocument
                                ? null
                                : _replaceDocument,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 36),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              foregroundColor: AppColors.brandGreen,
                              side: const BorderSide(
                                color: AppColors.brandGreen,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            iconAlignment: IconAlignment.end,
                            icon: const Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                            ),
                            label: Text(
                              vehicle.hasRegistrationDocument
                                  ? 'Заменить'
                                  : 'Загрузить',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: FilledButton(
                      key: DriverVehicleDetailsScreen.editButtonKey,
                      onPressed: () => onEdit(vehicle),
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
                      child: const Text('Редактировать'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: OutlinedButton(
                      key: DriverVehicleDetailsScreen.deleteButtonKey,
                      onPressed: () => _confirmDelete(context, ref, vehicle),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.errorText,
                        side: const BorderSide(color: AppColors.errorText),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Удалить ТС'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Removing a car cannot be undone, so it is confirmed first.
  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    DriverVehicle vehicle,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.accentWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Удалить ТС?',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        content: Text(
          '${vehicle.title} · ${vehicle.plateNumber} пропадёт из списка. '
          'Опубликованные поездки на этом авто останутся без изменений.',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            height: 1.33,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(foregroundColor: AppColors.accentBlack),
            child: const Text('Отмена'),
          ),
          TextButton(
            key: DriverVehicleDetailsScreen.confirmDeleteKey,
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorText),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(driverVehiclesProvider.notifier).remove(vehicle.id);
    if (mounted) onDeleted();
  }
}

class _PlateBadge extends StatelessWidget {
  const _PlateBadge({required this.plateNumber});

  final String plateNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.accentBlack),
      ),
      child: Text(
        plateNumber,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.accentBlack,
          fontSize: 13,
          height: 1.38,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.vehicle});

  final DriverVehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final color = switch (vehicle.verificationStatus) {
      VehicleVerificationStatus.approved => AppColors.brandGreen,
      VehicleVerificationStatus.rejected => AppColors.errorText,
      _ => AppColors.textSecondary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color),
      ),
      child: Text(
        vehicle.statusLabel,
        style: TextStyle(color: color, fontSize: 13, height: 1.38),
      ),
    );
  }
}
