import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/app/widgets/screen_header.dart';
import 'package:vput/core/utils/russian_date_labels.dart';
import 'package:vput/features/trips/data/preview_trip_publication_settings.dart';
import 'package:vput/features/trips/domain/driver_trip.dart';

/// The decision screen: the trip, the part of it the passenger asks for, and
/// the two answers the driver can give.
class DriverBookingRequestScreen extends ConsumerStatefulWidget {
  const DriverBookingRequestScreen({
    required this.trip,
    required this.booking,
    required this.onBack,
    required this.onApprove,
    required this.onReject,
    this.onOpenPassenger,
    super.key,
  });

  static const stopsToggleKey = Key('booking_request_stops');
  static const approveButtonKey = Key('booking_request_approve');
  static const rejectButtonKey = Key('booking_request_reject');
  static const passengerButtonKey = Key('booking_request_passenger');

  final DriverTrip trip;
  final DriverTripPassengerBooking booking;
  final VoidCallback onBack;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  /// Opens the passenger profile, as the booking rules allow before deciding.
  final VoidCallback? onOpenPassenger;

  @override
  ConsumerState<DriverBookingRequestScreen> createState() =>
      _DriverBookingRequestScreenState();
}

class _DriverBookingRequestScreenState
    extends ConsumerState<DriverBookingRequestScreen> {
  bool _stopsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final draft = trip.draft;
    final commission = ref.watch(tripCommissionPolicyProvider);
    final total = draft.fullRoutePrice ?? 0;
    final money = commission.breakdownFor(total);
    final departure = draft.departureAt;
    final arrival = draft.arrivalAt;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ScreenHeader(
                title: 'Поездка',
                onBack: widget.onBack,
                trailing: widget.onOpenPassenger == null
                    ? null
                    : Center(
                        child: SizedBox.square(
                          dimension: 40,
                          child: IconButton.filled(
                            key: DriverBookingRequestScreen.passengerButtonKey,
                            onPressed: widget.onOpenPassenger,
                            tooltip: 'Профиль пассажира',
                            padding: EdgeInsets.zero,
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.surfaceMuted,
                              foregroundColor: AppColors.accentBlack,
                              shape: const CircleBorder(),
                            ),
                            icon: const Icon(
                              Icons.more_horiz_rounded,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _MoneyTile(
                            label: 'Стоимость',
                            value: '${money.total} ₽',
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _MoneyTile(
                            label: 'Комиссия',
                            value: '${money.commission} ₽',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _OutlinedCard(
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'К оплате водителю',
                              style: TextStyle(
                                color: AppColors.accentBlack,
                                fontSize: 15,
                                height: 1.33,
                              ),
                            ),
                          ),
                          Text(
                            '${money.driverAmount} ₽',
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
                    const SizedBox(height: 20),
                    const _SectionTitle('Маршрут поездки'),
                    const SizedBox(height: 12),
                    _TripRouteCard(
                      trip: trip,
                      stopsExpanded: _stopsExpanded,
                      onToggleStops: () =>
                          setState(() => _stopsExpanded = !_stopsExpanded),
                    ),
                    const SizedBox(height: 20),
                    const _SectionTitle('Маршрут пассажира'),
                    const SizedBox(height: 12),
                    _PassengerRouteCard(trip: trip, booking: widget.booking),
                    const SizedBox(height: 12),
                    _WhiteCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _MoneyTile(
                                  label: 'Дата и время',
                                  value: departure == null
                                      ? 'Не указаны'
                                      : RussianDateLabels.dateAndTime(
                                          departure,
                                        ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: _MoneyTile(
                                  label: 'Мест для пассажиров',
                                  value:
                                      '${trip.freeSeatCount} из '
                                      '${draft.seatCount}',
                                ),
                              ),
                            ],
                          ),
                          if (arrival != null) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(
                                  Icons.schedule_rounded,
                                  size: 18,
                                  color: AppColors.accentBlack,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Прибытие ~${RussianDateLabels.time(arrival)}',
                                  style: const TextStyle(
                                    color: AppColors.accentBlack,
                                    fontSize: 15,
                                    height: 1.33,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        key: DriverBookingRequestScreen.rejectButtonKey,
                        onPressed: widget.onReject,
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
                        child: const Text('Отклонить бронь'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: FilledButton(
                        key: DriverBookingRequestScreen.approveButtonKey,
                        onPressed: widget.onApprove,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.brandGreen,
                          foregroundColor: AppColors.accentWhite,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Подтвердить бронь'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.accentBlack,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.33,
      ),
    );
  }
}

class _MoneyTile extends StatelessWidget {
  const _MoneyTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return _OutlinedCard(
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

class _OutlinedCard extends StatelessWidget {
  const _OutlinedCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.accentWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: child,
    );
  }
}

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

/// Full route of the trip: the ends always visible, the stops behind a chip.
class _TripRouteCard extends StatelessWidget {
  const _TripRouteCard({
    required this.trip,
    required this.stopsExpanded,
    required this.onToggleStops,
  });

  final DriverTrip trip;
  final bool stopsExpanded;
  final VoidCallback onToggleStops;

  @override
  Widget build(BuildContext context) {
    final stops = trip.draft.intermediateStops;
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RoutePoint(
            marker: const _OriginMarker(),
            text: trip.draft.origin.address,
          ),
          if (stops.isNotEmpty) ...[
            const _Connector(),
            _RoutePoint(
              marker: const _StopMarker(),
              child: _StopsChip(
                count: stops.length,
                expanded: stopsExpanded,
                onPressed: onToggleStops,
              ),
            ),
            if (stopsExpanded)
              for (final stop in stops) ...[
                const _Connector(),
                _RoutePoint(
                  marker: const _StopMarker(),
                  text: stop.address,
                  small: true,
                ),
              ],
          ],
          const _Connector(),
          _RoutePoint(
            marker: const _DestinationMarker(),
            text: trip.draft.destination.address,
          ),
        ],
      ),
    );
  }
}

/// The part of the route the passenger asks for: where they get on and off.
class _PassengerRouteCard extends StatelessWidget {
  const _PassengerRouteCard({required this.trip, required this.booking});

  final DriverTrip trip;
  final DriverTripPassengerBooking booking;

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PassengerPoint(
            label: 'Точка посадки',
            value: booking.pickupAddress ?? trip.draft.origin.address,
          ),
          const _Connector(),
          _PassengerPoint(
            label: 'Точка высадки',
            value: booking.dropoffAddress ?? trip.draft.destination.address,
          ),
        ],
      ),
    );
  }
}

class _PassengerPoint extends StatelessWidget {
  const _PassengerPoint({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 20),
          child: _OriginMarker(),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.only(bottom: 6),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.accentBlack)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.33,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.accentBlack,
                    fontSize: 15,
                    height: 1.33,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RoutePoint extends StatelessWidget {
  const _RoutePoint({
    required this.marker,
    this.text,
    this.child,
    this.small = false,
  });

  final Widget marker;
  final String? text;
  final Widget? child;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final label = text;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(width: 10, child: Center(child: marker)),
        const SizedBox(width: 8),
        Expanded(
          child:
              child ??
              Text(
                label ?? '',
                style: TextStyle(
                  color: AppColors.accentBlack,
                  fontSize: small ? 13 : 15,
                  height: small ? 1.38 : 1.33,
                ),
              ),
        ),
      ],
    );
  }
}

class _StopsChip extends StatelessWidget {
  const _StopsChip({
    required this.count,
    required this.expanded,
    required this.onPressed,
  });

  final int count;
  final bool expanded;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        key: DriverBookingRequestScreen.stopsToggleKey,
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 24),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          foregroundColor: AppColors.brandGreen,
          side: const BorderSide(color: AppColors.brandGreen),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
        iconAlignment: IconAlignment.end,
        icon: Icon(
          expanded
              ? Icons.keyboard_arrow_up_rounded
              : Icons.keyboard_arrow_down_rounded,
          size: 12,
        ),
        label: Text('$count ${_stopsWord(count)}'),
      ),
    );
  }

  static String _stopsWord(int count) {
    final mod100 = count % 100;
    final mod10 = count % 10;
    if (mod100 >= 11 && mod100 <= 14) return 'остановок';
    if (mod10 == 1) return 'остановка';
    if (mod10 >= 2 && mod10 <= 4) return 'остановки';
    return 'остановок';
  }
}

class _Connector extends StatelessWidget {
  const _Connector();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 10,
      height: 22,
      child: Center(child: _DashedLine()),
    );
  }
}

class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 1,
      height: 22,
      child: CustomPaint(painter: _DashPainter()),
    );
  }
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF898A8D)
      ..strokeWidth = 1;
    for (var y = 0.0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(0, y + 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OriginMarker extends StatelessWidget {
  const _OriginMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: AppColors.accentBlack,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _DestinationMarker extends StatelessWidget {
  const _DestinationMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        border: Border.all(width: 2, color: AppColors.accentBlack),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _StopMarker extends StatelessWidget {
  const _StopMarker();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: 6,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.textSecondary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
