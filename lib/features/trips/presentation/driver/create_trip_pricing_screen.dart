import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/features/trips/application/trip_draft_controller.dart';
import 'package:vput/features/trips/data/preview_trip_publication_settings.dart';
import 'package:vput/features/trips/domain/trip_fare_table.dart';
import 'package:vput/features/trips/presentation/widgets/create_trip_controls.dart';
import 'package:vput/features/trips/presentation/widgets/trip_fare_fields.dart';
import 'package:vput/features/trips/presentation/widgets/trip_money_breakdown_card.dart';

/// Step 3: what the driver earns on the whole route, on every other pair of
/// points and for a boarding, with the platform commission added on top.
class CreateTripPricingScreen extends ConsumerWidget {
  const CreateTripPricingScreen({
    required this.onBack,
    required this.onContinue,
    this.isEditing = false,
    super.key,
  });

  static const keyPrefix = 'create_trip';

  static final fullRouteFieldKey = TripFareFields.fullRouteFieldKey(keyPrefix);
  static final minimumFieldKey = TripFareFields.minimumFieldKey(keyPrefix);
  static const moneyBreakdownKey = TripMoneyBreakdownCard.cardKey;

  static Key legFieldKey(int fromIndex, int toIndex) =>
      TripFareFields.legFieldKey(keyPrefix, TripFareLeg(fromIndex, toIndex));

  final VoidCallback onBack;
  final VoidCallback onContinue;
  final bool isEditing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(tripDraftProvider);
    final commission = ref.watch(tripCommissionPolicyProvider);
    final fullRoutePrice = draft.fullRoutePrice;

    return CreateTripStepScaffold(
      step: 3,
      onBack: onBack,
      primaryLabel: isEditing ? 'Сохранить' : 'Далее',
      onPrimary: draft.isPricingValid ? onContinue : null,
      children: [
        if (fullRoutePrice != null && fullRoutePrice > 0) ...[
          TripMoneyBreakdownCard(
            breakdown: commission.breakdownFor(fullRoutePrice),
            commissionPercent: commission.percent,
          ),
          const SizedBox(height: 20),
        ],
        CreateTripSection(
          title: 'Стоимость',
          padded: false,
          child: const TripFareFields(keyPrefix: keyPrefix),
        ),
      ],
    );
  }
}
