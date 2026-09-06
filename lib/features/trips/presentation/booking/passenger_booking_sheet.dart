import 'package:flutter/material.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/features/trips/domain/passenger_booking_request.dart';
import 'package:vput/features/trips/domain/passenger_trip.dart';
import 'package:vput/features/trips/presentation/booking/booking_sheet_parts.dart';

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

  /// Stops the passenger may board at: at least one pair starting there is
  /// priced by the driver.
  List<int> get _pickupChoices => [
    for (var index = 0; index < _trip.stops.length - 1; index++)
      if (_dropoffChoicesFrom(index).isNotEmpty) index,
  ];

  /// Stops the passenger may leave at, given where they get on. A pair the
  /// driver did not price is not sold, so it is not offered.
  List<int> _dropoffChoicesFrom(int pickupIndex) => [
    for (var index = pickupIndex + 1; index < _trip.stops.length; index++)
      if (_trip.isLegSold(pickupIndex, index)) index,
  ];

  void _setPickup(int index) {
    setState(() {
      _pickupIndex = index;
      final choices = _dropoffChoicesFrom(index);
      if (!choices.contains(_dropoffIndex)) {
        _dropoffIndex = choices.isEmpty ? index + 1 : choices.first;
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

  /// What the driver receives for this booking: the fare of the chosen pair
  /// plus the extras, for every seat. The platform commission is added on top
  /// of it by the server, and shown separately.
  int _driverFareRubles() {
    final baseFare = _trip.fareBetween(_pickupIndex, _dropoffIndex) ?? 0;
    var extras = 0;
    for (final service in _selectedExtras) {
      extras += _trip.extraServicePrices[service] ?? 0;
    }
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
      amountRubles: _driverFareRubles(),
      status: isInstant
          ? PassengerBookingStatus.awaitingPayment
          : PassengerBookingStatus.pendingDriver,
      paymentStatus: PassengerPaymentStatus.unpaid,
    );
  }

  bool get _canSubmit =>
      _trip.hasAvailableSeats &&
      _trip.stops.length >= 2 &&
      _trip.isLegSold(_pickupIndex, _dropoffIndex);

  void _submit() {
    if (!_canSubmit) return;
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
              const BookingSheetDragHandle(),
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
                      const BookingSheetSectionTitle('Точка отправления'),
                      const SizedBox(height: 12),
                      BookingSheetRouteCard(
                        children: [
                          for (final index in _pickupChoices)
                            BookingSheetRouteTile(
                              key: PassengerBookingSheet.pickupKey(index),
                              label: _trip.stops[index].address,
                              selected: _pickupIndex == index,
                              onTap: () => _setPickup(index),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const BookingSheetSectionTitle('Конечная точка'),
                      const SizedBox(height: 12),
                      BookingSheetRouteCard(
                        children: [
                          for (final index in _dropoffChoicesFrom(_pickupIndex))
                            BookingSheetRouteTile(
                              key: PassengerBookingSheet.dropoffKey(index),
                              label: _trip.stops[index].address,
                              selected: _dropoffIndex == index,
                              onTap: () => _setDropoff(index),
                            ),
                        ],
                      ),
                      if (_availableSeatExtras.isNotEmpty) ...[
                        const SizedBox(height: 22),
                        const BookingSheetSectionTitle('Доп. услуги'),
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
                          onPressed: _canSubmit ? _submit : null,
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
            BookingSheetSwitch(value: selected),
          ],
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
          BookingSheetCounterButton(
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
          BookingSheetCounterButton(
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
