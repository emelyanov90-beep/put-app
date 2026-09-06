import 'package:flutter/material.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/features/trips/domain/trip_commission.dart';
import 'package:vput/features/trips/presentation/widgets/create_trip_controls.dart';

/// «Общая стоимость / Комиссия / Вы получите» — what the passenger pays, what
/// the platform keeps and what stays with the driver.
class TripMoneyBreakdownCard extends StatelessWidget {
  const TripMoneyBreakdownCard({required this.breakdown, super.key});

  static const cardKey = Key('create_trip_money_breakdown');

  final TripMoneyBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: cardKey,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _Tile(
                  label: 'Общая стоимость',
                  value: '${breakdown.total} ₽',
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _Tile(
                  label: 'Комиссия',
                  value: '${breakdown.commission} ₽',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _OutlinedTile(
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Вы получите',
                    style: TextStyle(
                      color: AppColors.accentBlack,
                      fontSize: 15,
                      height: 1.33,
                    ),
                  ),
                ),
                Text(
                  '${breakdown.driverAmount} ₽',
                  style: const TextStyle(
                    color: AppColors.accentBlack,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.29,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return _OutlinedTile(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.accentBlack,
              fontSize: 13,
              height: 1.38,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.accentBlack,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.33,
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlinedTile extends StatelessWidget {
  const _OutlinedTile({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CreateTripCard(
      padding: const EdgeInsets.all(8),
      borderRadius: 8,
      border: true,
      child: child,
    );
  }
}
