import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/core/utils/russian_date_labels.dart';
import 'package:vput/features/trips/application/trip_draft_controller.dart';
import 'package:vput/features/trips/data/preview_trip_publication_settings.dart';
import 'package:vput/features/trips/domain/trip_route_point.dart';
import 'package:vput/features/trips/presentation/widgets/create_trip_controls.dart';
import 'package:vput/features/trips/presentation/widgets/publish_confirmation_sheet.dart';
import 'package:vput/features/trips/presentation/widgets/trip_money_breakdown_card.dart';
import 'package:vput/features/trips/presentation/widgets/trip_route_block.dart';
import 'package:vput/features/trips/presentation/widgets/trip_schedule_sheets.dart';

/// The trip back: the route of the published trip in reverse, its money and
/// services carried over, and a new departure to set.
class CreateReturnTripScreen extends ConsumerStatefulWidget {
  const CreateReturnTripScreen({
    required this.onBack,
    required this.onPublish,
    this.now,
    super.key,
  });

  static const originFieldKey = Key('return_trip_origin');
  static const destinationFieldKey = Key('return_trip_destination');
  static const dateFieldKey = Key('return_trip_date');
  static const departureTimeFieldKey = Key('return_trip_departure_time');
  static const arrivalTimeFieldKey = Key('return_trip_arrival_time');
  static const publishButtonKey = CreateTripStepScaffold.primaryButtonKey;

  static Key stopFieldKey(int index) => Key('return_trip_stop_$index');
  static Key clearPointKey(int index) => Key('return_trip_clear_$index');

  final VoidCallback onBack;
  final VoidCallback onPublish;

  /// Injectable clock; defaults to the real one.
  final DateTime? now;

  @override
  ConsumerState<CreateReturnTripScreen> createState() =>
      _CreateReturnTripScreenState();
}

class _CreateReturnTripScreenState
    extends ConsumerState<CreateReturnTripScreen> {
  late final DateTime _now = widget.now ?? DateTime.now();
  final _controllers = <TextEditingController>[];

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

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

  Future<void> _publish() async {
    final confirmed = await PublishConfirmationSheet.show(context);
    if (!confirmed || !mounted) return;
    widget.onPublish();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(tripDraftProvider);
    final controller = ref.read(tripDraftProvider.notifier);
    final commission = ref.watch(tripCommissionPolicyProvider);
    final points = draft.points;
    _syncControllers(points);
    final lastIndex = points.length - 1;
    final departure = draft.departureAt;
    final arrival = draft.arrivalAt;
    final fullRoutePrice = draft.fullRoutePrice;
    final canPublish =
        draft.canPublish(now: _now) && ref.watch(tripDraftVehicleReadyProvider);

    return CreateTripStepScaffold(
      title: 'Обратное направление',
      onBack: widget.onBack,
      primaryLabel: 'Опубликовать поездку',
      onPrimary: canPublish ? _publish : null,
      children: [
        if (fullRoutePrice != null && fullRoutePrice > 0) ...[
          TripMoneyBreakdownCard(
            breakdown: commission.breakdownFor(fullRoutePrice),
          ),
          const SizedBox(height: 20),
        ],
        CreateTripSection(
          title: 'Маршрут',
          child: TripRouteBlock(
            pointCount: points.length,
            fields: [
              for (var index = 0; index < points.length; index++)
                CreateTripField(
                  fieldKey: index == 0
                      ? CreateReturnTripScreen.originFieldKey
                      : index == lastIndex
                      ? CreateReturnTripScreen.destinationFieldKey
                      : CreateReturnTripScreen.stopFieldKey(index),
                  clearKey: CreateReturnTripScreen.clearPointKey(index),
                  label: index == lastIndex
                      ? 'Пункт назначения'
                      : 'Точка посадки',
                  controller: _controllers[index],
                  onChanged: (value) => controller.setPointAt(
                    index,
                    points[index].copyWith(address: value),
                  ),
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
        ),
        CreateTripSection(
          title: 'Дата и время выезда',
          child: Row(
            children: [
              Expanded(
                child: CreateTripField(
                  fieldKey: CreateReturnTripScreen.dateFieldKey,
                  label: 'Дата',
                  value: departure == null
                      ? null
                      : RussianDateLabels.numericDate(departure),
                  onTap: () => pickTripDepartureDate(
                    context,
                    controller: controller,
                    departure: departure,
                    now: _now,
                  ),
                  trailing: const _FieldIcon(Icons.calendar_today_rounded),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CreateTripField(
                  fieldKey: CreateReturnTripScreen.departureTimeFieldKey,
                  label: 'Время',
                  value: departure == null
                      ? null
                      : RussianDateLabels.shortTime(departure),
                  onTap: () => pickTripDepartureTime(
                    context,
                    controller: controller,
                    departure: departure,
                    now: _now,
                  ),
                  trailing: const _FieldIcon(Icons.schedule_rounded),
                ),
              ),
            ],
          ),
        ),
        CreateTripSection(
          title: 'Примерное время прибытия',
          child: CreateTripField(
            fieldKey: CreateReturnTripScreen.arrivalTimeFieldKey,
            label: 'Время',
            value: arrival == null
                ? null
                : RussianDateLabels.shortTime(arrival),
            onTap: departure == null
                ? null
                : () => pickTripArrivalTime(
                    context,
                    controller: controller,
                    arrival: arrival,
                    now: _now,
                  ),
            trailing: const _FieldIcon(Icons.schedule_rounded),
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
