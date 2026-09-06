import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/core/utils/russian_date_labels.dart';
import 'package:vput/features/trips/application/driver_trips_controller.dart';
import 'package:vput/features/trips/application/trip_draft_controller.dart';
import 'package:vput/features/trips/domain/trip_route_point.dart';
import 'package:vput/features/trips/presentation/widgets/create_trip_controls.dart';
import 'package:vput/features/trips/presentation/widgets/trip_route_block.dart';
import 'package:vput/features/trips/presentation/widgets/trip_schedule_sheets.dart';

/// Step 2: route with planned stops, departure date and time, estimated
/// arrival and the number of seats.
class CreateTripRouteScreen extends ConsumerStatefulWidget {
  const CreateTripRouteScreen({
    required this.onBack,
    required this.onContinue,
    this.isEditing = false,
    this.onSave,
    this.onEditPricing,
    this.now,
    super.key,
  });

  /// Seat cap used until a vehicle is chosen; picking a vehicle lowers it to
  /// the seats of that vehicle.
  static const seatCapWithoutVehicle = 8;

  static const originFieldKey = Key('create_trip_origin');
  static const destinationFieldKey = Key('create_trip_destination');
  static const addStopButtonKey = Key('create_trip_add_stop');
  static const clearOriginKey = Key('create_trip_clear_origin');
  static const clearDestinationKey = Key('create_trip_clear_destination');
  static const dateFieldKey = Key('create_trip_date');
  static const departureTimeFieldKey = Key('create_trip_departure_time');
  static const arrivalTimeFieldKey = Key('create_trip_arrival_time');
  static const editPricingButtonKey = Key('create_trip_edit_pricing_action');
  static const saveButtonKey = CreateTripStepScaffold.secondaryButtonKey;

  static Key stopFieldKey(int index) => Key('create_trip_stop_$index');
  static Key removeStopKey(int index) => Key('create_trip_remove_stop_$index');

  final VoidCallback onBack;
  final VoidCallback onContinue;

  /// Editing a stored trip: the screen is titled «Изменение заказа» and offers
  /// «Сохранить» next to «Далее».
  final bool isEditing;
  final VoidCallback? onSave;
  final VoidCallback? onEditPricing;

  /// Injectable clock; defaults to the real one.
  final DateTime? now;

  @override
  ConsumerState<CreateTripRouteScreen> createState() =>
      _CreateTripRouteScreenState();
}

class _CreateTripRouteScreenState extends ConsumerState<CreateTripRouteScreen> {
  late final DateTime _now = widget.now ?? DateTime.now();
  final _controllers = <TextEditingController>[];

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Keeps one controller per route point while stops are added and removed.
  void _syncControllers(List<TripRoutePoint> points) {
    while (_controllers.length < points.length) {
      _controllers.add(TextEditingController());
    }
    while (_controllers.length > points.length) {
      _controllers.removeLast().dispose();
    }
    for (var index = 0; index < points.length; index++) {
      final address = points[index].address;
      if (_controllers[index].text != address) {
        _controllers[index].text = address;
      }
    }
  }

  Future<void> _pickDate() => pickTripDepartureDate(
    context,
    controller: ref.read(tripDraftProvider.notifier),
    departure: ref.read(tripDraftProvider).departureAt,
    now: _now,
  );

  Future<void> _pickDepartureTime() => pickTripDepartureTime(
    context,
    controller: ref.read(tripDraftProvider.notifier),
    departure: ref.read(tripDraftProvider).departureAt,
    now: _now,
  );

  Future<void> _pickArrivalTime() => pickTripArrivalTime(
    context,
    controller: ref.read(tripDraftProvider.notifier),
    arrival: ref.read(tripDraftProvider).arrivalAt,
    now: _now,
  );

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(tripDraftProvider);
    final controller = ref.read(tripDraftProvider.notifier);
    final vehicle = ref.watch(selectedDriverVehicleProvider);
    final maxSeats =
        vehicle?.seatCount ?? CreateTripRouteScreen.seatCapWithoutVehicle;
    final points = draft.points;
    _syncControllers(points);
    final lastIndex = points.length - 1;
    final departure = draft.departureAt;
    final arrival = draft.arrivalAt;
    final canContinue =
        draft.isRouteValid &&
        draft.isScheduleValid(now: _now) &&
        draft.isSeatCountValid;

    final hasChanges = ref.watch(tripDraftHasChangesProvider);

    return CreateTripStepScaffold(
      step: 2,
      title: widget.isEditing ? 'Изменение заказа' : 'Новый заказ',
      onBack: widget.onBack,
      primaryLabel: 'Далее',
      onPrimary: canContinue ? widget.onContinue : null,
      secondaryLabel: widget.isEditing ? 'Сохранить' : null,
      onSecondary: hasChanges && canContinue ? widget.onSave : null,
      sideBySideActions: true,
      children: [
        CreateTripSection(
          title: 'Маршрут',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TripRouteBlock(
                pointCount: points.length,
                fields: [
                  for (var index = 0; index < points.length; index++)
                    CreateTripField(
                      fieldKey: index == 0
                          ? CreateTripRouteScreen.originFieldKey
                          : index == lastIndex
                          ? CreateTripRouteScreen.destinationFieldKey
                          : CreateTripRouteScreen.stopFieldKey(index),
                      label: index == lastIndex
                          ? 'Пункт назначения'
                          : 'Точка посадки',
                      controller: _controllers[index],
                      onChanged: (value) => controller.setPointAt(
                        index,
                        points[index].copyWith(address: value),
                      ),
                      clearKey: index == 0
                          ? CreateTripRouteScreen.clearOriginKey
                          : index == lastIndex
                          ? CreateTripRouteScreen.clearDestinationKey
                          : CreateTripRouteScreen.removeStopKey(index),
                      // The «×» clears an endpoint, but removes a stop: a stop
                      // only exists while the driver keeps it.
                      onClear: () {
                        if (index == 0 || index == lastIndex) {
                          controller.setPointAt(
                            index,
                            const TripRoutePoint(address: ''),
                          );
                          return;
                        }
                        controller.removeStopAt(index);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 11),
              CreateTripOutlinedAction(
                actionKey: CreateTripRouteScreen.addStopButtonKey,
                label: 'Добавить остановку',
                onPressed: controller.addStop,
              ),
            ],
          ),
        ),
        CreateTripSection(
          title: 'Дата и время выезда',
          child: Row(
            children: [
              Expanded(
                child: CreateTripField(
                  fieldKey: CreateTripRouteScreen.dateFieldKey,
                  label: 'Дата',
                  value: departure == null
                      ? null
                      : RussianDateLabels.dayAndMonth(departure),
                  onTap: _pickDate,
                  trailing: const _FieldIcon(Icons.calendar_today_rounded),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CreateTripField(
                  fieldKey: CreateTripRouteScreen.departureTimeFieldKey,
                  label: 'Время',
                  value: departure == null
                      ? null
                      : RussianDateLabels.time(departure),
                  onTap: _pickDepartureTime,
                  trailing: const _FieldIcon(Icons.schedule_rounded),
                ),
              ),
            ],
          ),
        ),
        CreateTripSection(
          title: 'Примерное время прибытия',
          child: CreateTripField(
            fieldKey: CreateTripRouteScreen.arrivalTimeFieldKey,
            label: 'Время',
            value: arrival == null ? null : RussianDateLabels.time(arrival),
            onTap: departure == null ? null : _pickArrivalTime,
            trailing: const _FieldIcon(Icons.schedule_rounded),
          ),
        ),
        CreateTripSection(
          title: 'Пассажиры',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CreateTripSeatCounter(
                label: 'Количество мест:',
                value: draft.seatCount,
                minValue: 0,
                maxValue: maxSeats,
                onChanged: controller.setSeatCount,
              ),
              if (widget.isEditing) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: OutlinedButton(
                    key: CreateTripRouteScreen.editPricingButtonKey,
                    onPressed: widget.onEditPricing,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.brandGreen,
                      side: const BorderSide(color: AppColors.brandGreen),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Изменить стоимость'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FieldIcon extends StatelessWidget {
  const _FieldIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Icon(icon, size: 18, color: AppColors.textSecondary);
  }
}
