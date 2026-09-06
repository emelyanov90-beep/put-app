import 'package:flutter/material.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/features/trips/data/preview_parcel_size_specs.dart';
import 'package:vput/features/trips/domain/trip_extras.dart';
import 'package:vput/features/trips/presentation/widgets/create_trip_controls.dart';

/// Tint of a chosen row in the design.
const _selectedTint = Color(0xFFE9F6EE);

/// Parcel settings of the trip: the sizes the driver carries and whether a
/// parcel may travel without its owner.
class ParcelOptionsSheet extends StatefulWidget {
  const ParcelOptionsSheet({required this.offer, super.key});

  static const sheetKey = Key('parcel_options_sheet');
  static const withoutPassengerKey = Key('parcel_without_passenger');
  static const cancelButtonKey = Key('parcel_cancel');
  static const addButtonKey = Key('parcel_add');

  static Key sizeKey(ParcelSize size) => Key('parcel_size_${size.name}');

  final TripParcelOffer offer;

  /// Returns the new settings, or `null` when the driver cancels.
  static Future<TripParcelOffer?> show(
    BuildContext context, {
    required TripParcelOffer offer,
  }) {
    return showModalBottomSheet<TripParcelOffer>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ParcelOptionsSheet(offer: offer),
    );
  }

  @override
  State<ParcelOptionsSheet> createState() => _ParcelOptionsSheetState();
}

class _ParcelOptionsSheetState extends State<ParcelOptionsSheet> {
  late final Map<ParcelSize, int> _prices = {...widget.offer.priceBySize};
  late bool _withoutPassenger = widget.offer.allowedWithoutPassenger;

  void _toggleSize(ParcelSizeSpec spec) {
    setState(() {
      if (_prices.containsKey(spec.size)) {
        _prices.remove(spec.size);
      } else {
        _prices[spec.size] = spec.priceRubles;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      key: ParcelOptionsSheet.sheetKey,
      color: AppColors.background,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              const Text(
                'Посылка',
                style: TextStyle(
                  color: AppColors.accentBlack,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  height: 1.29,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Укажите размер вашей посылки',
                style: TextStyle(
                  color: Color(0xFF95969C),
                  fontSize: 15,
                  height: 1.33,
                ),
              ),
              const SizedBox(height: 12),
              for (final spec in previewParcelSizeSpecs) ...[
                if (spec != previewParcelSizeSpecs.first)
                  const SizedBox(height: 8),
                _SizeRow(
                  spec: spec,
                  selected: _prices.containsKey(spec.size),
                  onTap: () => _toggleSize(spec),
                ),
              ],
              const SizedBox(height: 16),
              _WithoutPassengerRow(
                value: _withoutPassenger,
                onChanged: (value) => setState(() => _withoutPassenger = value),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        key: ParcelOptionsSheet.cancelButtonKey,
                        onPressed: () => Navigator.of(context).pop(),
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
                        key: ParcelOptionsSheet.addButtonKey,
                        onPressed: _prices.isEmpty
                            ? null
                            : () => Navigator.of(context).pop(
                                TripParcelOffer(
                                  enabled: true,
                                  priceBySize: _prices,
                                  allowedWithoutPassenger: _withoutPassenger,
                                ),
                              ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.brandGreen,
                          foregroundColor: AppColors.accentWhite,
                          disabledBackgroundColor: AppColors.surfaceMuted,
                          disabledForegroundColor: const Color(0xFF95969C),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Добавить'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SizeRow extends StatelessWidget {
  const _SizeRow({
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  final ParcelSizeSpec spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        key: ParcelOptionsSheet.sizeKey(spec.size),
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: selected ? _selectedTint : AppColors.accentWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.brandGreen : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              // Foundation placeholder: the design shows a photo of the boot
              // with a parcel in it; no such asset is in the repository yet.
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 56,
                  height: 44,
                  color: AppColors.surfaceMuted,
                  child: const Icon(
                    Icons.inventory_2_rounded,
                    size: 22,
                    color: AppColors.textSecondary,
                  ),
                ),
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
                    const SizedBox(height: 2),
                    Text(
                      spec.dimensionsLabel,
                      style: const TextStyle(
                        color: Color(0xFF95969C),
                        fontSize: 13,
                        height: 1.38,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '+${spec.priceRubles}₽',
                style: const TextStyle(
                  color: AppColors.brandGreen,
                  fontSize: 15,
                  height: 1.33,
                ),
              ),
              const SizedBox(width: 8),
              _CheckMark(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckMark extends StatelessWidget {
  const _CheckMark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 20,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? AppColors.brandGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(width: 1.5, color: AppColors.brandGreen),
        ),
        child: selected
            ? const Icon(
                Icons.check_rounded,
                size: 14,
                color: AppColors.accentWhite,
              )
            : null,
      ),
    );
  }
}

class _WithoutPassengerRow extends StatelessWidget {
  const _WithoutPassengerRow({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(
            Icons.person_off_rounded,
            size: 18,
            color: AppColors.accentBlack,
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Без проезда пассажира',
                style: TextStyle(
                  color: AppColors.accentBlack,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.38,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Можно отправить только посылку, без места в авто',
                style: TextStyle(
                  color: Color(0xFF95969C),
                  fontSize: 13,
                  height: 1.38,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        CreateTripSwitch(
          switchKey: ParcelOptionsSheet.withoutPassengerKey,
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
