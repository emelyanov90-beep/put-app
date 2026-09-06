import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/features/trips/application/passenger_order_draft_controller.dart';
import 'package:vput/features/trips/data/preview_parcel_size_specs.dart';
import 'package:vput/features/trips/data/preview_trip_publication_settings.dart';
import 'package:vput/features/trips/domain/passenger_trip.dart';
import 'package:vput/features/trips/domain/trip_draft.dart';
import 'package:vput/features/trips/domain/trip_extras.dart';
import 'package:vput/features/trips/presentation/widgets/create_trip_controls.dart';
import 'package:vput/features/trips/presentation/widgets/order_extra_labels.dart';

/// Step 3 of the passenger «Новый заказ» wizard.
///
/// A seat order picks the services it needs on the way; a parcel order picks
/// the size to send. Prices come from the platform catalogue, exactly as they
/// do for the driver — the passenger never types a price.
class PassengerOrderExtrasScreen extends ConsumerWidget {
  const PassengerOrderExtrasScreen({
    required this.onBack,
    required this.onContinue,
    super.key,
  });

  static Key extraSwitchKey(TripExtraService service) =>
      Key('passenger_order_extra_${service.name}');

  static Key parcelSizeKey(ParcelSize size) =>
      Key('passenger_order_parcel_${size.name}');

  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(passengerOrderDraftProvider);
    final controller = ref.read(passengerOrderDraftProvider.notifier);
    final prices = ref.watch(tripExtraServicePricesProvider);

    return CreateTripStepScaffold(
      step: 3,
      stepCount: passengerOrderStepCount,
      onBack: onBack,
      primaryLabel: 'Далее',
      onPrimary: draft.areExtrasValid ? onContinue : null,
      footnote: draft.isParcelOrder
          ? 'Стоимость зависит от размера и указана за одну посылку.'
          : 'Услуги оплачиваются вместе с местом. Мы покажем только те поездки, '
                'где водитель их предоставляет.',
      children: [
        if (draft.isParcelOrder)
          CreateTripSection(
            title: 'Размер посылки',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final spec in previewParcelSizeSpecs) ...[
                  if (spec != previewParcelSizeSpecs.first)
                    const Divider(height: 1, color: AppColors.divider),
                  _ParcelSizeRow(
                    rowKey: parcelSizeKey(spec.size),
                    spec: spec,
                    selected: draft.parcelSize == spec.size,
                    onTap: () => controller.setParcelSize(spec.size),
                  ),
                ],
              ],
            ),
          )
        else
          CreateTripSection(
            title: 'Дополнительные услуги',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final service in tripSeatExtraServices)
                  _ExtraRow(
                    switchKey: extraSwitchKey(service),
                    icon: orderExtraIcon(service),
                    title: orderExtraTitle(service),
                    price: prices[service],
                    value: draft.extras.contains(service),
                    onChanged: (selected) =>
                        controller.setExtraSelected(service, selected),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ExtraRow extends StatelessWidget {
  const _ExtraRow({
    required this.switchKey,
    required this.icon,
    required this.title,
    required this.price,
    required this.value,
    required this.onChanged,
  });

  final Key switchKey;
  final IconData icon;
  final String title;
  final int? price;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 24, color: AppColors.accentBlack),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.accentBlack,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.33,
                  ),
                ),
                if (price != null)
                  Text(
                    '$price₽',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.38,
                    ),
                  ),
              ],
            ),
          ),
          Switch(
            key: switchKey,
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.accentWhite,
            activeTrackColor: AppColors.brandGreen,
          ),
        ],
      ),
    );
  }
}

class _ParcelSizeRow extends StatelessWidget {
  const _ParcelSizeRow({
    required this.rowKey,
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  final Key rowKey;
  final ParcelSizeSpec spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        key: rowKey,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 22,
                color: selected ? AppColors.brandGreen : AppColors.divider,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spec.title,
                      style: const TextStyle(
                        color: AppColors.accentBlack,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.33,
                      ),
                    ),
                    Text(
                      spec.dimensionsLabel,
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
              Text(
                '${spec.priceRubles}₽',
                style: const TextStyle(
                  color: AppColors.accentBlack,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.33,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
