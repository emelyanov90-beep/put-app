import 'package:flutter/material.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/features/trips/domain/passenger_booking_request.dart';
import 'package:vput/features/trips/domain/passenger_trip.dart';

class PassengerBookingSheet extends StatefulWidget {
  const PassengerBookingSheet({required this.trip, super.key});

  static const sheetKey = Key('passenger_booking_sheet');
  static const submitButtonKey = Key('passenger_booking_submit');
  static const passengerMinusKey = Key('passenger_booking_minus');
  static const passengerPlusKey = Key('passenger_booking_plus');
  static const passengerCountKey = Key('passenger_booking_count');

  static Key pickupKey(int index) =>
      ValueKey('passenger_booking_pickup_$index');
  static Key dropoffKey(int index) =>
      ValueKey('passenger_booking_dropoff_$index');
  static Key extraKey(TripExtraService service) =>
      ValueKey('passenger_booking_extra_${service.name}');

  final PassengerTrip trip;

  @override
  State<PassengerBookingSheet> createState() => _PassengerBookingSheetState();
}

class _PassengerBookingSheetState extends State<PassengerBookingSheet> {
  static const _extraPriceRubles = 150;

  late int _pickupIndex;
  late int _dropoffIndex;
  late int _passengerCount;
  final _selectedExtras = <TripExtraService>{};

  PassengerTrip get _trip => widget.trip;
  int get _maxPassengerCount => _trip.totalSeats <= 0
      ? 1
      : _trip.availableSeats.clamp(1, _trip.totalSeats);

  List<TripExtraService> get _availableSeatExtras => TripExtraService.values
      .where((service) => service != TripExtraService.parcel)
      .where(_trip.services.contains)
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    _pickupIndex = 0;
    _dropoffIndex = _trip.stops.length - 1;
    _passengerCount = 1;
  }

  void _setPickup(int index) {
    setState(() {
      _pickupIndex = index;
      if (_dropoffIndex <= _pickupIndex) {
        _dropoffIndex = _pickupIndex + 1;
      }
    });
  }

  void _setDropoff(int index) {
    setState(() => _dropoffIndex = index);
  }

  void _toggleExtra(TripExtraService service) {
    setState(() {
      if (!_selectedExtras.add(service)) {
        _selectedExtras.remove(service);
      }
    });
  }

  void _changePassengerCount(int delta) {
    setState(() {
      _passengerCount = (_passengerCount + delta).clamp(1, _maxPassengerCount);
    });
  }

  int _fareRubles() {
    final segmentCount = _dropoffIndex - _pickupIndex;
    final fullRouteSegments = _trip.stops.length - 1;
    final baseFare = _pickupIndex == 0 && _dropoffIndex == fullRouteSegments
        ? _trip.detailsPriceRubles
        : segmentCount * 150;
    final extras = _selectedExtras.length * _extraPriceRubles;
    return (baseFare + extras) * _passengerCount;
  }

  PassengerBookingRequest _buildRequest() {
    final isInstant = _trip.bookingMode == PassengerTripBookingMode.instant;
    return PassengerBookingRequest(
      tripId: _trip.id,
      pickupIndex: _pickupIndex,
      dropoffIndex: _dropoffIndex,
      seatCount: _passengerCount,
      selectedExtras: Set.unmodifiable(_selectedExtras),
      amountRubles: _fareRubles(),
      status: isInstant
          ? PassengerBookingStatus.awaitingPayment
          : PassengerBookingStatus.pendingDriver,
      paymentStatus: PassengerPaymentStatus.unpaid,
    );
  }

  void _submit() {
    if (!_trip.hasAvailableSeats || _trip.stops.length < 2) return;
    Navigator.of(context).pop(_buildRequest());
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: .94,
      child: Material(
        key: PassengerBookingSheet.sheetKey,
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 10),
              const _DragHandle(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Откликнуться на заказ',
                        style: TextStyle(
                          color: AppColors.accentBlack,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 26),
                      const _BookingSectionTitle('Точка отправления'),
                      const SizedBox(height: 12),
                      _RouteChoiceCard(
                        children: [
                          for (
                            var index = 0;
                            index < _trip.stops.length - 1;
                            index++
                          )
                            _RouteChoiceTile(
                              key: PassengerBookingSheet.pickupKey(index),
                              label: _trip.stops[index].address,
                              selected: _pickupIndex == index,
                              onTap: () => _setPickup(index),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const _BookingSectionTitle('Конечная точка'),
                      const SizedBox(height: 12),
                      _RouteChoiceCard(
                        children: [
                          for (
                            var index = _pickupIndex + 1;
                            index < _trip.stops.length;
                            index++
                          )
                            _RouteChoiceTile(
                              key: PassengerBookingSheet.dropoffKey(index),
                              label: _trip.stops[index].address,
                              selected: _dropoffIndex == index,
                              onTap: () => _setDropoff(index),
                            ),
                        ],
                      ),
                      if (_availableSeatExtras.isNotEmpty) ...[
                        const SizedBox(height: 22),
                        const _BookingSectionTitle('Доп. услуги'),
                        const SizedBox(height: 12),
                        _ExtrasCard(
                          services: _availableSeatExtras,
                          selectedExtras: _selectedExtras,
                          onToggle: _toggleExtra,
                        ),
                      ],
                      const SizedBox(height: 22),
                      _PassengerCounterCard(
                        value: _passengerCount,
                        canDecrease: _passengerCount > 1,
                        canIncrease: _passengerCount < _maxPassengerCount,
                        onDecrease: () => _changePassengerCount(-1),
                        onIncrease: () => _changePassengerCount(1),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          key: PassengerBookingSheet.submitButtonKey,
                          onPressed:
                              _trip.hasAvailableSeats && _trip.stops.length >= 2
                              ? _submit
                              : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.brandGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Отправить заявку',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 43,
      height: 5,
      decoration: BoxDecoration(
        color: const Color(0xFFCACBCE),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class _BookingSectionTitle extends StatelessWidget {
  const _BookingSectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.accentBlack,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
    );
  }
}

class _RouteChoiceCard extends StatelessWidget {
  const _RouteChoiceCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.accentWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: _RoadWatermark()),
          Column(children: children),
        ],
      ),
    );
  }
}

class _RouteChoiceTile extends StatelessWidget {
  const _RouteChoiceTile({
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            _RadioMark(selected: selected),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.accentBlack,
                  fontSize: 15,
                  height: 1.33,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadioMark extends StatelessWidget {
  const _RadioMark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.brandGreen, width: 2),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: AppColors.brandGreen,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }
}

class _ExtrasCard extends StatelessWidget {
  const _ExtrasCard({
    required this.services,
    required this.selectedExtras,
    required this.onToggle,
  });

  final List<TripExtraService> services;
  final Set<TripExtraService> selectedExtras;
  final ValueChanged<TripExtraService> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.accentWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (final service in services) ...[
            _ExtraTile(
              service: service,
              selected: selectedExtras.contains(service),
              onChanged: () => onToggle(service),
            ),
            if (service != services.last)
              const Divider(height: 1, color: AppColors.divider),
          ],
        ],
      ),
    );
  }
}

class _ExtraTile extends StatelessWidget {
  const _ExtraTile({
    required this.service,
    required this.selected,
    required this.onChanged,
  });

  final TripExtraService service;
  final bool selected;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final (icon, title, subtitle) = switch (service) {
      TripExtraService.childSeat => (
        Icons.child_friendly_rounded,
        'Детское кресло',
        'Детское кресло',
      ),
      TripExtraService.luggage => (
        Icons.work_rounded,
        'Багаж',
        'Большой чемодан',
      ),
      TripExtraService.pets => (
        Icons.pets_rounded,
        'Животные',
        'В переноске или на коленях',
      ),
      TripExtraService.parcel => (
        Icons.inventory_2_rounded,
        'Посылка',
        'Без пассажира',
      ),
    };

    return InkWell(
      key: PassengerBookingSheet.extraKey(service),
      onTap: onChanged,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: const Color(0xFF898A8D)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      height: 1.33,
                    ),
                  ),
                ],
              ),
            ),
            _BookingSwitch(value: selected),
          ],
        ),
      ),
    );
  }
}

class _BookingSwitch extends StatelessWidget {
  const _BookingSwitch({required this.value});

  final bool value;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 42,
      height: 26,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: value ? AppColors.brandGreen : AppColors.accentWhite,
        border: Border.all(color: AppColors.brandGreen, width: 2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Align(
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: value ? AppColors.accentWhite : AppColors.brandGreen,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _PassengerCounterCard extends StatelessWidget {
  const _PassengerCounterCard({
    required this.value,
    required this.canDecrease,
    required this.canIncrease,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int value;
  final bool canDecrease;
  final bool canIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.accentWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Пассажиров',
              style: TextStyle(
                color: AppColors.accentBlack,
                fontSize: 15,
                height: 1.33,
              ),
            ),
          ),
          _CounterButton(
            key: PassengerBookingSheet.passengerMinusKey,
            icon: Icons.remove_rounded,
            enabled: canDecrease,
            primary: true,
            onTap: onDecrease,
          ),
          SizedBox(
            key: PassengerBookingSheet.passengerCountKey,
            width: 70,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.accentBlack,
                fontSize: 15,
                height: 1.33,
              ),
            ),
          ),
          _CounterButton(
            key: PassengerBookingSheet.passengerPlusKey,
            icon: Icons.add_rounded,
            enabled: canIncrease,
            primary: false,
            onTap: onIncrease,
          ),
        ],
      ),
    );
  }
}

class _CounterButton extends StatelessWidget {
  const _CounterButton({
    required this.icon,
    required this.enabled,
    required this.primary,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final bool enabled;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = primary
        ? AppColors.accentBlack
        : const Color(0xFF898A8D);
    return IconButton.outlined(
      onPressed: enabled ? onTap : null,
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        fixedSize: const Size(40, 40),
        backgroundColor: enabled ? background : AppColors.surfaceMuted,
        foregroundColor: AppColors.accentWhite,
        disabledForegroundColor: AppColors.accentWhite,
        side: const BorderSide(color: AppColors.divider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      ..moveTo(size.width * .54, -14)
      ..cubicTo(
        size.width * 1.02,
        size.height * .14,
        size.width * .5,
        size.height * .38,
        size.width * .68,
        size.height * .64,
      )
      ..cubicTo(
        size.width * .84,
        size.height * .86,
        size.width * .95,
        size.height * .82,
        size.width * 1.05,
        size.height * 1.08,
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
