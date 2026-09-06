import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/core/utils/russian_date_labels.dart';
import 'package:vput/features/onboarding/application/onboarding_draft_controller.dart';
import 'package:vput/features/profile/presentation/widgets/profile_section_scaffold.dart';
import 'package:vput/features/system/presentation/system_failure_view.dart';
import 'package:vput/features/system/presentation/system_loading_screen.dart';
import 'package:vput/features/trips/application/driver_trips_controller.dart';
import 'package:vput/features/trips/application/passenger_orders_provider.dart';
import 'package:vput/features/trips/domain/driver_trip.dart';
import 'package:vput/features/trips/domain/passenger_order.dart';

/// «История заказов»: what is already behind the user.
///
/// A passenger sees completed orders, a driver sees completed trips — the same
/// records the active lists show, just past ones, so nothing is stored twice.
class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({
    required this.onBack,
    required this.onOrderSelected,
    required this.onTripSelected,
    super.key,
  });

  static Key orderKey(String id) => Key('order_history_$id');

  final VoidCallback onBack;
  final ValueChanged<PassengerOrder> onOrderSelected;
  final ValueChanged<DriverTrip> onTripSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDriver =
        ref.watch(onboardingDraftProvider.select((draft) => draft.role)) ==
        OnboardingRole.driver;
    return isDriver ? _driverHistory(context, ref) : _passengerHistory(ref);
  }

  Widget _driverHistory(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final trips = ref
        .watch(driverTripsProvider)
        .where((trip) => trip.isCompleted(now))
        .toList(growable: false);
    return ProfileSectionScaffold(
      title: 'История заказов',
      onBack: onBack,
      children: [
        if (trips.isEmpty)
          const _EmptyHistory()
        else
          for (var index = 0; index < trips.length; index++) ...[
            if (index > 0) const SizedBox(height: 10),
            _HistoryCard(
              cardKey: orderKey(trips[index].id),
              route: trips[index].routeLabel,
              subtitle: _departureLabel(trips[index]),
              status: trips[index].statusLabel(now),
              priceRubles: trips[index].draft.fullRoutePrice ?? 0,
              onTap: () => onTripSelected(trips[index]),
            ),
          ],
      ],
    );
  }

  static String _departureLabel(DriverTrip trip) {
    final departure = trip.draft.departureAt;
    return departure == null
        ? 'Дата не указана'
        : RussianDateLabels.dateAndTime(departure);
  }

  Widget _passengerHistory(WidgetRef ref) {
    return ref
        .watch(passengerOrdersProvider)
        .when(
          loading: () => const Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(child: SystemLoadingView()),
          ),
          error: (_, _) => Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: SystemFailureView(
                onRetry: () => ref.invalidate(passengerOrdersProvider),
              ),
            ),
          ),
          data: (orders) {
            final completed = orders
                .where((order) => order.isCompleted)
                .toList(growable: false);
            return ProfileSectionScaffold(
              title: 'История заказов',
              onBack: onBack,
              children: [
                if (completed.isEmpty)
                  const _EmptyHistory()
                else
                  for (var index = 0; index < completed.length; index++) ...[
                    if (index > 0) const SizedBox(height: 10),
                    _HistoryCard(
                      cardKey: orderKey(completed[index].id),
                      route:
                          '${completed[index].trip.origin.address} → '
                          '${completed[index].trip.destination.address}',
                      subtitle: completed[index].departureWindowLabel,
                      status: completed[index].statusLabel,
                      priceRubles: completed[index].priceRubles,
                      onTap: () => onOrderSelected(completed[index]),
                    ),
                  ],
              ],
            );
          },
        );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const ProfileEmptyState(
      icon: Icons.receipt_long_rounded,
      title: 'История пуста',
      description:
          'Завершённые поездки и заказы появятся здесь после их окончания.',
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.cardKey,
    required this.route,
    required this.subtitle,
    required this.status,
    required this.priceRubles,
    required this.onTap,
  });

  final Key cardKey;
  final String route;
  final String subtitle;
  final String status;
  final int priceRubles;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ProfileCard(
      padded: false,
      child: InkWell(
        key: cardKey,
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                route,
                style: const TextStyle(
                  color: AppColors.accentBlack,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.33,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.38,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      status,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.38,
                      ),
                    ),
                  ),
                  Text(
                    '$priceRubles ₽',
                    style: const TextStyle(
                      color: AppColors.accentBlack,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.33,
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
