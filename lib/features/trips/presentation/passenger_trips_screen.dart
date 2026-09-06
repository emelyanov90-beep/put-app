import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/features/system/presentation/system_failure_view.dart';
import 'package:vput/features/system/presentation/system_loading_screen.dart';
import 'package:vput/features/trips/application/passenger_trip_search_controller.dart';
import 'package:vput/features/trips/domain/passenger_trip.dart';
import 'package:vput/features/trips/presentation/trip_filters_sheet.dart';
import 'package:vput/features/trips/presentation/widgets/passenger_bottom_bar.dart';
import 'package:vput/features/trips/presentation/widgets/trip_route_timeline.dart';

class PassengerTripsScreen extends ConsumerWidget {
  const PassengerTripsScreen({
    required this.onOrders,
    required this.onCreate,
    required this.onChats,
    required this.onProfile,
    required this.onTripSelected,
    super.key,
  });

  static const titleKey = Key('passenger_trips_title');
  static const filterButtonKey = Key('passenger_trips_filter');
  static const filterActiveBadgeKey = Key('passenger_trips_filter_badge');
  static const carTabKey = Key('passenger_trips_car_tab');
  static const busTabKey = Key('passenger_trips_bus_tab');
  static const emptyStateKey = Key('passenger_trips_empty');
  static const emptyImageKey = Key('passenger_trips_empty_image');
  static const registrationStatusKey = Key(
    'passenger_trip_registration_status',
  );

  static Key tripCardKey(String id) => ValueKey('passenger_trip_card_$id');

  final VoidCallback onOrders;
  final VoidCallback onCreate;
  final VoidCallback onChats;
  final VoidCallback onProfile;
  final ValueChanged<PassengerTrip> onTripSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: AppColors.background,
    );
    final searchState = ref.watch(passengerTripSearchProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _TripsHeader(
                onFilter: () => _openFilters(context, ref, searchState),
                filtersActive: searchState.hasFilters,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _TransportTabs(
                  selected: searchState.transportType,
                  onSelected: ref
                      .read(passengerTripSearchProvider.notifier)
                      .selectTransport,
                ),
              ),
              Expanded(
                child: switch (searchState.status) {
                  PassengerTripSearchStatus.empty => const _EmptyTripsState(),
                  PassengerTripSearchStatus.loading =>
                    const SystemLoadingView(),
                  PassengerTripSearchStatus.data => ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    itemCount: searchState.trips.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final trip = searchState.trips[index];
                      return _TripCard(
                        trip: trip,
                        onTap: () => onTripSelected(trip),
                      );
                    },
                  ),
                  PassengerTripSearchStatus.error => SystemFailureView(
                    onRetry: ref
                        .read(passengerTripSearchProvider.notifier)
                        .retry,
                  ),
                },
              ),
            ],
          ),
        ),
        bottomNavigationBar: PassengerBottomBar(
          currentItem: PassengerNavigationItem.trips,
          onTrips: () {},
          onOrders: onOrders,
          onCreate: onCreate,
          onChats: onChats,
          onProfile: onProfile,
        ),
      ),
    );
  }

  Future<void> _openFilters(
    BuildContext context,
    WidgetRef ref,
    PassengerTripSearchState state,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.accentBlack.withValues(alpha: .42),
      builder: (sheetContext) => TripFiltersSheet(
        initialOrigin: state.originQuery,
        initialDestination: state.destinationQuery,
        onClear: () {
          ref.read(passengerTripSearchProvider.notifier).clearFilters();
        },
        onApply: (origin, destination) {
          ref
              .read(passengerTripSearchProvider.notifier)
              .applyFilters(origin: origin, destination: destination);
          Navigator.of(sheetContext).pop();
        },
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip, required this.onTap});

  final PassengerTrip trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isRegistrationInProgress = trip.isPassengerRegistrationInProgress;

    return Material(
      key: PassengerTripsScreen.tripCardKey(trip.id),
      color: AppColors.accentWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isRegistrationInProgress
            ? const BorderSide(color: AppColors.brandGreen)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 19,
                    backgroundColor: Color(0xFFE9EEF0),
                    child: Icon(
                      Icons.person_rounded,
                      color: Color(0xFF898A8D),
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.driverName,
                          style: const TextStyle(
                            color: AppColors.accentBlack,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.33,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFF2C500),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                trip.driverRatingLabel,
                                style: const TextStyle(
                                  color: Color(0xFF61636B),
                                  fontSize: 13,
                                  height: 1.38,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '≈ ${trip.distanceKm.toStringAsFixed(1)} км',
                          style: const TextStyle(
                            color: Color(0xFF61636B),
                            fontSize: 13,
                            height: 1.38,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _PriorityBadge(badge: trip.priorityBadge),
                ],
              ),
              const SizedBox(height: 14),
              TripRouteTimeline(
                origin: trip.origin.address,
                destination: trip.destination.address,
                intermediateStopCount: trip.intermediateStopCount,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 17,
                    color: Color(0xFF898A8D),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    trip.arrivalLabel,
                    style: const TextStyle(
                      color: AppColors.accentBlack,
                      fontSize: 15,
                      height: 1.33,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  for (final service in trip.services.take(2))
                    _ServiceLabel(service: service),
                  if (trip.hasAvailableSeats)
                    _ServiceTextLabel(
                      icon: Icons.person_rounded,
                      text:
                          '${trip.availableSeats} ${trip.availableSeats == 1 ? 'место' : 'места'}',
                    ),
                ],
              ),
              if (isRegistrationInProgress) ...[
                const SizedBox(height: 10),
                const Text(
                  'Идёт регистрация пассажиров',
                  key: PassengerTripsScreen.registrationStatusKey,
                  style: TextStyle(
                    color: AppColors.brandGreen,
                    fontSize: 15,
                    height: 1.33,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.divider),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      size: 18,
                      color: Color(0xFF898A8D),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        trip.departureLabel,
                        style: const TextStyle(
                          color: AppColors.accentBlack,
                          fontSize: 15,
                          height: 1.33,
                        ),
                      ),
                    ),
                    Text(
                      '${trip.priceRubles} ₽',
                      style: const TextStyle(
                        color: AppColors.accentBlack,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const Text(
                      ' /чел',
                      style: TextStyle(
                        color: Color(0xFF61636B),
                        fontSize: 15,
                        height: 1.33,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.badge});

  final TripPriorityBadge badge;

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (badge) {
      TripPriorityBadge.top => (Icons.star_rounded, 'Топ'),
      TripPriorityBadge.nearest => (Icons.schedule_rounded, 'Ближайший'),
    };

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.brandGreen),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.accentBlack),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.accentBlack,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceLabel extends StatelessWidget {
  const _ServiceLabel({required this.service});

  final TripExtraService service;

  @override
  Widget build(BuildContext context) {
    final (icon, text) = switch (service) {
      TripExtraService.pets => (Icons.pets_rounded, 'С животными'),
      TripExtraService.luggage => (Icons.work_rounded, 'С багажом'),
      TripExtraService.childSeat => (
        Icons.child_friendly_rounded,
        'Дет. кресло',
      ),
      TripExtraService.parcel => (Icons.inventory_2_rounded, 'Посылка'),
    };
    return _ServiceTextLabel(icon: icon, text: text);
  }
}

class _ServiceTextLabel extends StatelessWidget {
  const _ServiceTextLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: const Color(0xFF898A8D)),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.accentBlack,
            fontSize: 15,
            height: 1.33,
          ),
        ),
      ],
    );
  }
}

class _TripsHeader extends StatelessWidget {
  const _TripsHeader({required this.onFilter, required this.filtersActive});

  final VoidCallback onFilter;
  final bool filtersActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 56),
          const Expanded(
            child: Text(
              'Поездки',
              key: PassengerTripsScreen.titleKey,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.accentBlack,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),
          SizedBox(
            width: 56,
            height: 48,
            child: Center(
              child: SizedBox.square(
                dimension: 40,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: IconButton.filled(
                        key: PassengerTripsScreen.filterButtonKey,
                        tooltip: 'Фильтры',
                        onPressed: onFilter,
                        padding: EdgeInsets.zero,
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surfaceMuted,
                          foregroundColor: const Color(0xFF898A8D),
                        ),
                        icon: const Icon(Icons.filter_alt_rounded, size: 24),
                      ),
                    ),
                    if (filtersActive)
                      Positioned(
                        key: PassengerTripsScreen.filterActiveBadgeKey,
                        top: 2,
                        right: 2,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppColors.errorBackground,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransportTabs extends StatelessWidget {
  const _TransportTabs({required this.selected, required this.onSelected});

  final PassengerTransportType selected;
  final ValueChanged<PassengerTransportType> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.accentSurface,
        border: Border.all(color: const Color(0xFFC8C8C8)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TransportTab(
              key: PassengerTripsScreen.carTabKey,
              label: 'Автомобили',
              selected: selected == PassengerTransportType.car,
              onTap: () => onSelected(PassengerTransportType.car),
            ),
          ),
          Expanded(
            child: _TransportTab(
              key: PassengerTripsScreen.busTabKey,
              label: 'Автобусы',
              selected: selected == PassengerTransportType.bus,
              onTap: () => onSelected(PassengerTransportType.bus),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransportTab extends StatelessWidget {
  const _TransportTab({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.brandGreen : Colors.transparent,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.accentWhite : const Color(0xFF61636B),
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.33,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyTripsState extends StatelessWidget {
  const _EmptyTripsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Transform.translate(
        offset: const Offset(0, -14),
        child: Padding(
          key: PassengerTripsScreen.emptyStateKey,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'docs/imgs/order.png',
                key: PassengerTripsScreen.emptyImageKey,
                width: 90,
                height: 80,
                fit: BoxFit.fill,
              ),
              const SizedBox(height: 8),
              const Text(
                'Здесь ещё нет заказов',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.accentBlack,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  height: 1.29,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Станьте первым — создайте поездку или\nпроверьте чуть позже',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
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
