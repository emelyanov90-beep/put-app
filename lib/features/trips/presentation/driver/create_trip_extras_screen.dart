import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/features/trips/application/trip_draft_controller.dart';
import 'package:vput/features/trips/data/preview_parcel_size_specs.dart';
import 'package:vput/features/trips/data/preview_trip_publication_settings.dart';
import 'package:vput/features/trips/domain/passenger_trip.dart';
import 'package:vput/features/trips/domain/trip_draft.dart';
import 'package:vput/features/trips/presentation/widgets/create_trip_controls.dart';
import 'package:vput/features/trips/presentation/widgets/parcel_options_sheet.dart';

/// Step 5: services the driver takes along. Prices come from the catalogue —
/// the driver only switches a service on, and picks parcel sizes in a sheet.
class CreateTripExtrasScreen extends ConsumerWidget {
  const CreateTripExtrasScreen({
    required this.onBack,
    required this.onContinue,
    this.isEditing = false,
    super.key,
  });

  static const parcelRowKey = Key('create_trip_parcel_row');

  static Key extraSwitchKey(TripExtraService service) =>
      Key('create_trip_extra_${service.name}');

  final VoidCallback onBack;
  final VoidCallback onContinue;
  final bool isEditing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(tripDraftProvider);
    final controller = ref.read(tripDraftProvider.notifier);
    final prices = ref.watch(tripExtraServicePricesProvider);
    final parcel = draft.parcel;

    return CreateTripStepScaffold(
      step: 5,
      onBack: onBack,
      primaryLabel: isEditing ? 'Сохранить' : 'Далее',
      onPrimary: onContinue,
      children: [
        CreateTripSection(
          title: 'Дополнительные услуги',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final service in tripSeatExtraServices)
                _ExtraRow(
                  switchKey: extraSwitchKey(service),
                  icon: _serviceIcon(service),
                  title: _serviceTitle(service),
                  price: prices[service],
                  value: draft.extraFor(service).enabled,
                  onChanged: (enabled) =>
                      controller.setExtraEnabled(service, enabled),
                ),
              _ParcelRow(
                priceLabel: _parcelPriceLabel(draft),
                onTap: () async {
                  final updated = await ParcelOptionsSheet.show(
                    context,
                    offer: parcel,
                  );
                  if (updated == null) return;
                  controller.setParcel(updated);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// «до 350₽» while no size is chosen, then the price of the cheapest one.
  static String _parcelPriceLabel(TripDraft draft) {
    final prices = draft.parcel.priceBySize.values;
    if (prices.isEmpty) return 'до $previewMaxParcelPrice₽';
    return '${prices.reduce((a, b) => a < b ? a : b)}₽';
  }

  static String _serviceTitle(TripExtraService service) {
    return switch (service) {
      TripExtraService.childSeat => 'Детское кресло',
      TripExtraService.luggage => 'Багаж',
      TripExtraService.pets => 'Животные',
      TripExtraService.parcel => 'Посылка',
    };
  }

  static IconData _serviceIcon(TripExtraService service) {
    return switch (service) {
      TripExtraService.childSeat => Icons.child_friendly_rounded,
      TripExtraService.luggage => Icons.work_rounded,
      TripExtraService.pets => Icons.pets_rounded,
      TripExtraService.parcel => Icons.inventory_2_rounded,
    };
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
    return _RowFrame(
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.accentBlack),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.accentBlack,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.38,
              ),
            ),
          ),
          if (price != null) ...[
            Text(
              '+$price₽',
              style: const TextStyle(
                color: AppColors.brandGreen,
                fontSize: 15,
                height: 1.33,
              ),
            ),
            const SizedBox(width: 20),
          ],
          CreateTripSwitch(
            switchKey: switchKey,
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ParcelRow extends StatelessWidget {
  const _ParcelRow({required this.priceLabel, required this.onTap});

  final String priceLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: CreateTripExtrasScreen.parcelRowKey,
      onTap: onTap,
      child: _RowFrame(
        last: true,
        child: Row(
          children: [
            const Icon(
              Icons.inventory_2_rounded,
              size: 18,
              color: AppColors.accentBlack,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Посылка',
                style: TextStyle(
                  color: AppColors.accentBlack,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.38,
                ),
              ),
            ),
            Text(
              priceLabel,
              style: const TextStyle(
                color: AppColors.brandGreen,
                fontSize: 15,
                height: 1.33,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.accentBlack,
            ),
          ],
        ),
      ),
    );
  }
}

class _RowFrame extends StatelessWidget {
  const _RowFrame({required this.child, this.last = false});

  final Widget child;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: child,
    );
  }
}
