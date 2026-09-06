import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/core/utils/russian_date_labels.dart';
import 'package:vput/features/trips/application/trip_draft_controller.dart';
import 'package:vput/features/trips/data/preview_parcel_size_specs.dart';
import 'package:vput/features/trips/data/preview_trip_publication_settings.dart';
import 'package:vput/features/trips/domain/passenger_trip.dart';
import 'package:vput/features/trips/domain/trip_draft.dart';
import 'package:vput/features/trips/domain/trip_commission.dart';
import 'package:vput/features/trips/domain/trip_publication_limits.dart';
import 'package:vput/features/trips/domain/trip_route_point.dart';
import 'package:vput/features/trips/presentation/widgets/create_trip_controls.dart';

/// Final screen of the wizard: everything the driver entered, a way back into
/// any step, the publication limits and the publish action.
class CreateTripSummaryScreen extends ConsumerWidget {
  const CreateTripSummaryScreen({
    required this.onBack,
    required this.onPublish,
    required this.onSaveDraft,
    this.onEditType,
    this.onEditRoute,
    this.onEditSchedule,
    this.onEditPricing,
    this.onEditVehicle,
    this.onEditServices,
    this.onEditExtras,
    this.onEditBookingMode,
    this.now,
    super.key,
  });

  static const publishButtonKey = CreateTripStepScaffold.primaryButtonKey;
  static const saveDraftButtonKey = CreateTripStepScaffold.secondaryButtonKey;
  static const limitNoticeKey = Key('create_trip_limit_notice');
  static const editTypeKey = Key('create_trip_edit_type');
  static const editRouteKey = Key('create_trip_edit_route');
  static const editPricingKey = Key('create_trip_edit_pricing');
  static const editVehicleKey = Key('create_trip_edit_vehicle');
  static const editServicesKey = Key('create_trip_edit_services');

  final VoidCallback onBack;
  final VoidCallback onPublish;
  final VoidCallback onSaveDraft;
  final VoidCallback? onEditType;
  final VoidCallback? onEditRoute;
  final VoidCallback? onEditSchedule;
  final VoidCallback? onEditPricing;
  final VoidCallback? onEditVehicle;
  final VoidCallback? onEditServices;
  final VoidCallback? onEditExtras;
  final VoidCallback? onEditBookingMode;

  /// Injectable clock; defaults to the real one.
  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moment = now ?? DateTime.now();
    final draft = ref.watch(tripDraftProvider);
    final vehicle = ref.watch(selectedDriverVehicleProvider);
    final commission = ref.watch(tripCommissionPolicyProvider);
    final limits = ref.watch(tripPublicationLimitsProvider);
    final usage = ref.watch(tripPublicationUsageProvider);
    final block = usage.blockFor(limits);
    final issues = draft.issues(now: moment);
    final canPublish =
        issues.isEmpty &&
        block == null &&
        ref.watch(tripDraftVehicleReadyProvider);
    final departure = draft.departureAt;
    final arrival = draft.arrivalAt;
    final editType = onEditType ?? onEditBookingMode ?? _noop;
    final editRoute = onEditRoute ?? onEditSchedule ?? _noop;
    final editPricing = onEditPricing ?? onEditVehicle ?? _noop;
    final editVehicle = onEditVehicle ?? onEditPricing ?? _noop;
    final editServices = onEditServices ?? onEditExtras ?? _noop;

    return CreateTripStepScaffold(
      title: 'Проверьте заказ',
      onBack: onBack,
      primaryLabel: 'Опубликовать',
      onPrimary: canPublish ? onPublish : null,
      secondaryLabel: 'Сохранить черновик',
      onSecondary: draft.canSave ? onSaveDraft : null,
      footnote: _limitFootnote(limits, usage),
      children: [
        if (block != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: _Notice(
              noticeKey: limitNoticeKey,
              text: switch (block) {
                TripPublicationBlock.directionLimit =>
                  'На сегодня в этом направлении уже есть публикация. '
                      'Сохраните поездку и опубликуйте её завтра.',
                TripPublicationBlock.dailyLimit =>
                  'Достигнут дневной лимит публикаций: ${limits.perDay} в '
                      'сутки. Опубликуйте заказ завтра.',
                TripPublicationBlock.weeklyLimit =>
                  'Достигнут недельный лимит публикаций: ${limits.perWeek} в '
                      'неделю.',
              },
            ),
          )
        else if (issues.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: _Notice(text: 'Заполните: ${_issueLabels(issues)}.'),
          ),
        _SummarySection(
          title: 'Тип заказа',
          editKey: editTypeKey,
          onEdit: editType,
          children: [
            _SummaryRow(
              label: 'Транспорт',
              value: draft.transportType == PassengerTransportType.car
                  ? 'Автомобиль'
                  : 'Автобус',
            ),
          ],
        ),
        _SummarySection(
          title: 'Маршрут',
          editKey: editRouteKey,
          onEdit: editRoute,
          children: [
            for (var index = 0; index < draft.points.length; index++)
              _SummaryRow(
                label: switch (draft.kindAt(index)) {
                  TripStopKind.origin => 'Откуда',
                  TripStopKind.destination => 'Куда',
                  TripStopKind.intermediate => 'Остановка',
                },
                value: draft.points[index].address.isEmpty
                    ? 'Не указано'
                    : draft.points[index].address,
              ),
            _SummaryRow(
              label: 'Выезд',
              value: departure == null
                  ? 'Не указан'
                  : RussianDateLabels.dateAndTime(departure),
            ),
            _SummaryRow(
              label: 'Прибытие',
              value: arrival == null
                  ? 'Не указано'
                  : RussianDateLabels.dateAndTime(arrival),
            ),
            _SummaryRow(label: 'Количество мест', value: '${draft.seatCount}'),
          ],
        ),
        _SummarySection(
          title: 'Стоимость и автомобиль',
          editKey: editPricingKey,
          onEdit: editPricing,
          children: [
            ..._moneyRows(draft.fullRoutePrice, commission),
            _SummaryRow(
              label: 'Весь маршрут',
              value: _price(draft.fullRoutePrice),
            ),
            if (draft.segmentCount > 1)
              for (var index = 0; index < draft.segmentCount; index++)
                _SummaryRow(
                  label:
                      '${draft.points[index].address} → '
                      '${draft.points[index + 1].address}',
                  value: _price(draft.segmentPrices[index]),
                ),
            _SummaryRow(
              label: 'Стоимость посадки',
              value: _price(draft.minimumBoardingPrice),
            ),
          ],
        ),
        _SummarySection(
          title: 'Автомобиль',
          editKey: editVehicleKey,
          onEdit: editVehicle,
          children: [
            _SummaryRow(
              label: 'Авто',
              value: vehicle == null
                  ? 'Не выбрано'
                  : '${vehicle.title} · ${vehicle.plateNumber}',
            ),
          ],
        ),
        _SummarySection(
          title: 'Услуги и бронирование',
          editKey: editServicesKey,
          onEdit: editServices,
          children: [
            ..._extraRows(draft),
            _SummaryRow(
              label: 'Бронирование',
              value: draft.bookingMode == TripBookingMode.standard
                  ? 'Стандартное'
                  : 'Быстрое бронирование',
            ),
          ],
        ),
      ],
    );
  }

  /// What the passenger pays and what stays with the driver, as on step 3.
  static List<Widget> _moneyRows(
    int? fullRoutePrice,
    TripCommissionPolicy commission,
  ) {
    if (fullRoutePrice == null || fullRoutePrice <= 0) return const [];
    final money = commission.breakdownFor(fullRoutePrice);
    return [
      _SummaryRow(label: 'Общая стоимость', value: '${money.total} ₽'),
      _SummaryRow(label: 'Комиссия', value: '${money.commission} ₽'),
      _SummaryRow(label: 'Вы получите', value: '${money.driverAmount} ₽'),
    ];
  }

  static List<Widget> _extraRows(TripDraft draft) {
    final rows = <Widget>[
      for (final service in tripSeatExtraServices)
        if (draft.extraFor(service).enabled)
          _SummaryRow(
            label: switch (service) {
              TripExtraService.childSeat => 'Детское кресло',
              TripExtraService.pets => 'Провоз животных',
              TripExtraService.luggage => 'Провоз багажа',
              TripExtraService.parcel => 'Провоз посылки',
            },
            value: _price(draft.extraFor(service).price),
          ),
      if (draft.parcel.enabled)
        for (final spec in previewParcelSizeSpecs)
          if (draft.parcel.acceptsSize(spec.size))
            _SummaryRow(
              label: 'Посылка ${spec.title}',
              value: _price(draft.parcel.priceBySize[spec.size]),
            ),
      if (draft.parcel.enabled && draft.parcel.allowedWithoutPassenger)
        const _SummaryRow(label: 'Посылка без пассажира', value: 'Да'),
    ];
    return rows.isEmpty
        ? const [_SummaryRow(label: 'Услуги', value: 'Не выбраны')]
        : rows;
  }

  static String _price(int? value) => value == null ? 'Не указана' : '$value ₽';

  static String _issueLabels(Set<TripDraftIssue> issues) {
    const labels = <TripDraftIssue, String>{
      TripDraftIssue.route: 'маршрут',
      TripDraftIssue.schedule: 'дату и время',
      TripDraftIssue.seats: 'количество мест',
      TripDraftIssue.pricing: 'стоимость',
      TripDraftIssue.extras: 'стоимость дополнительных услуг',
      TripDraftIssue.vehicle: 'автомобиль',
    };
    return issues.map((issue) => labels[issue]!).join(', ');
  }

  static String _limitFootnote(
    TripPublicationLimits limits,
    TripPublicationUsage usage,
  ) {
    return 'Сегодня опубликовано ${usage.publishedToday} из ${limits.perDay} · '
        'за неделю ${usage.publishedThisWeek} из ${limits.perWeek}';
  }

  static void _noop() {}
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({
    required this.title,
    required this.editKey,
    required this.onEdit,
    required this.children,
  });

  final String title;
  final Key editKey;
  final VoidCallback onEdit;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.accentBlack,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.33,
                    ),
                  ),
                ),
                TextButton(
                  key: editKey,
                  onPressed: onEdit,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(64, 32),
                    foregroundColor: AppColors.brandGreen,
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Изменить'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CreateTripCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ],
      ),
    );
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

class _Notice extends StatelessWidget {
  const _Notice({required this.text, this.noticeKey});

  final String text;
  final Key? noticeKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: noticeKey,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorText.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.errorText,
          fontSize: 13,
          height: 1.38,
        ),
      ),
    );
  }
}
