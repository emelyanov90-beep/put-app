import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/app/widgets/screen_header.dart';
import 'package:vput/features/trips/domain/passenger_booking_request.dart';
import 'package:vput/features/trips/domain/passenger_trip.dart';
import 'package:vput/features/trips/presentation/booking/passenger_booking_sheet.dart';
import 'package:vput/features/trips/presentation/booking/passenger_parcel_sheet.dart';
import 'package:vput/features/trips/presentation/widgets/trip_route_timeline.dart';

class TripDetailsScreen extends StatelessWidget {
  const TripDetailsScreen({
    required this.trip,
    required this.onBack,
    required this.onDriver,
    required this.onBookingSubmitted,
    required this.onParcelSubmitted,
    this.isBooking = false,
    super.key,
  });

  static const routeCardKey = Key('trip_details_route');
  static const driverCardKey = Key('trip_details_driver');
  static const bookSeatButtonKey = Key('trip_details_book_seat');
  static const sendParcelButtonKey = Key('trip_details_send_parcel');

  final bool isBooking;
  final PassengerTrip trip;
  final VoidCallback onBack;
  final VoidCallback onDriver;
  final ValueChanged<PassengerBookingRequest> onBookingSubmitted;
  final ValueChanged<PassengerParcelRequest> onParcelSubmitted;

  @override
  Widget build(BuildContext context) {
    const overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.accentWhite,
      systemNavigationBarIconBrightness: Brightness.dark,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              ScreenHeader(title: 'Поездка', onBack: onBack),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(0, 20, 0, 132),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionTitle('Маршрут'),
                      const SizedBox(height: 12),
                      _RouteCard(trip: trip),
                      const SizedBox(height: 12),
                      _TripInfoCard(trip: trip),
                      const SizedBox(height: 22),
                      const _SectionTitle('Водитель'),
                      const SizedBox(height: 12),
                      _DriverCard(trip: trip, onDriver: onDriver),
                      const SizedBox(height: 12),
                      _PriceCard(trip: trip),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _TripActions(
          hasAvailableSeats: trip.hasAvailableSeats,
          isBooking: isBooking,
          acceptsParcels: trip.acceptsParcels,
          onBookSeat: () => _openBooking(context),
          onSendParcel: () => _openParcel(context),
        ),
      ),
    );
  }

  Future<void> _openBooking(BuildContext context) async {
    final request = await showModalBottomSheet<PassengerBookingRequest>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PassengerBookingSheet(trip: trip),
    );
    if (request == null || !context.mounted) return;
    onBookingSubmitted(request);
  }

  Future<void> _openParcel(BuildContext context) async {
    final request = await showModalBottomSheet<PassengerParcelRequest>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PassengerParcelSheet(trip: trip),
    );
    if (request == null || !context.mounted) return;
    onParcelSubmitted(request);
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.accentBlack,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.trip});

  final PassengerTrip trip;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: TripDetailsScreen.routeCardKey,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: _RoadWatermark()),
          TripRouteTimeline(
            origin: trip.origin.address,
            destination: trip.destination.address,
            intermediateStopCount: trip.intermediateStopCount,
            expandedStopButton: true,
            intermediateStops: trip.stops
                .skip(1)
                .take(trip.intermediateStopCount)
                .map((stop) => stop.address)
                .toList(growable: false),
            showIntermediateStops: trip.hasAvailableSeats,
          ),
        ],
      ),
    );
  }
}

class _RoadWatermark extends StatelessWidget {
  const _RoadWatermark();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(child: CustomPaint(painter: _RoadWatermarkPainter()));
  }
}

class _RoadWatermarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * .58, -12)
      ..cubicTo(
        size.width * 1.08,
        size.height * .12,
        size.width * .55,
        size.height * .33,
        size.width * .72,
        size.height * .58,
      )
      ..cubicTo(
        size.width * .86,
        size.height * .78,
        size.width * .97,
        size.height * .78,
        size.width * 1.08,
        size.height * 1.04,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFF1F2F3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 48
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TripInfoCard extends StatelessWidget {
  const _TripInfoCard({required this.trip});

  final PassengerTrip trip;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  label: 'Дата и время',
                  value: trip.detailsDepartureLabel,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoTile(
                  label: 'Мест свободно',
                  value: '${trip.availableSeats} из ${trip.totalSeats}',
                  valueColor: trip.hasAvailableSeats
                      ? AppColors.accentBlack
                      : AppColors.errorText,
                ),
              ),
            ],
          ),
          if (trip.services.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 13,
              runSpacing: 9,
              children: [
                for (final service in trip.services)
                  _DetailService(service: service),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
    this.valueColor = AppColors.accentBlack,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, height: 1.2),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailService extends StatelessWidget {
  const _DetailService({required this.service});

  final TripExtraService service;

  @override
  Widget build(BuildContext context) {
    final (icon, text) = switch (service) {
      TripExtraService.luggage => (Icons.work_rounded, 'С багажом'),
      TripExtraService.pets => (Icons.pets_rounded, 'С животными'),
      TripExtraService.childSeat => (
        Icons.child_friendly_rounded,
        'Дет. кресло',
      ),
      TripExtraService.parcel => (Icons.inventory_2_rounded, 'Посылка S, M'),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: const Color(0xFF898A8D)),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 15, height: 1.3)),
      ],
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.trip, required this.onDriver});

  final PassengerTrip trip;
  final VoidCallback onDriver;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: TripDetailsScreen.driverCardKey,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 23,
                backgroundColor: Color(0xFFE9EEF0),
                child: Icon(
                  Icons.person_rounded,
                  color: Color(0xFF898A8D),
                  size: 30,
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
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFF2C500),
                          size: 18,
                        ),
                        Text(
                          trip.driverRatingLabel,
                          style: const TextStyle(
                            color: Color(0xFF61636B),
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton.outlined(
                onPressed: onDriver,
                icon: const Icon(Icons.chevron_right_rounded),
                style: IconButton.styleFrom(
                  foregroundColor: AppColors.accentBlack,
                  side: const BorderSide(color: AppColors.divider),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              height: 150,
              color: AppColors.surfaceMuted,
              child: Image.asset(trip.vehicle.photoAsset, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.directions_car_rounded,
                size: 17,
                color: Color(0xFF898A8D),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  '${trip.vehicle.brand} ${trip.vehicle.model}',
                  style: const TextStyle(fontSize: 15),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.accentBlack),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  trip.vehicle.plateNumber,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceCard extends StatefulWidget {
  const _PriceCard({required this.trip});

  final PassengerTrip trip;

  @override
  State<_PriceCard> createState() => _PriceCardState();
}

class _PriceCardState extends State<_PriceCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.trip.hasAvailableSeats;
  }

  @override
  Widget build(BuildContext context) {
    final stops = widget.trip.stops;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _PriceRow(
            label: 'Стоимость поездки',
            value: '${widget.trip.detailsPriceRubles} ₽',
            strong: true,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Между остановками',
                  style: TextStyle(fontSize: 15),
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _expanded = !_expanded),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  side: const BorderSide(color: AppColors.brandGreen),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                iconAlignment: IconAlignment.end,
                icon: Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 15,
                ),
                label: Text(_expanded ? 'Скрыть' : 'Смотреть стоимость'),
              ),
            ],
          ),
          if (_expanded)
            for (var index = 0; index < stops.length - 1; index++) ...[
              const SizedBox(height: 10),
              _PriceRow(
                label: '${stops[index].address} — ${stops[index + 1].address}',
                value: '150 ₽',
              ),
            ],
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: strong ? 15 : 13,
              height: 1.35,
              fontWeight: strong ? FontWeight.w400 : FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: strong ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _TripActions extends StatelessWidget {
  const _TripActions({
    required this.hasAvailableSeats,
    this.isBooking = false,
    required this.acceptsParcels,
    required this.onBookSeat,
    required this.onSendParcel,
  });

  final bool hasAvailableSeats;
  final bool isBooking;
  final bool acceptsParcels;
  final VoidCallback onBookSeat;
  final VoidCallback onSendParcel;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        color: AppColors.accentWhite,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                key: TripDetailsScreen.bookSeatButtonKey,
                onPressed: hasAvailableSeats && !isBooking ? onBookSeat : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandGreen,
                  disabledBackgroundColor: AppColors.divider,
                  disabledForegroundColor: const Color(0xFF898A8D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isBooking
                      ? 'Подождите…'
                      : hasAvailableSeats
                      ? 'Забронировать место'
                      : 'Мест нет',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                key: TripDetailsScreen.sendParcelButtonKey,
                onPressed: acceptsParcels ? onSendParcel : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brandGreen,
                  side: BorderSide(
                    color: acceptsParcels
                        ? AppColors.brandGreen
                        : AppColors.divider,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Отправить посылку',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
