import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/features/trips/application/trip_draft_controller.dart';
import 'package:vput/features/trips/data/preview_trip_publication_settings.dart';
import 'package:vput/features/trips/presentation/widgets/create_trip_controls.dart';
import 'package:vput/features/trips/presentation/widgets/trip_money_breakdown_card.dart';

/// Step 3: what the driver earns on the whole route, between stops and for a
/// boarding, with the platform commission shown on top of it.
class CreateTripPricingScreen extends ConsumerStatefulWidget {
  const CreateTripPricingScreen({
    required this.onBack,
    required this.onContinue,
    this.isEditing = false,
    super.key,
  });

  static const fullRouteFieldKey = Key('create_trip_full_price');
  static const minimumFieldKey = Key('create_trip_minimum_price');
  static const moneyBreakdownKey = TripMoneyBreakdownCard.cardKey;

  static Key segmentFieldKey(int index) => Key('create_trip_segment_$index');

  final VoidCallback onBack;
  final VoidCallback onContinue;
  final bool isEditing;

  @override
  ConsumerState<CreateTripPricingScreen> createState() =>
      _CreateTripPricingScreenState();
}

class _CreateTripPricingScreenState
    extends ConsumerState<CreateTripPricingScreen> {
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
    final commission = ref.watch(tripCommissionPolicyProvider);
    _syncSegmentControllers(draft.segmentPrices);
    final points = draft.points;
    final fullRoutePrice = draft.fullRoutePrice;

    return CreateTripStepScaffold(
      step: 3,
      onBack: widget.onBack,
      primaryLabel: widget.isEditing ? 'Сохранить' : 'Далее',
      onPrimary: draft.isPricingValid ? widget.onContinue : null,
      children: [
        if (fullRoutePrice != null && fullRoutePrice > 0) ...[
          TripMoneyBreakdownCard(
            breakdown: commission.breakdownFor(fullRoutePrice),
          ),
          const SizedBox(height: 20),
        ],
        CreateTripSection(
          title: 'Стоимость',
          padded: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PriceCard(
                title: 'Весь маршрут',
                children: [
                  _PriceRow(
                    from: points.first.address,
                    to: points.last.address,
                    fieldKey: CreateTripPricingScreen.fullRouteFieldKey,
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
                        fieldKey: CreateTripPricingScreen.segmentFieldKey(
                          index,
                        ),
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
                    fieldKey: CreateTripPricingScreen.minimumFieldKey,
                    controller: _minimumController,
                    onChanged: controller.setMinimumBoardingPrice,
                  ),
                ],
              ),
            ],
          ),
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
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.38,
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

/// A route line above the price it is charged for.
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (origin != null && destination != null) ...[
          _RouteLine(from: origin, to: destination),
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

class _RouteLine extends StatelessWidget {
  const _RouteLine({required this.from, required this.to});

  final String from;
  final String to;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: AppColors.textSecondary,
      fontSize: 13,
      height: 1.38,
    );
    return Row(
      children: [
        Flexible(
          child: Text(
            from,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
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
            to,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
    );
  }
}
