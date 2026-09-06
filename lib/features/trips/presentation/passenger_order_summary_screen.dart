import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/core/utils/russian_date_labels.dart';
import 'package:vput/features/trips/application/passenger_order_draft_controller.dart';
import 'package:vput/features/trips/data/preview_parcel_size_specs.dart';
import 'package:vput/features/trips/domain/passenger_order_draft.dart';
import 'package:vput/features/trips/presentation/widgets/create_trip_controls.dart';
import 'package:vput/features/trips/presentation/widgets/order_extra_labels.dart';
import 'package:vput/features/trips/presentation/widgets/trip_route_timeline.dart';

/// Step 4 of the passenger «Новый заказ» wizard: the order as it stands, and
/// the hand-off to the trips that match it.
///
/// A passenger order is a search for a published trip, not a second kind of
/// trip: the primary action applies the route and transport as filters and
/// opens «Поездки». Booking itself stays in the trip details flow, so the
/// passenger never leaves the wizard with something the backend has not seen.
class PassengerOrderSummaryScreen extends ConsumerWidget {
  const PassengerOrderSummaryScreen({
    required this.onBack,
    required this.onFindTrips,
    super.key,
  });

  static const findTripsButtonKey = CreateTripStepScaffold.primaryButtonKey;

  final VoidCallback onBack;
  final ValueChanged<PassengerOrderDraft> onFindTrips;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(passengerOrderDraftProvider);
    final departure = draft.departureAt;
    final arrival = draft.arrivalAt;

    return CreateTripStepScaffold(
      step: 4,
      stepCount: passengerOrderStepCount,
      onBack: onBack,
      primaryLabel: 'Найти поездки',
      onPrimary: () => onFindTrips(draft),
      footnote:
          'Мы подберём опубликованные поездки по этому маршруту. '
          'Место или посылку вы забронируете в карточке поездки.',
      children: [
        CreateTripSection(
          title: 'Маршрут',
          child: TripRouteTimeline(
            origin: draft.points.first.address,
            destination: draft.points.last.address,
            intermediateStopCount: draft.points.length - 2,
            intermediateStops: [
              for (final point
                  in draft.points.skip(1).take(draft.points.length - 2))
                point.address,
            ],
            showIntermediateStops: draft.points.length > 2,
          ),
        ),
        CreateTripSection(
          title: 'Заказ',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SummaryRow(
                label: 'Тип заказа',
                value: draft.isParcelOrder
                    ? 'Автобус, посылка'
                    : 'Автомобиль, место',
              ),
              if (departure != null)
                _SummaryRow(
                  label: 'Выезд',
                  value: RussianDateLabels.dateAndTime(departure),
                ),
              if (arrival != null)
                _SummaryRow(
                  label: 'Прибытие',
                  value: RussianDateLabels.dateAndTime(arrival),
                ),
              if (draft.isParcelOrder)
                _SummaryRow(label: 'Размер посылки', value: _parcelLabel(draft))
              else
                _SummaryRow(
                  label: 'Пассажиров',
                  value: '${draft.passengerCount}',
                ),
            ],
          ),
        ),
        if (!draft.isParcelOrder)
          CreateTripSection(
            title: 'Дополнительные услуги',
            child: draft.extras.isEmpty
                ? const Text(
                    'Не выбраны',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.38,
                    ),
                  )
                : Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      for (final service in draft.extras)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              orderExtraIcon(service),
                              size: 18,
                              color: AppColors.accentBlack,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              orderExtraTitle(service),
                              style: const TextStyle(
                                color: AppColors.accentBlack,
                                fontSize: 13,
                                height: 1.38,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
          ),
      ],
    );
  }

  static String _parcelLabel(PassengerOrderDraft draft) {
    final size = draft.parcelSize;
    if (size == null) return 'Не выбран';
    final spec = previewParcelSizeSpec(size);
    return '${spec.title}, ${spec.priceRubles}₽';
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.38,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.accentBlack,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.38,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
