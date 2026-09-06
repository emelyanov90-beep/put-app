import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/features/trips/application/trip_draft_controller.dart';
import 'package:vput/features/trips/domain/trip_fare_table.dart';
import 'package:vput/features/trips/presentation/widgets/create_trip_controls.dart';

/// The fare fields of a trip: the whole route, every other pair of points, and
/// the boarding price. Shared by «Новый заказ» step 3 and «Изменение
/// стоимости», so both price a trip the same way.
///
/// One field per pair on purpose — the driver sets no rate per kilometre,
/// because a short leg is dearer per kilometre than a long one.
class TripFareFields extends ConsumerStatefulWidget {
  const TripFareFields({required this.keyPrefix, super.key});

  /// Prefix of the field keys, so the two screens stay addressable apart.
  final String keyPrefix;

  static Key fullRouteFieldKey(String prefix) => Key('${prefix}_full_price');
  static Key minimumFieldKey(String prefix) => Key('${prefix}_minimum_price');
  static Key legFieldKey(String prefix, TripFareLeg leg) =>
      Key('${prefix}_fare_${leg.key}');

  @override
  ConsumerState<TripFareFields> createState() => _TripFareFieldsState();
}

class _TripFareFieldsState extends ConsumerState<TripFareFields> {
  final _legControllers = <TripFareLeg, TextEditingController>{};
  late final TextEditingController _minimumController;

  @override
  void initState() {
    super.initState();
    _minimumController = TextEditingController(
      text: ref.read(tripDraftProvider).minimumBoardingPrice?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    for (final controller in _legControllers.values) {
      controller.dispose();
    }
    _minimumController.dispose();
    super.dispose();
  }

  /// Keeps one controller per existing leg: new legs get a field, and the
  /// controllers of legs that a removed stop took away are disposed.
  TextEditingController _controllerFor(TripFareLeg leg, int? price) {
    final existing = _legControllers[leg];
    if (existing != null) return existing;
    final controller = TextEditingController(text: price?.toString() ?? '');
    _legControllers[leg] = controller;
    return controller;
  }

  void _pruneControllers(Set<TripFareLeg> legs) {
    final stale = _legControllers.keys
        .where((leg) => !legs.contains(leg))
        .toList(growable: false);
    for (final leg in stale) {
      _legControllers.remove(leg)!.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(tripDraftProvider);
    final controller = ref.read(tripDraftProvider.notifier);
    final points = draft.points;
    final legs = draft.fareLegs;
    _pruneControllers(legs.toSet());

    final fullRoute = TripFareLeg(0, points.length - 1);
    final otherLegs = legs
        .where((leg) => leg != fullRoute)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TripFareCard(
          title: 'Весь маршрут',
          children: [
            TripFareRow(
              from: points.first.address,
              to: points.last.address,
              fieldKey: TripFareFields.fullRouteFieldKey(widget.keyPrefix),
              controller: _controllerFor(
                fullRoute,
                draft.fares.priceFor(fullRoute.fromIndex, fullRoute.toIndex),
              ),
              onChanged: controller.setFullRoutePrice,
            ),
          ],
        ),
        if (otherLegs.isNotEmpty) ...[
          const SizedBox(height: 12),
          TripFareCard(
            title: 'Между остановками',
            subtitle:
                'Цена задаётся для каждой пары точек отдельно. Чем короче '
                'участок, тем дороже километр — единой ставки за километр нет.',
            children: [
              for (final leg in otherLegs)
                TripFareRow(
                  from: points[leg.fromIndex].address,
                  to: points[leg.toIndex].address,
                  fieldKey: TripFareFields.legFieldKey(widget.keyPrefix, leg),
                  controller: _controllerFor(
                    leg,
                    draft.fares.priceFor(leg.fromIndex, leg.toIndex),
                  ),
                  onChanged: (value) =>
                      controller.setLegPrice(leg.fromIndex, leg.toIndex, value),
                ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        TripFareCard(
          title: 'Стоимость посадки',
          children: [
            TripFareRow(
              fieldKey: TripFareFields.minimumFieldKey(widget.keyPrefix),
              controller: _minimumController,
              onChanged: controller.setMinimumBoardingPrice,
            ),
          ],
        ),
      ],
    );
  }
}

/// White card grouping a set of fare fields under a caption.
class TripFareCard extends StatelessWidget {
  const TripFareCard({
    required this.title,
    required this.children,
    this.subtitle,
    super.key,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final hint = subtitle;
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
            if (hint != null) ...[
              const SizedBox(height: 6),
              Text(
                hint,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.38,
                ),
              ),
            ],
            const SizedBox(height: 12),
            for (final child in children) ...[
              if (child != children.first) const SizedBox(height: 8),
              child,
            ],
          ],
        ),
      ),
    );
  }
}

/// A route line above the price charged for it.
class TripFareRow extends StatelessWidget {
  const TripFareRow({
    required this.fieldKey,
    required this.controller,
    required this.onChanged,
    this.from,
    this.to,
    super.key,
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
