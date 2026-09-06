import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/features/trips/application/driver_trips_controller.dart';
import 'package:vput/features/trips/application/trip_draft_controller.dart';
import 'package:vput/features/trips/presentation/widgets/create_trip_controls.dart';

/// «Изменение стоимости» — the fares of a saved trip: the whole route, every
/// leg between stops and the boarding price.
class EditTripPricingScreen extends ConsumerStatefulWidget {
  const EditTripPricingScreen({
    required this.onBack,
    required this.onSave,
    super.key,
  });

  static const fullRouteFieldKey = Key('edit_trip_full_price');
  static const minimumFieldKey = Key('edit_trip_minimum_price');
  static const saveButtonKey = CreateTripStepScaffold.primaryButtonKey;

  static Key segmentFieldKey(int index) => Key('edit_trip_segment_$index');

  final VoidCallback onBack;
  final VoidCallback onSave;

  @override
  ConsumerState<EditTripPricingScreen> createState() =>
      _EditTripPricingScreenState();
}

class _EditTripPricingScreenState extends ConsumerState<EditTripPricingScreen> {
  late final TextEditingController _fullRouteController;
  late final TextEditingController _minimumController;
  final _segmentControllers = <TextEditingController>[];

  @override
  void initState() {
    super.initState();
    final draft = ref.read(tripDraftProvider);
    _fullRouteController = TextEditingController(
      text: draft.fullRoutePrice?.toString() ?? '',
    );
    _minimumController = TextEditingController(
      text: draft.minimumBoardingPrice?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _fullRouteController.dispose();
    _minimumController.dispose();
    for (final controller in _segmentControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _syncSegmentControllers(List<int?> prices) {
    while (_segmentControllers.length < prices.length) {
      final index = _segmentControllers.length;
      _segmentControllers.add(
        TextEditingController(text: prices[index]?.toString() ?? ''),
      );
    }
    while (_segmentControllers.length > prices.length) {
      _segmentControllers.removeLast().dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(tripDraftProvider);
    final controller = ref.read(tripDraftProvider.notifier);
    final hasChanges = ref.watch(tripDraftHasChangesProvider);
    _syncSegmentControllers(draft.segmentPrices);
    final points = draft.points;

    return CreateTripStepScaffold(
      title: 'Изменение стоимости',
      onBack: widget.onBack,
      primaryLabel: 'Сохранить',
      onPrimary: hasChanges && draft.isPricingValid ? widget.onSave : null,
      children: [
        _PriceCard(
          title: 'Весь маршрут',
          children: [
            _PriceRow(
              from: points.first.address,
              to: points.last.address,
              fieldKey: EditTripPricingScreen.fullRouteFieldKey,
              controller: _fullRouteController,
              onChanged: controller.setFullRoutePrice,
            ),
          ],
        ),
        if (draft.segmentCount > 1) ...[
          const SizedBox(height: 12),
          _PriceCard(
            title: 'Между остановками',
            children: [
              for (var index = 0; index < draft.segmentCount; index++)
                _PriceRow(
                  from: points[index].address,
                  to: points[index + 1].address,
                  fieldKey: EditTripPricingScreen.segmentFieldKey(index),
                  controller: _segmentControllers[index],
                  onChanged: (value) =>
                      controller.setSegmentPrice(index, value),
                ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        _PriceCard(
          title: 'Стоимость посадки',
          children: [
            _PriceRow(
              fieldKey: EditTripPricingScreen.minimumFieldKey,
              controller: _minimumController,
              onChanged: controller.setMinimumBoardingPrice,
            ),
          ],
        ),
      ],
    );
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CreateTripCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            const SizedBox(height: 12),
            for (final child in children) ...[
              if (child != children.first) const SizedBox(height: 4),
              child,
            ],
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.fieldKey,
    required this.controller,
    required this.onChanged,
    this.from,
    this.to,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final ValueChanged<int?> onChanged;
  final String? from;
  final String? to;

  @override
  Widget build(BuildContext context) {
    final origin = from;
    final destination = to;
    const routeStyle = TextStyle(
      color: AppColors.textSecondary,
      fontSize: 13,
      height: 1.38,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (origin != null && destination != null) ...[
          Row(
            children: [
              Flexible(
                child: Text(
                  origin,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: routeStyle,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              Flexible(
                child: Text(
                  destination,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: routeStyle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        CreateTripPriceField(
          fieldKey: fieldKey,
          controller: controller,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
