import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:vput/features/profile/application/user_profile_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/core/utils/russian_date_labels.dart';
import 'package:vput/features/trips/data/preview_trip_publication_settings.dart';
import 'package:vput/features/trips/domain/driver_trip.dart';
import 'package:vput/features/trips/domain/passenger_trip.dart';
import 'package:vput/features/trips/domain/trip_extras.dart';
import 'package:vput/features/trips/presentation/widgets/create_trip_controls.dart';
import 'package:vput/features/trips/presentation/widgets/trip_route_timeline.dart';
import 'package:vput/features/vehicles/data/preview_driver_vehicle_repository.dart';
import 'package:vput/features/vehicles/domain/driver_vehicle.dart';

class DriverTripDetailsScreen extends ConsumerWidget {
  const DriverTripDetailsScreen({
    required this.trip,
    required this.onBack,
    required this.onEdit,
    required this.onCancelTrip,
    required this.onRepeatTrip,
    required this.onSeatCapacityChanged,
    required this.onClosePassengerRegistration,
    required this.onPassenger,
    this.now,
    super.key,
  });

  static const routeCardKey = Key('driver_trip_details_route');
  static const infoCardKey = Key('driver_trip_details_info');
  static const vehicleCardKey = Key('driver_trip_details_vehicle');
  static const passengersBlockKey = Key('driver_trip_details_passengers');
  static const menuButtonKey = Key('driver_trip_details_menu');
  static const changeSeatsMenuItemKey = Key('driver_trip_details_change_seats');
  static const editMenuItemKey = Key('driver_trip_details_edit');
  static const transferPassengersMenuItemKey = Key(
    'driver_trip_details_transfer_passengers',
  );
  static const closeRegistrationMenuItemKey = Key(
    'driver_trip_details_close_registration',
  );
  static const cancelButtonKey = Key('driver_trip_details_cancel');
  static const repeatButtonKey = Key('driver_trip_details_repeat');
  static const seatCapacitySheetKey = Key(
    'driver_trip_details_seat_capacity_sheet',
  );
  static const seatCapacitySaveButtonKey = Key(
    'driver_trip_details_seat_capacity_save',
  );
  static const editUnavailableSheetKey = Key(
    'driver_trip_details_edit_unavailable_sheet',
  );
  static const editUnavailableOkButtonKey = Key(
    'driver_trip_details_edit_unavailable_ok',
  );
  static const transferUnavailableSheetKey = Key(
    'driver_trip_details_transfer_unavailable_sheet',
  );
  static const transferUnavailableOkButtonKey = Key(
    'driver_trip_details_transfer_unavailable_ok',
  );

  static Key passengerStateKey(String id) =>
      Key('driver_trip_details_passenger_state_$id');

  static Key passengerKey(String id) =>
      Key('driver_trip_details_passenger_$id');

  final DriverTrip trip;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onCancelTrip;
  final VoidCallback onRepeatTrip;
  final ValueChanged<int> onSeatCapacityChanged;
  final VoidCallback onClosePassengerRegistration;
  final ValueChanged<DriverTripPassengerBooking> onPassenger;
  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTime = now ?? DateTime.now();
    final isCompleted = trip.isCompleted(currentTime);
    const overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.accentWhite,
      systemNavigationBarIconBrightness: Brightness.dark,
    );
    final vehicle = trip.draft.vehicleId == null
        ? null
        : ref
              .read(driverVehicleRepositoryProvider)
              .findById(trip.draft.vehicleId!);
    final hasPassengers = trip.passengerBookings.isNotEmpty;
    final canEdit = !trip.hasJoinedPassengers && !isCompleted;
    final vehicleSeatCount = vehicle?.seatCount ?? 8;
    final maxSeatCapacity = [
      vehicleSeatCount,
      trip.draft.seatCount,
      trip.bookedSeatCount,
    ].reduce((a, b) => a > b ? a : b);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _Header(
                canEdit: canEdit,
                canManage: !isCompleted,
                hasJoinedPassengers: trip.hasJoinedPassengers,
                canCloseRegistration:
                    trip.hasJoinedPassengers && trip.freeSeatCount > 0,
                onBack: onBack,
                onEdit: onEdit,
                onChangeSeats: () async {
                  final value = await _showSeatCapacitySheet(
                    context,
                    trip: trip,
                    maxValue: maxSeatCapacity,
                  );
                  if (value != null && value != trip.draft.seatCount) {
                    onSeatCapacityChanged(value);
                  }
                },
                onTransferPassengers: () => _showInfoSheet(
                  context,
                  key: DriverTripDetailsScreen.transferUnavailableSheetKey,
                  okButtonKey:
                      DriverTripDetailsScreen.transferUnavailableOkButtonKey,
                  title: 'Передача пассажиров',
                  description:
                      'Передать пассажиров можно будет после выбора другой '
                      'подходящей поездки. Пока можно изменить количество '
                      'мест или завершить приём пассажиров.',
                ),
                onClosePassengerRegistration: onClosePassengerRegistration,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(0, 20, 0, 104),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionTitle('Маршрут'),
                      const SizedBox(height: 12),
                      _RouteAndMoneyCard(trip: trip),
                      const SizedBox(height: 12),
                      _TripInfoCard(trip: trip),
                      const SizedBox(height: 22),
                      if (hasPassengers) ...[
                        const _SectionTitle('Пассажиры'),
                        const SizedBox(height: 12),
                        _PassengersCard(
                          passengers: trip.passengerBookings,
                          onPassenger: onPassenger,
                        ),
                      ] else ...[
                        const _SectionTitle('Водитель'),
                        const SizedBox(height: 12),
                        _VehicleCard(vehicle: vehicle),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: isCompleted
            ? _BottomRepeatButton(onRepeatTrip: onRepeatTrip)
            : _BottomCancelButton(
                onCancelTrip: () async {
                  final confirmed = await _confirmCancelTrip(context, trip);
                  if (confirmed) onCancelTrip();
                },
              ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.canEdit,
    required this.canManage,
    required this.hasJoinedPassengers,
    required this.canCloseRegistration,
    required this.onBack,
    required this.onEdit,
    required this.onChangeSeats,
    required this.onTransferPassengers,
    required this.onClosePassengerRegistration,
  });

  final bool canEdit;
  final bool canManage;
  final bool hasJoinedPassengers;
  final bool canCloseRegistration;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onChangeSeats;
  final VoidCallback onTransferPassengers;
  final VoidCallback onClosePassengerRegistration;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 48,
            child: Center(
              child: SizedBox.square(
                dimension: 40,
                child: IconButton.filled(
                  onPressed: onBack,
                  padding: EdgeInsets.zero,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.accentWhite,
                    foregroundColor: AppColors.accentBlack,
                  ),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                ),
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'Поездка',
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
              child: PopupMenuButton<_TripMenuAction>(
                key: DriverTripDetailsScreen.menuButtonKey,
                enabled: canManage,
                tooltip: 'Действия',
                color: AppColors.accentWhite,
                surfaceTintColor: Colors.transparent,
                offset: const Offset(0, 46),
                constraints: const BoxConstraints(minWidth: 284),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (action) {
                  switch (action) {
                    case _TripMenuAction.changeSeats:
                      onChangeSeats();
                    case _TripMenuAction.edit:
                      if (canEdit) {
                        onEdit();
                      } else {
                        _showEditUnavailableSheet(context);
                      }
                    case _TripMenuAction.transferPassengers:
                      onTransferPassengers();
                    case _TripMenuAction.closeRegistration:
                      onClosePassengerRegistration();
                  }
                },
                itemBuilder: (_) => [
                  if (hasJoinedPassengers)
                    _menuItem(
                      key: DriverTripDetailsScreen.changeSeatsMenuItemKey,
                      value: _TripMenuAction.changeSeats,
                      icon: Icons.airline_seat_recline_normal_rounded,
                      label: 'Изменить количество мест',
                    ),
                  _menuItem(
                    key: DriverTripDetailsScreen.editMenuItemKey,
                    value: _TripMenuAction.edit,
                    icon: Icons.edit_rounded,
                    label: 'Редактировать',
                  ),
                  if (hasJoinedPassengers)
                    _menuItem(
                      key:
                          DriverTripDetailsScreen.transferPassengersMenuItemKey,
                      value: _TripMenuAction.transferPassengers,
                      icon: Icons.groups_rounded,
                      label: 'Передать пассажиров',
                    ),
                  if (hasJoinedPassengers)
                    _menuItem(
                      key: DriverTripDetailsScreen.closeRegistrationMenuItemKey,
                      value: _TripMenuAction.closeRegistration,
                      icon: Icons.no_transfer_rounded,
                      label: 'Завершить приём пассажиров',
                      enabled: canCloseRegistration,
                    ),
                ],
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.accentWhite.withValues(alpha: .72),
                    shape: BoxShape.circle,
                  ),
                  child: const SizedBox.square(
                    dimension: 40,
                    child: Icon(Icons.more_horiz_rounded, size: 22),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<_TripMenuAction> _menuItem({
    required Key key,
    required _TripMenuAction value,
    required IconData icon,
    required String label,
    bool enabled = true,
  }) {
    final color = enabled ? AppColors.accentBlack : AppColors.textSecondary;
    return PopupMenuItem(
      key: key,
      value: value,
      enabled: enabled,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              label,
              style: TextStyle(color: color, fontSize: 15, height: 1.33),
            ),
          ),
        ],
      ),
    );
  }
}

enum _TripMenuAction {
  changeSeats,
  edit,
  transferPassengers,
  closeRegistration,
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

class _RouteAndMoneyCard extends ConsumerWidget {
  const _RouteAndMoneyCard({required this.trip});

  final DriverTrip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final policy = ref.watch(tripCommissionPolicyProvider);
    final price = trip.draft.fullRoutePrice ?? 0;
    final commission = policy.fixedRubles.clamp(0, price);
    final driverAmount = price - commission;
    return Container(
      key: DriverTripDetailsScreen.routeCardKey,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: _RoadWatermark()),
          Column(
            children: [
              TripRouteTimeline(
                origin: trip.draft.origin.address,
                destination: trip.draft.destination.address,
                intermediateStopCount: trip.draft.intermediateStops.length,
                expandedStopButton: trip.draft.intermediateStops.isNotEmpty,
                intermediateStops: trip.draft.intermediateStops
                    .map((point) => point.address)
                    .toList(growable: false),
                showIntermediateStops: true,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _MoneyTile(label: 'Стоимость', value: '$price ₽'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MoneyTile(
                      label: 'Комиссия',
                      value: '$commission ₽',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _DriverPaymentLine(amount: driverAmount),
            ],
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

class _MoneyTile extends StatelessWidget {
  const _MoneyTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: AppColors.accentWhite,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, height: 1.2)),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.accentBlack,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverPaymentLine extends StatelessWidget {
  const _DriverPaymentLine({required this.amount});

  final int amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: AppColors.accentWhite,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text('К оплате водителю', style: TextStyle(fontSize: 15)),
          ),
          Text(
            '$amount ₽',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _TripInfoCard extends StatelessWidget {
  const _TripInfoCard({required this.trip});

  final DriverTrip trip;

  @override
  Widget build(BuildContext context) {
    final departure = trip.draft.departureAt;
    final arrival = trip.draft.arrivalAt;
    return Container(
      key: DriverTripDetailsScreen.infoCardKey,
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
                  value: departure == null
                      ? 'Не указано'
                      : RussianDateLabels.dateAndTime(departure),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoTile(
                  label: 'Мест для пассажиров',
                  value: '${trip.freeSeatCount} из ${trip.draft.seatCount}',
                ),
              ),
            ],
          ),
          if (arrival != null) ...[
            const SizedBox(height: 14),
            _IconText(
              icon: Icons.schedule_rounded,
              text: 'Прибытие ~${RussianDateLabels.time(arrival)}',
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 13,
            runSpacing: 9,
            children: [
              for (final extra in trip.draft.extras)
                if (extra.enabled) _ServiceLabel(service: extra.service),
              if (trip.draft.parcel.enabled)
                _ParcelService(parcel: trip.draft.parcel),
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

class _VehicleCard extends ConsumerWidget {
  const _VehicleCard({required this.vehicle});

  final DriverVehicle? vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final car = vehicle;
    final profile = ref.watch(userProfileProvider).profile;
    return Container(
      key: DriverTripDetailsScreen.vehicleCardKey,
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
              CircleAvatar(
                radius: 23,
                backgroundImage: profile.avatarBytes == null
                    ? null
                    : MemoryImage(profile.avatarBytes!),
                backgroundColor: const Color(0xFFE9EEF0),
                child: profile.avatarBytes == null
                    ? const Icon(Icons.person_outline)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      profile.ratingLabel,
                      style: const TextStyle(
                        color: Color(0xFF61636B),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.outlined(
                onPressed: () => context.push('/profile'),
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
              child: car?.photoBytes != null
                  ? Image.memory(car!.photoBytes!, fit: BoxFit.cover)
                  : Image.asset(
                      car?.photoAsset ?? 'docs/imgs/car.png',
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                car?.transportType == VehicleTransportType.bus
                    ? Icons.directions_bus_rounded
                    : Icons.directions_car_rounded,
                size: 17,
                color: const Color(0xFF898A8D),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  car?.title ?? 'Автомобиль',
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
                  car?.plateNumber ?? '—',
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

class _PassengersCard extends StatelessWidget {
  const _PassengersCard({required this.passengers, required this.onPassenger});

  final List<DriverTripPassengerBooking> passengers;
  final ValueChanged<DriverTripPassengerBooking> onPassenger;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: DriverTripDetailsScreen.passengersBlockKey,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accentWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (final passenger in passengers) ...[
            if (passenger != passengers.first)
              const Divider(height: 1, indent: 70, color: AppColors.divider),
            _PassengerRow(
              passenger: passenger,
              onTap: () => onPassenger(passenger),
            ),
          ],
        ],
      ),
    );
  }
}

class _PassengerRow extends StatelessWidget {
  const _PassengerRow({required this.passenger, required this.onTap});

  final DriverTripPassengerBooking passenger;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: DriverTripDetailsScreen.passengerKey(passenger.id),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: AppColors.divider,
                foregroundImage: passenger.passengerAvatarAsset == null
                    ? null
                    : AssetImage(passenger.passengerAvatarAsset!),
                child: passenger.passengerAvatarAsset == null
                    ? const Icon(
                        Icons.person_rounded,
                        color: AppColors.textSecondary,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            passenger.passengerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _BookingStateLabel(passenger: passenger),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFF2C500),
                          size: 18,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            passenger.passengerRatingLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF61636B),
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.accentBlack,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What is expected next on this booking: the driver's decision, the
/// passenger's payment, or nothing at all.
class _BookingStateLabel extends StatelessWidget {
  const _BookingStateLabel({required this.passenger});

  final DriverTripPassengerBooking passenger;

  @override
  Widget build(BuildContext context) {
    final color = switch (passenger.state) {
      DriverBookingState.awaitingDriver => AppColors.errorText,
      DriverBookingState.awaitingPayment => AppColors.brandGreen,
      DriverBookingState.paid => AppColors.textSecondary,
    };
    return Text(
      passenger.stateLabel,
      key: DriverTripDetailsScreen.passengerStateKey(passenger.id),
      style: TextStyle(color: color, fontSize: 13, height: 1.38),
    );
  }
}

class _BottomCancelButton extends StatelessWidget {
  const _BottomCancelButton({required this.onCancelTrip});

  final VoidCallback onCancelTrip;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        color: AppColors.accentWhite,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: SizedBox(
          height: 48,
          width: double.infinity,
          child: FilledButton(
            key: DriverTripDetailsScreen.cancelButtonKey,
            onPressed: onCancelTrip,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.errorBackground,
              foregroundColor: AppColors.accentWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Отменить поездку'),
          ),
        ),
      ),
    );
  }
}

class _BottomRepeatButton extends StatelessWidget {
  const _BottomRepeatButton({required this.onRepeatTrip});

  final VoidCallback onRepeatTrip;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        color: AppColors.accentWhite,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: SizedBox(
          height: 48,
          width: double.infinity,
          child: FilledButton(
            key: DriverTripDetailsScreen.repeatButtonKey,
            onPressed: onRepeatTrip,
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
            child: const Text('Повторить поездку'),
          ),
        ),
      ),
    );
  }
}

Future<int?> _showSeatCapacitySheet(
  BuildContext context, {
  required DriverTrip trip,
  required int maxValue,
}) {
  var value = trip.draft.seatCount;
  final minValue = trip.bookedSeatCount;
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final hasChanges = value != trip.draft.seatCount;
          return SafeArea(
            top: false,
            child: Container(
              key: DriverTripDetailsScreen.seatCapacitySheetKey,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFC9CACD),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Количество мест',
                    style: TextStyle(
                      color: AppColors.accentBlack,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      height: 1.29,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentWhite,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CreateTripSeatCounter(
                      label: 'Количество мест:',
                      value: value,
                      minValue: minValue,
                      maxValue: maxValue,
                      onChanged: (next) => setState(() => value = next),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      key: DriverTripDetailsScreen.seatCapacitySaveButtonKey,
                      onPressed: hasChanges
                          ? () => Navigator.of(context).pop(value)
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandGreen,
                        foregroundColor: AppColors.accentWhite,
                        disabledBackgroundColor: AppColors.divider,
                        disabledForegroundColor: AppColors.textSecondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Сохранить'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Future<void> _showEditUnavailableSheet(BuildContext context) => _showInfoSheet(
  context,
  key: DriverTripDetailsScreen.editUnavailableSheetKey,
  okButtonKey: DriverTripDetailsScreen.editUnavailableOkButtonKey,
  title: 'Редактирование недоступно',
  description:
      'К поездке уже присоединились пассажиры. Маршрут, время и стоимость '
      'изменить нельзя',
);

Future<void> _showInfoSheet(
  BuildContext context, {
  required Key key,
  required String title,
  required String description,
  Key? okButtonKey,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => SafeArea(
      top: false,
      child: Container(
        key: key,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 43,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCACBCE),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.accentBlack,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                height: 1.29,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                height: 1.33,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 48,
              child: OutlinedButton(
                key: okButtonKey,
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brandGreen,
                  side: const BorderSide(color: AppColors.brandGreen),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.33,
                  ),
                ),
                child: const Text('Понятно'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<bool> _confirmCancelTrip(BuildContext context, DriverTrip trip) async {
  final hasPassengers = trip.hasJoinedPassengers;
  final isLimitRisk = hasPassengers && trip.recentCancellations30d >= 1;
  final result = await showDialog<bool>(
    context: context,
    barrierColor: AppColors.accentBlack.withValues(alpha: .45),
    builder: (context) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      backgroundColor: AppColors.accentWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hasPassengers
                  ? isLimitRisk
                        ? 'Это может повлиять на ваш\nаккаунт'
                        : 'Отменить поездку?'
                  : 'Отменить поездку?',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.accentBlack,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              hasPassengers
                  ? isLimitRisk
                        ? 'Повторная отмена поездки с пассажирами за последние '
                              '30 дней временно заблокирует аккаунт на 30 дней.'
                        : 'К поездке уже присоединился пассажир. Такая отмена '
                              'считается нарушением правил сообщества.'
                  : 'Пассажиры ещё не присоединились, поэтому поездку можно '
                        'отменить без предупреждения.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                height: 1.33,
              ),
            ),
            if (hasPassengers) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Отмен за 30 дней',
                        style: TextStyle(fontSize: 13, height: 1.3),
                      ),
                    ),
                    Text(
                      '${trip.recentCancellations30d.clamp(0, 2)} / 2',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                child: const Text('Не отменять'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.errorBackground,
                  foregroundColor: AppColors.accentWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  hasPassengers ? 'Всё равно отменить' : 'Да, отменить',
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}

class _ServiceLabel extends StatelessWidget {
  const _ServiceLabel({required this.service});

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
  const _ParcelService({required this.parcel});

  final TripParcelOffer parcel;

  @override
  Widget build(BuildContext context) {
    final sizes = parcel.priceBySize.keys
        .map((size) {
          return switch (size) {
            ParcelSize.small => 'S',
            ParcelSize.medium => 'M',
            ParcelSize.large => 'L',
          };
        })
        .join(', ');
    return _IconText(
      icon: Icons.inventory_2_rounded,
      text: 'С посылкой • $sizes • ${parcel.priceBySize.length} из 3',
    );
  }
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
