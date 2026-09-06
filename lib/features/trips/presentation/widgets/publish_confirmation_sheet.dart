import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/core/utils/russian_date_labels.dart';
import 'package:vput/features/trips/application/trip_draft_controller.dart';
import 'package:vput/features/trips/domain/trip_draft.dart';

/// Last look at the trip before it goes live.
class PublishConfirmationSheet extends ConsumerStatefulWidget {
  const PublishConfirmationSheet({super.key});

  static const sheetKey = Key('publish_confirmation_sheet');
  static const confirmButtonKey = Key('publish_confirmation_confirm');
  static const cancelButtonKey = Key('publish_confirmation_cancel');
  static const segmentsToggleKey = Key('publish_confirmation_segments');

  /// Resolves to `true` when the driver confirms the publication.
  static Future<bool> show(BuildContext context) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const PublishConfirmationSheet(),
    );
    return confirmed ?? false;
  }

  @override
  ConsumerState<PublishConfirmationSheet> createState() =>
      _PublishConfirmationSheetState();
}

class _PublishConfirmationSheetState
    extends ConsumerState<PublishConfirmationSheet> {
  bool _segmentsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(tripDraftProvider);
    final vehicle = ref.watch(selectedDriverVehicleProvider);
    final departure = draft.departureAt;
    final extras = _enabledExtras(draft);

    return Material(
      key: PublishConfirmationSheet.sheetKey,
      color: AppColors.background,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Опубликовать поездку?',
                      style: TextStyle(
                        color: AppColors.accentBlack,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        height: 1.29,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'После публикации пассажиры смогут увидеть и '
                      'забронировать места. Изменить поездку можно будет до '
                      'того, как присоединится первый пассажир.',
                      style: TextStyle(
                        color: Color(0xFF95969C),
                        fontSize: 15,
                        height: 1.33,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Container(
                    color: AppColors.accentWhite,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Row(
                          label: 'Точка посадки',
                          value: draft.origin.address,
                          onTap: _close,
                        ),
                        _Row(
                          label: 'Пункт назначения',
                          value: draft.destination.address,
                          onTap: _close,
                        ),
                        _Row(
                          label: 'Доп. остановки',
                          value: '${draft.intermediateStops.length}',
                          onTap: _close,
                        ),
                        _Row(
                          label: 'Дата и время',
                          value: departure == null
                              ? 'Не указаны'
                              : '${RussianDateLabels.numericDate(departure)}, '
                                    '${RussianDateLabels.time(departure)}',
                          onTap: _close,
                        ),
                        _Row(
                          label: 'Стоимость поездки',
                          value: _price(draft.fullRoutePrice),
                          strong: true,
                        ),
                        if (draft.segmentCount > 1) ...[
                          _SegmentsToggle(
                            expanded: _segmentsExpanded,
                            onPressed: () => setState(
                              () => _segmentsExpanded = !_segmentsExpanded,
                            ),
                          ),
                          if (_segmentsExpanded)
                            for (final leg in draft.fareLegs)
                              if (leg.fromIndex != 0 ||
                                  leg.toIndex != draft.segmentCount)
                                _Row(
                                  label:
                                      '${draft.points[leg.fromIndex].address} – '
                                      '${draft.points[leg.toIndex].address}',
                                  value:
                                      draft.fares.priceFor(
                                            leg.fromIndex,
                                            leg.toIndex,
                                          ) ==
                                          null
                                      ? '—'
                                      : '${draft.fares.priceFor(leg.fromIndex, leg.toIndex)}₽',
                                  labelOnTop: true,
                                ),
                        ],
                        _Row(
                          label: 'Цена доп. услуг',
                          value: '${_extrasPrice(draft)} ₽',
                          onTap: _close,
                        ),
                        _Row(
                          label: 'Автомобиль',
                          value: vehicle == null
                              ? 'Не выбран'
                              : '${vehicle.title}, ${vehicle.plateNumber}',
                          onTap: _close,
                        ),
                        _Row(
                          label: 'Доп услуги',
                          value: '$extras',
                          onTap: _close,
                        ),
                        _Row(
                          label: 'Тип бронирования',
                          value: draft.bookingMode == TripBookingMode.standard
                              ? 'Стандартное'
                              : 'Быстрое бронирование',
                          onTap: _close,
                          last: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          key: PublishConfirmationSheet.cancelButtonKey,
                          onPressed: _close,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.brandGreen,
                            side: const BorderSide(color: AppColors.brandGreen),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: const Text('Отмена'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: FilledButton(
                          key: PublishConfirmationSheet.confirmButtonKey,
                          onPressed: () => Navigator.of(context).pop(true),
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
                          child: const Text('Да, опубликовать'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _close() => Navigator.of(context).pop(false);

  static String _price(int? value) => value == null ? 'Не указана' : '$value ₽';

  /// Number of services the trip carries: seat extras plus the parcel.
  static int _enabledExtras(TripDraft draft) {
    var count = 0;
    for (final service in tripSeatExtraServices) {
      if (draft.extraFor(service).enabled) count++;
    }
    if (draft.parcel.enabled) count++;
    return count;
  }

  /// Everything the extras add up to: seat services plus the priciest parcel
  /// size the driver accepts.
  static int _extrasPrice(TripDraft draft) {
    var total = 0;
    for (final service in tripSeatExtraServices) {
      total += draft.extraFor(service).price ?? 0;
    }
    final parcelPrices = draft.parcel.priceBySize.values;
    if (parcelPrices.isNotEmpty) {
      total += parcelPrices.reduce((a, b) => a > b ? a : b);
    }
    return total;
  }
}

class _SegmentsToggle extends StatelessWidget {
  const _SegmentsToggle({required this.expanded, required this.onPressed});

  final bool expanded;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Между остановками',
              style: TextStyle(
                color: AppColors.accentBlack,
                fontSize: 15,
                height: 1.33,
              ),
            ),
          ),
          OutlinedButton.icon(
            key: PublishConfirmationSheet.segmentsToggleKey,
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: AppColors.brandGreen,
              side: const BorderSide(color: AppColors.brandGreen),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            iconAlignment: IconAlignment.end,
            icon: Icon(
              expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 14,
            ),
            label: const Text('Смотреть стоимость'),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.onTap,
    this.strong = false,
    this.last = false,
    this.labelOnTop = false,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool strong;
  final bool last;

  /// Segment rows put the long route label above the price.
  final bool labelOnTop;

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      color: strong ? AppColors.accentBlack : const Color(0xFF95969C),
      fontSize: 15,
      height: 1.33,
    );
    final valueStyle = TextStyle(
      color: AppColors.accentBlack,
      fontSize: 15,
      fontWeight: strong ? FontWeight.w700 : FontWeight.w400,
      height: 1.33,
    );

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: labelOnTop ? 3 : 2,
              child: Text(label, style: labelStyle),
            ),
            const SizedBox(width: 12),
            Flexible(
              flex: 2,
              child: Text(
                value,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: valueStyle,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
