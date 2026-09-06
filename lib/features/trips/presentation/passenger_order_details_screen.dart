import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/app/widgets/screen_header.dart';
import 'package:vput/features/trips/domain/passenger_order.dart';
import 'package:vput/features/trips/domain/passenger_trip.dart';
import 'package:vput/features/trips/presentation/widgets/trip_route_timeline.dart';

class PassengerOrderDetailsScreen extends StatelessWidget {
  const PassengerOrderDetailsScreen({
    required this.order,
    required this.onBack,
    required this.onDriver,
    required this.onCancellationCompleted,
    required this.onChatDriver,
    this.isCancelling = false,
    super.key,
  });

  static const cancelButtonKey = Key('passenger_order_cancel');
  static const chatButtonKey = Key('passenger_order_chat');
  static const routeCardKey = Key('passenger_order_details_route');
  static const driverCardKey = Key('passenger_order_details_driver');
  static const keepBookingButtonKey = Key('passenger_order_keep_booking');
  static const confirmCancelButtonKey = Key('passenger_order_confirm_cancel');
  static const confirmLimitCancelButtonKey = Key(
    'passenger_order_confirm_limit_cancel',
  );

  final bool isCancelling;
  final PassengerOrder order;
  final VoidCallback onBack;
  final VoidCallback onDriver;
  final ValueChanged<PassengerCancellationOutcome> onCancellationCompleted;
  final VoidCallback onChatDriver;

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
                  padding: const EdgeInsets.fromLTRB(0, 20, 0, 112),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionTitle('Маршрут'),
                      const SizedBox(height: 12),
                      _RouteCard(order: order),
                      const SizedBox(height: 12),
                      _TripInfoCard(order: order),
                      const SizedBox(height: 22),
                      const _SectionTitle('Водитель'),
                      const SizedBox(height: 12),
                      _DriverCard(order: order, onDriver: onDriver),
                      const SizedBox(height: 12),
                      _PriceCard(order: order),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _OrderActions(
          cancelEnabled: order.isActive && !isCancelling,
          onCancelBooking: () => _startCancellation(context),
          onChatDriver: onChatDriver,
        ),
      ),
    );
  }

  Future<void> _startCancellation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.accentBlack.withValues(alpha: .42),
      builder: (_) => _CancelBookingDialog(order: order),
    );
    if (confirmed != true || !context.mounted) return;

    if (!order.willReachCancellationLimit) {
      onCancellationCompleted(PassengerCancellationOutcome.refundRequested);
      return;
    }

    final confirmedLimit = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.accentBlack.withValues(alpha: .42),
      builder: (_) => const _CancellationLimitDialog(),
    );
    if (confirmedLimit == true && context.mounted) {
      onCancellationCompleted(PassengerCancellationOutcome.bookingBlocked);
    }
  }
}

class _CancelBookingDialog extends StatelessWidget {
  const _CancelBookingDialog({required this.order});

  final PassengerOrder order;

  @override
  Widget build(BuildContext context) {
    final cancelCount = order.recentCancellations30d.clamp(0, 2);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      backgroundColor: AppColors.accentWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Отменить бронирование?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.accentBlack,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'После двух отмен за последние 30 дней новые бронирования '
              'недоступны до разблокировки администратором.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                height: 1.33,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  if (!order.willReachCancellationLimit) ...[
                    _DialogInfoRow(
                      label: 'Заявка на mock-возврат',
                      value: '${order.displayRefundAmountRubles} ₽',
                    ),
                    const SizedBox(height: 12),
                    const _DialogInfoRow(
                      label: 'Рассмотрение',
                      value: 'Администратором',
                    ),
                    const SizedBox(height: 12),
                  ],
                  _DialogInfoRow(
                    label: 'Отмен за 30 дней',
                    value: '$cancelCount / 2',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton(
                key: PassengerOrderDetailsScreen.keepBookingButtonKey,
                onPressed: () => Navigator.of(context).pop(false),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandGreen,
                  foregroundColor: AppColors.accentWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Не отменять',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton(
                key: PassengerOrderDetailsScreen.confirmCancelButtonKey,
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF63D45),
                  foregroundColor: AppColors.accentWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Да, отменить',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CancellationLimitDialog extends StatelessWidget {
  const _CancellationLimitDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      backgroundColor: AppColors.accentWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Это может повлиять на ваш\nаккаунт',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.accentBlack,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Вы уже отменили одну поездку за последние 30 дней. '
              'Бронирование новых поездок будет недоступно в течение 30 дней.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                height: 1.33,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9E8),
                border: Border.all(color: const Color(0xFFEAB308)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.error_rounded, color: Color(0xFFE0A800), size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'У вас уже была одна отмена за последние 30 дней',
                      style: TextStyle(
                        color: AppColors.accentBlack,
                        fontSize: 15,
                        height: 1.33,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandGreen,
                  foregroundColor: AppColors.accentWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Не отменять',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton(
                key: PassengerOrderDetailsScreen.confirmLimitCancelButtonKey,
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF63D45),
                  foregroundColor: AppColors.accentWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Всё равно отменить',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogInfoRow extends StatelessWidget {
  const _DialogInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final labelText = Text(
      label,
      style: const TextStyle(fontSize: 13, height: 1.3),
    );
    final valueText = Text(
      value,
      style: const TextStyle(
        color: AppColors.accentBlack,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 240) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [labelText, valueText],
          );
        }
        return Row(
          children: [
            Expanded(child: labelText),
            valueText,
          ],
        );
      },
    );
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
  const _RouteCard({required this.order});

  final PassengerOrder order;

  @override
  Widget build(BuildContext context) {
    final trip = order.trip;
    return Container(
      key: PassengerOrderDetailsScreen.routeCardKey,
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
            showIntermediateStops: true,
          ),
        ],
      ),
    );
  }
}

class _TripInfoCard extends StatelessWidget {
  const _TripInfoCard({required this.order});

  final PassengerOrder order;

  @override
  Widget build(BuildContext context) {
    final trip = order.trip;
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
                  label: 'Мест для пассажиров',
                  value:
                      '${order.passengerSeatsAvailable} из ${order.passengerSeatsTotal}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 13,
            runSpacing: 9,
            children: [
              for (final service in trip.services)
                if (service != TripExtraService.parcel)
                  _DetailService(service: service),
              if (order.hasParcel) _ParcelService(order: order),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

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
            style: const TextStyle(
              color: AppColors.accentBlack,
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
      TripExtraService.parcel => (Icons.inventory_2_rounded, 'С посылкой'),
    };
    return _IconText(icon: icon, text: text);
  }
}

class _ParcelService extends StatelessWidget {
  const _ParcelService({required this.order});

  final PassengerOrder order;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.inventory_2_rounded,
          size: 17,
          color: Color(0xFF898A8D),
        ),
        const SizedBox(width: 5),
        Text(
          'С посылкой • ${order.parcelSizes.join(', ')} • '
          '${order.parcelSlotsAvailable} из ${order.parcelSlotsTotal}',
          style: const TextStyle(fontSize: 15, height: 1.3),
        ),
      ],
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.order, required this.onDriver});

  final PassengerOrder order;
  final VoidCallback onDriver;

  @override
  Widget build(BuildContext context) {
    final trip = order.trip;
    return Container(
      key: PassengerOrderDetailsScreen.driverCardKey,
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
              child: Image.asset(trip.vehicle.photoAsset, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                trip.transportType == PassengerTransportType.bus
                    ? Icons.directions_bus_rounded
                    : Icons.directions_car_rounded,
                size: 17,
                color: const Color(0xFF898A8D),
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

class _PriceCard extends StatelessWidget {
  const _PriceCard({required this.order});

  final PassengerOrder order;

  @override
  Widget build(BuildContext context) {
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
            value: '${order.trip.detailsPriceRubles} ₽',
            strong: true,
          ),
          if (order.parcelPriceRubles != null) ...[
            const Divider(height: 24),
            _PriceRow(
              label: 'Стоимость перевозки посылки',
              value: '${order.parcelPriceRubles} ₽',
              strong: true,
            ),
          ],
          if (order.segmentPriceRubles != null) ...[
            const Divider(height: 24),
            _PriceRow(
              label: 'Между остановками',
              value: '${order.segmentPriceRubles} ₽',
              strong: true,
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
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 15, height: 1.35),
          ),
        ),
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

class _OrderActions extends StatelessWidget {
  const _OrderActions({
    required this.cancelEnabled,
    required this.onCancelBooking,
    required this.onChatDriver,
  });

  final bool cancelEnabled;
  final VoidCallback onCancelBooking;
  final VoidCallback onChatDriver;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        color: AppColors.accentWhite,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  key: PassengerOrderDetailsScreen.cancelButtonKey,
                  onPressed: cancelEnabled ? onCancelBooking : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.errorBackground,
                    side: BorderSide(
                      color: cancelEnabled
                          ? AppColors.errorBackground
                          : AppColors.divider,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Отменить бронь',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 48,
                child: FilledButton(
                  key: PassengerOrderDetailsScreen.chatButtonKey,
                  onPressed: onChatDriver,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandGreen,
                    foregroundColor: AppColors.accentWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Написать водителю',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
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

class _IconText extends StatelessWidget {
  const _IconText({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
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
